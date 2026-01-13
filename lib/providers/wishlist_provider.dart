import 'package:flutter/material.dart';
import '../services/wishlist_service.dart';
import '../models/wishlist_item.dart';
import '../utils/error_handler.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();

  List<WishlistItem> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _wishlistWatchIds = {};

  List<WishlistItem> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _wishlistItems.isEmpty;
  int get itemCount => _wishlistItems.length;

  bool isInWishlist(String watchId) {
    return _wishlistWatchIds.contains(watchId);
  }

  Future<void> fetchWishlist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wishlistItems = await _wishlistService.getWishlist();
      _wishlistWatchIds = _wishlistItems.map((item) => item.watchId).toSet();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToWishlist(String watchId) async {
    try {
      await _wishlistService.addToWishlist(watchId);
      _wishlistWatchIds.add(watchId);
      await fetchWishlist(); // Refresh wishlist
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromWishlist(String id, String watchId) async {
    try {
      await _wishlistService.removeFromWishlist(id);
      _wishlistWatchIds.remove(watchId);
      await fetchWishlist(); // Refresh wishlist
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleWishlist(String watchId, String? wishlistId) async {
    if (isInWishlist(watchId)) {
      return await removeFromWishlist(wishlistId!, watchId);
    } else {
      return await addToWishlist(watchId);
    }
  }

  Future<bool> moveToCart(String id) async {
    try {
      await _wishlistService.moveToCart(id);
      await fetchWishlist(); // Refresh wishlist
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Move all wishlist items to cart at once
  Future<int> moveAllToCart() async {
    int successCount = 0;
    final itemsToMove = List<WishlistItem>.from(_wishlistItems);

    for (final item in itemsToMove) {
      try {
        await _wishlistService.moveToCart(item.id);
        successCount++;
      } catch (e) {
        // Continue with other items even if one fails
        print('Failed to move item ${item.id}: $e');
      }
    }

    await fetchWishlist(); // Refresh wishlist after all moves
    return successCount;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
