import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/review.dart';
import '../models/user.dart';
import 'cloudinary_service.dart';
import 'package:flutter/foundation.dart';

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
    bool approvedOnly = true,
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

      Query query =
          _firestore.collection('reviews').where('watchId', isEqualTo: watchId);
      if (approvedOnly) {
        query = query.where('status', isEqualTo: 'approved');
      }

      final allReviewsSnapshot = await query.get();

      for (var doc in allReviewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final rating = (data?['rating'] as num?)?.toInt();
        if (rating != null && rating >= 1 && rating <= 5) {
          final ratingKey = rating.toString();
          ratingDistribution[ratingKey] =
              (ratingDistribution[ratingKey] as int? ?? 0) + 1;
        }
      }

      final allDocs = allReviewsSnapshot.docs.toList();

      allDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>?;
        final bData = b.data() as Map<String, dynamic>?;

        // Featured reviews always come first
        final aFeat = aData?['isFeatured'] == true;
        final bFeat = bData?['isFeatured'] == true;
        if (aFeat != bFeat) return aFeat ? -1 : 1;

        if (sortBy == 'rating') {
          final aRating = (aData?['rating'] as num?)?.toInt() ?? 0;
          final bRating = (bData?['rating'] as num?)?.toInt() ?? 0;
          return sortOrder == 'desc'
              ? bRating.compareTo(aRating)
              : aRating.compareTo(bRating);
        } else {
          final aTime =
              (aData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime =
              (bData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return sortOrder == 'desc'
              ? bTime.compareTo(aTime)
              : aTime.compareTo(bTime);
        }
      });

      final startIndex = (page - 1) * limit;
      final paginatedDocs = allDocs.length > startIndex
          ? allDocs.sublist(
              startIndex, (startIndex + limit).clamp(0, allDocs.length))
          : [];

      for (var doc in paginatedDocs) {
        try {
          final review = Review.fromFirestore(doc);
          User? user;
          try {
            final userDoc =
                await _firestore.collection('users').doc(review.userId).get();
            if (userDoc.exists) user = User.fromFirestore(userDoc);
          } catch (e) {
            debugPrint('Error fetching user for review ${review.id}: $e');
          }

          reviews.add(Review.fromJson({
            ...review.toJson(),
            'id': review.id,
            'user': user?.toJson(),
            'createdAt': review.createdAt.toIso8601String(),
            if (review.adminReplyAt != null)
              'adminReplyAt': review.adminReplyAt!.toIso8601String(),
          }));
        } catch (e) {
          debugPrint('Error processing review doc: $e');
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
      rethrow;
    }
  }

  String? _checkAutoFlag(String comment, int rating) {
    final forbiddenKeywords = ['scam', 'fake', 'worst', 'stolen', 'garbage'];
    final lowerComment = comment.toLowerCase();

    for (var keyword in forbiddenKeywords) {
      if (lowerComment.contains(keyword)) {
        return 'Keyword Match: $keyword';
      }
    }

    if (rating == 1 && comment.length < 10) {
      return 'Potential Spam: Short 1-star review';
    }

    return null;
  }

  double _calculateSentiment(String comment) {
    final positive = [
      'great',
      'excellent',
      'amazing',
      'beautiful',
      'quality',
      'perfect'
    ];
    final negative = ['bad', 'poor', 'slow', 'broken', 'plastic', 'ugly'];

    int score = 0;
    final words = comment.toLowerCase().split(' ');
    for (var word in words) {
      if (positive.contains(word)) score++;
      if (negative.contains(word)) score--;
    }

    return (score / (words.length + 1)).clamp(-1.0, 1.0);
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

    final flagReason = _checkAutoFlag(review.comment, review.rating);
    final sentiment = _calculateSentiment(review.comment);
    final status = flagReason != null ? 'flagged' : 'pending';

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
        'status': status,
        'flagReason': flagReason,
        'sentimentScore': sentiment,
        'isFeatured': false,
        'tags': [
          if (imageUrls.isNotEmpty) 'photo',
          'verified',
        ],
      });

      if (status == 'approved') {
        // If we change it to auto-approve in future
        transaction.update(watchRef, {
          'averageRating': newRating,
          'reviewCount': newCount,
        });
      }
    });

    // Fetch the actual review document
    final doc = await reviewRef.get();
    if (doc.exists) {
      final reviewFromDoc = Review.fromFirestore(doc);
      final userDoc =
          await _firestore.collection('users').doc(reviewFromDoc.userId).get();
      User? user;
      if (userDoc.exists) user = User.fromFirestore(userDoc);

      return Review.fromJson({
        ...reviewFromDoc.toJson(),
        'id': reviewFromDoc.id,
        'user': user?.toJson(),
        'createdAt': reviewFromDoc.createdAt.toIso8601String(),
      });
    }

    // Fallback if document doesn't exist (shouldn't happen)
    throw Exception('Failed to create review');
  }

  Future<Review> updateReview(String id,
      {int? rating,
      String? comment,
      List<XFile>? images,
      String? status}) async {
    if (uid == null) throw Exception('User not logged in');

    final reviewRef = _firestore.collection('reviews').doc(id);
    final reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists) throw Exception('Review not found');

    final reviewData = reviewDoc.data()!;
    final oldRating = (reviewData['rating'] as num).toInt();
    final oldStatus = reviewData['status'] as String;

    final updates = <String, dynamic>{};
    if (rating != null) updates['rating'] = rating;
    if (comment != null) updates['comment'] = comment;
    if (status != null) updates['status'] = status;

    if (images != null) {
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final url = await _uploadImage(id, images[i], i);
        imageUrls.add(url);
      }
      updates['images'] = imageUrls;
    }

    // Update watch average rating only if status is or becomes 'approved'
    if ((rating != null && rating != oldRating) ||
        (status != null && status != oldStatus)) {
      await _firestore.runTransaction((transaction) async {
        final watchRef =
            _firestore.collection('watches').doc(reviewData['watchId']);
        final watchDoc = await transaction.get(watchRef);

        final watchData = watchDoc.data()!;
        double totalRating = (watchData['averageRating'] ?? 0.0).toDouble() *
            (watchData['reviewCount'] ?? 0);
        int totalCount = watchData['reviewCount'] ?? 0;

        // Remove old rating if it was approved
        if (oldStatus == 'approved') {
          totalRating -= oldRating;
          totalCount -= 1;
        }

        // Add new rating if it is now approved
        final newStatus = status ?? oldStatus;
        final newRatingValue = rating ?? oldRating;

        if (newStatus == 'approved') {
          totalRating += newRatingValue;
          totalCount += 1;
        }

        final newAverageRating =
            totalCount > 0 ? totalRating / totalCount : 0.0;

        transaction.update(reviewRef, updates);
        transaction.update(watchRef, {
          'averageRating': newAverageRating,
          'reviewCount': totalCount,
        });
      });
    } else {
      await reviewRef.update(updates);
    }

    final updatedDoc = await reviewRef.get();
    return Review.fromFirestore(updatedDoc);
  }

  Future<void> approveReview(String id, {bool isFeatured = false}) async {
    await updateReview(id, status: 'approved');
    if (isFeatured) {
      await _firestore
          .collection('reviews')
          .doc(id)
          .update({'isFeatured': true});
    }
  }

  Future<void> deleteReview(String id) async {
    if (uid == null) throw Exception('User not logged in');

    final reviewRef = _firestore.collection('reviews').doc(id);
    final reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists) throw Exception('Review not found');

    final reviewData = reviewDoc.data()!;
    final status = reviewData['status'] as String;
    final rating = (reviewData['rating'] as num).toInt();

    await _firestore.runTransaction((transaction) async {
      if (status == 'approved') {
        final watchRef =
            _firestore.collection('watches').doc(reviewData['watchId']);
        final watchDoc = await transaction.get(watchRef);

        final watchData = watchDoc.data()!;
        double totalRating = (watchData['averageRating'] ?? 0.0).toDouble() *
            (watchData['reviewCount'] ?? 0);
        int totalCount = watchData['reviewCount'] ?? 0;

        if (totalCount > 1) {
          totalCount -= 1;
          totalRating -= rating;
          final newRating = totalRating / totalCount;
          transaction.update(watchRef, {
            'averageRating': newRating,
            'reviewCount': totalCount,
          });
        } else {
          transaction.update(watchRef, {
            'averageRating': 0.0,
            'reviewCount': 0,
          });
        }
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

  Future<bool> checkCanReview(String watchId) async {
    if (uid == null) return false;

    try {
      // 1. Check if user already reviewed
      final existingReview = await _firestore
          .collection('reviews')
          .where('watchId', isEqualTo: watchId)
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Already reviewed, so they "can't" review again (or it would be an update)
        // But the requirement is to restrict to buyers.
        // Let's assume they can only leave one review.
        return false;
      }

      // 2. Check for delivered orders containing this watch
      final deliveredOrders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'DELIVERED')
          .get();

      for (var orderDoc in deliveredOrders.docs) {
        final items = await orderDoc.reference
            .collection('orderItems')
            .where('watchId', isEqualTo: watchId)
            .limit(1)
            .get();

        if (items.docs.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if user can review: $e');
      return false;
    }
  }
}
