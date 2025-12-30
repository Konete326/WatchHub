import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/watch_service.dart';
import '../models/cart_item.dart';
import '../models/app_settings.dart';
import '../utils/error_handler.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  final WatchService _watchService = WatchService();

  List<CartItem> _cartItems = [];
  Set<String> _selectedItemIds = {};
  double _subtotal = 0;
  double _deliveryCharge = 0;
  int _itemCount = 0;
  AppSettings? _settings;
  bool _isLoading = false;
  bool _addedToCart = false;
  String? _errorMessage;

  List<CartItem> get cartItems => _cartItems;
  Set<String> get selectedItemIds => _selectedItemIds;
  bool get addedToCart => _addedToCart;

  void consumeAddedToCart() {
    _addedToCart = false;
  }

  void triggerAddedToCartAnimation() {
    _addedToCart = true;
    notifyListeners();
  }

  List<CartItem> get selectedItems =>
      _cartItems.where((item) => _selectedItemIds.contains(item.id)).toList();

  double get subtotal {
    if (_selectedItemIds.isEmpty) return _subtotal;
    return selectedItems.fold(0,
        (sum, item) => sum + (item.watch?.currentPrice ?? 0) * item.quantity);
  }

  double get deliveryCharge {
    if (_selectedItemIds.isEmpty) return _deliveryCharge;
    return _settings?.calculateDelivery(selectedItemCount, subtotal) ?? 0;
  }

  double get totalAmount => subtotal + deliveryCharge;

  int get itemCount => _itemCount;

  int get selectedItemCount {
    if (_selectedItemIds.isEmpty) return 0;
    return selectedItems.fold(0, (sum, item) => sum + item.quantity);
  }

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _cartItems.isEmpty;
  bool get hasSelection => _selectedItemIds.isNotEmpty;
  bool get isAllSelected =>
      _cartItems.isNotEmpty && _selectedItemIds.length == _cartItems.length;

  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _cartService.getCart();
      _cartItems = result as List<CartItem>;
      _subtotal = _cartItems.fold(0,
          (sum, item) => sum + (item.watch?.currentPrice ?? 0) * item.quantity);
      _itemCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);

      // Fetch settings for delivery calculation
      if (_settings == null) {
        _settings = await _watchService.getAppSettings();
      }
      _deliveryCharge =
          _settings?.calculateDelivery(_itemCount, _subtotal) ?? 0;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(String watchId, {int quantity = 1}) async {
    try {
      await _cartService.addToCart(watchId, quantity: quantity);
      _addedToCart = true;
      await fetchCart(); // Refresh cart
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(String id, int quantity) async {
    try {
      await _cartService.updateCartItem(id, quantity);
      await fetchCart(); // Refresh cart
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(String id) async {
    try {
      await _cartService.removeFromCart(id);
      await fetchCart(); // Refresh cart
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      await _cartService.clearCart();
      _cartItems = [];
      _subtotal = 0;
      _itemCount = 0;
      _selectedItemIds.clear(); // Clear selections when cart is cleared
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  void toggleSelection(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
    } else {
      _selectedItemIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(bool select) {
    if (select) {
      _selectedItemIds = _cartItems.map((item) => item.id).toSet();
    } else {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }

  Future<bool> deleteSelectedItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      for (final id in _selectedItemIds) {
        await _cartService.removeFromCart(id);
      }
      _selectedItemIds.clear();
      await fetchCart();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
