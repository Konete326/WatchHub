import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/review.dart';
import '../models/user.dart';
import 'cloudinary_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<String> _uploadImage(String reviewId, File file, int index) async {
    return await CloudinaryService.uploadImage(
      file,
      folder: 'reviews',
      publicId: 'reviews/$reviewId/image_$index',
    );
  }

  Future<Map<String, dynamic>> getWatchReviews(
    String watchId, {
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('watchId', isEqualTo: watchId)
        .orderBy(sortBy, descending: sortOrder == 'desc')
        .limit(limit * page)
        .get();

    final reviews = <Review>[];
    final ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    final allReviewsSnapshot = await _firestore
        .collection('reviews')
        .where('watchId', isEqualTo: watchId)
        .get();

    for (var doc in allReviewsSnapshot.docs) {
      final rating = doc.data()['rating'] as int;
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
    }

    final startIndex = (page - 1) * limit;
    final docs = snapshot.docs;
    final paginatedDocs = docs.length > startIndex
        ? docs.sublist(startIndex, (startIndex + limit).clamp(0, docs.length))
        : [];

    for (var doc in paginatedDocs) {
      final review = Review.fromFirestore(doc);
      final userDoc =
          await _firestore.collection('users').doc(review.userId).get();
      User? user;
      if (userDoc.exists) {
        user = User.fromFirestore(userDoc);
      }
      reviews.add(Review(
        id: review.id,
        userId: review.userId,
        watchId: review.watchId,
        rating: review.rating,
        comment: review.comment,
        images: review.images,
        helpfulCount: review.helpfulCount,
        createdAt: review.createdAt,
        user: user,
      ));
    }

    return {
      'reviews': reviews,
      'ratingDistribution': ratingDistribution,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': allReviewsSnapshot.docs.length,
        'totalPages': (allReviewsSnapshot.docs.length / limit).ceil()
      },
    };
  }

  Future<Review> createReview(Review review, {List<File>? images}) async {
    if (uid == null) throw Exception('User not logged in');

    final reviewRef = _firestore.collection('reviews').doc();
    final watchRef = _firestore.collection('watches').doc(review.watchId);

    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      for (int i = 0; i < images.length; i++) {
        final url = await _uploadImage(reviewRef.id, images[i], i);
        imageUrls.add(url);
      }
    }

    return await _firestore.runTransaction((transaction) async {
      final watchDoc = await transaction.get(watchRef);
      if (!watchDoc.exists) throw Exception('Watch not found');

      final watchData = watchDoc.data()!;
      final currentRating = (watchData['averageRating'] ?? 0.0).toDouble();
      final currentCount = watchData['reviewCount'] ?? 0;

      final newCount = currentCount + 1;
      final newRating =
          ((currentRating * currentCount) + review.rating) / newCount;

      transaction.set(reviewRef, {
        'userId': uid,
        'watchId': review.watchId,
        'rating': review.rating,
        'comment': review.comment,
        'images': imageUrls,
        'helpfulCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(watchRef, {
        'averageRating': newRating,
        'reviewCount': newCount,
      });

      return Review(
        id: reviewRef.id,
        userId: uid!,
        watchId: review.watchId,
        rating: review.rating,
        comment: review.comment,
        images: imageUrls,
        helpfulCount: 0,
        createdAt: DateTime.now(),
      );
    });
  }

  Future<Review> updateReview(String id,
      {int? rating, String? comment, List<File>? images}) async {
    if (uid == null) throw Exception('User not logged in');

    final reviewRef = _firestore.collection('reviews').doc(id);
    final reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists) throw Exception('Review not found');

    final reviewData = reviewDoc.data()!;
    final updates = <String, dynamic>{};
    if (rating != null) updates['rating'] = rating;
    if (comment != null) updates['comment'] = comment;

    if (images != null) {
      // For simplicity, we'll replace images. In a real app, we might want to manage individual images.
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final url = await _uploadImage(id, images[i], i);
        imageUrls.add(url);
      }
      updates['images'] = imageUrls;
    }

    if (rating != null && rating != reviewData['rating']) {
      // Need to update watch average rating
      await _firestore.runTransaction((transaction) async {
        final watchRef =
            _firestore.collection('watches').doc(reviewData['watchId']);
        final watchDoc = await transaction.get(watchRef);

        final watchData = watchDoc.data()!;
        final currentRating = (watchData['averageRating'] ?? 0.0).toDouble();
        final currentCount = watchData['reviewCount'] ?? 0;

        final newRating =
            ((currentRating * currentCount) - reviewData['rating'] + rating) /
                currentCount;

        transaction.update(reviewRef, updates);
        transaction.update(watchRef, {'averageRating': newRating});
      });
    } else {
      await reviewRef.update(updates);
    }

    final updatedDoc = await reviewRef.get();
    return Review.fromFirestore(updatedDoc);
  }

  Future<void> deleteReview(String id) async {
    if (uid == null) throw Exception('User not logged in');

    final reviewRef = _firestore.collection('reviews').doc(id);
    final reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists) throw Exception('Review not found');

    final reviewData = reviewDoc.data()!;

    await _firestore.runTransaction((transaction) async {
      final watchRef =
          _firestore.collection('watches').doc(reviewData['watchId']);
      final watchDoc = await transaction.get(watchRef);

      final watchData = watchDoc.data()!;
      final currentRating = (watchData['averageRating'] ?? 0.0).toDouble();
      final currentCount = watchData['reviewCount'] ?? 0;

      if (currentCount > 1) {
        final newCount = currentCount - 1;
        final newRating =
            ((currentRating * currentCount) - reviewData['rating']) / newCount;
        transaction.update(watchRef, {
          'averageRating': newRating,
          'reviewCount': newCount,
        });
      } else {
        transaction.update(watchRef, {
          'averageRating': 0.0,
          'reviewCount': 0,
        });
      }

      transaction.delete(reviewRef);
    });
  }

  Future<void> markReviewHelpful(String id) async {
    if (uid == null) throw Exception('User not logged in');
    await _firestore.collection('reviews').doc(id).update({
      'helpfulCount': FieldValue.increment(1),
    });
  }
}
