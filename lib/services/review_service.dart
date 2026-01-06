import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/review.dart';
import '../models/user.dart';
import 'cloudinary_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<String> _uploadImage(String reviewId, XFile file, int index) async {
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
    try {
      final reviews = <Review>[];
      final ratingDistribution = <String, dynamic>{
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0
      };

      // Get all reviews for this watch (we'll sort client-side to avoid index issues)
      final allReviewsSnapshot = await _firestore
          .collection('reviews')
          .where('watchId', isEqualTo: watchId)
          .get();

      // Calculate rating distribution
      for (var doc in allReviewsSnapshot.docs) {
        final rating = doc.data()['rating'] as int?;
        if (rating != null && rating >= 1 && rating <= 5) {
          final ratingKey = rating.toString();
          ratingDistribution[ratingKey] =
              (ratingDistribution[ratingKey] as int? ?? 0) + 1;
        }
      }

      // Process all documents and sort client-side
      final allDocs = <DocumentSnapshot>[];
      for (var doc in allReviewsSnapshot.docs) {
        allDocs.add(doc);
      }

      // Sort documents client-side
      allDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>? ?? {};
        final bData = b.data() as Map<String, dynamic>? ?? {};

        if (sortBy == 'rating') {
          final aRating = aData['rating'] as int? ?? 0;
          final bRating = bData['rating'] as int? ?? 0;
          return sortOrder == 'desc'
              ? bRating.compareTo(aRating)
              : aRating.compareTo(bRating);
        } else if (sortBy == 'createdAt') {
          final aTime =
              (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime =
              (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return sortOrder == 'desc'
              ? bTime.compareTo(aTime)
              : aTime.compareTo(bTime);
        }
        return 0;
      });

      // Paginate
      final startIndex = (page - 1) * limit;
      final paginatedDocs = allDocs.length > startIndex
          ? allDocs.sublist(
              startIndex, (startIndex + limit).clamp(0, allDocs.length))
          : [];

      // Fetch user data for each review
      for (var doc in paginatedDocs) {
        try {
          final review = Review.fromFirestore(doc);
          User? user;

          // Try to fetch user data, but don't fail if user doesn't exist
          try {
            final userDoc =
                await _firestore.collection('users').doc(review.userId).get();
            if (userDoc.exists) {
              user = User.fromFirestore(userDoc);
            }
          } catch (e) {
            print('Error fetching user for review ${review.id}: $e');
            // Continue without user data
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
        } catch (e) {
          print('Error processing review document ${doc.id}: $e');
          // Skip this review and continue
          continue;
        }
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
    } catch (e) {
      print('Error in getWatchReviews: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<Review> createReview(Review review, {List<XFile>? images}) async {
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

    await _firestore.runTransaction((transaction) async {
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
    });

    // Fetch the actual review document to get the server timestamp
    final doc = await reviewRef.get();
    if (doc.exists) {
      final reviewFromDoc = Review.fromFirestore(doc);
      // Fetch user data for the review
      final userDoc =
          await _firestore.collection('users').doc(reviewFromDoc.userId).get();
      User? user;
      if (userDoc.exists) {
        user = User.fromFirestore(userDoc);
      }
      return Review(
        id: reviewFromDoc.id,
        userId: reviewFromDoc.userId,
        watchId: reviewFromDoc.watchId,
        rating: reviewFromDoc.rating,
        comment: reviewFromDoc.comment,
        images: reviewFromDoc.images,
        helpfulCount: reviewFromDoc.helpfulCount,
        createdAt: reviewFromDoc.createdAt,
        user: user,
      );
    }

    // Fallback if document doesn't exist (shouldn't happen)
    throw Exception('Failed to create review');
  }

  Future<Review> updateReview(String id,
      {int? rating, String? comment, List<XFile>? images}) async {
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
