import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../models/review.dart';
import '../utils/error_handler.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  List<Review> _reviews = [];
  Map<String, dynamic>? _ratingDistribution;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  List<Review> get reviews => _reviews;
  Map<String, dynamic>? get ratingDistribution => _ratingDistribution;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isLoading; // Alias for clarity in UI
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _currentPage < _totalPages;

  Future<void> fetchWatchReviews(String watchId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _reviews = [];
      _isLoading = true;
    } else if (!hasMorePages) {
      return;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _reviewService.getWatchReviews(
        watchId,
        page: _currentPage,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final List<Review> fetchedReviews = result['reviews'] as List<Review>;

      if (refresh) {
        _reviews = fetchedReviews;
        _ratingDistribution =
            result['ratingDistribution'] as Map<String, dynamic>?;
      } else {
        _reviews.addAll(fetchedReviews);
      }

      _totalPages = (result['pagination']['totalPages'] as num).toInt();
      _currentPage++;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      print('Error fetching reviews: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReview(Review review, {List<XFile>? images}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newReview =
          await _reviewService.createReview(review, images: images);

      // Add the new review to the list immediately
      _reviews.insert(0, newReview);
      notifyListeners();

      // Refresh reviews to get updated rating distribution
      // Add a small delay to ensure Firestore has indexed the new review for queries
      await Future.delayed(const Duration(milliseconds: 300));
      await fetchWatchReviews(review.watchId, refresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReview(String id,
      {int? rating, String? comment, List<XFile>? images}) async {
    try {
      final updatedReview = await _reviewService.updateReview(
        id,
        rating: rating,
        comment: comment,
        images: images,
      );

      final index = _reviews.indexWhere((r) => r.id == id);
      if (index != -1) {
        final watchId = _reviews[index].watchId;
        _reviews[index] = updatedReview;
        // Refresh reviews to get updated rating distribution
        await fetchWatchReviews(watchId, refresh: true);
      }
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview(String id) async {
    try {
      final reviewToDelete = _reviews.firstWhere((r) => r.id == id);
      final watchId = reviewToDelete.watchId;

      await _reviewService.deleteReview(id);
      _reviews.removeWhere((r) => r.id == id);
      // Refresh reviews to get updated rating distribution
      await fetchWatchReviews(watchId, refresh: true);
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> markReviewHelpful(String id) async {
    try {
      await _reviewService.markReviewHelpful(id);
      final index = _reviews.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Note: Would need to update the review with new helpful count
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
    }
  }

  void setSortOrder(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    notifyListeners();
  }

  void clearReviews() {
    _reviews = [];
    _ratingDistribution = null;
    _currentPage = 1;
    _totalPages = 1;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper methods
  Review? getUserReview(String watchId, String userId) {
    try {
      return _reviews.firstWhere(
        (review) => review.watchId == watchId && review.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  bool hasUserReviewed(String watchId, String userId) {
    return getUserReview(watchId, userId) != null;
  }
}
