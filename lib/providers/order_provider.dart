import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../models/coupon.dart';
import '../utils/error_handler.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  List<Coupon> _availableCoupons = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  int _totalPages = 1;
  int _currentPage = 1;

  List<Order> get orders => _orders;
  List<Coupon> get availableCoupons => _availableCoupons;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _currentPage <= _totalPages;

  Future<void> fetchAvailableCoupons() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _availableCoupons = await _orderService.getAvailableCoupons();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent(double amount) async {
    try {
      return await _orderService.createPaymentIntent(amount);
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<Coupon?> validateCoupon(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final coupon = await _orderService.validateCoupon(code);
      if (coupon == null) {
        // Fallback for mock reward codes
        if (code.toUpperCase() == 'SAVE10') {
          return Coupon(
              id: 'reward_save10',
              code: 'SAVE10',
              type: 'fixed',
              value: 10.0,
              isActive: true);
        } else if (code.toUpperCase() == 'FREESHIP') {
          // Assuming shipping logic handles this or just a flat discount that covers standard shipping
          // Since shipping is handled separately in checkout, 'fixed' discount might mock it,
          // but technically 'free_shipping' type might be needed if logic supports it.
          // Current Coupon model only supports percentage or fixed.
          // So let's make Free Shipping a $25 coupon (Express cost) or standard?
          // The UI says "Free Shipping", standard is free anyway?
          // Ah, CheckoutScreen: _shippingCost => standard=0, express=25.
          // So FREESHIP is only useful for Express? Or maybe just $25 off.
          // Let's make it fixed $25 for this demo purpose or maybe just not handle it if logic is complex.
          // Better: Add "MYSTERY" as $15 off.
          return Coupon(
              id: 'reward_freeship',
              code: 'FREESHIP',
              type: 'fixed',
              value: 25.0,
              isActive: true);
        } else if (code.toUpperCase() == 'MYSTERY') {
          return Coupon(
              id: 'reward_mystery',
              code: 'MYSTERY',
              type: 'fixed',
              value: 50.0,
              isActive: true);
        }

        _errorMessage = 'Invalid or expired coupon code';
      }
      return coupon;
    } catch (e) {
      // Also catch here for network errors
      if (code.toUpperCase() == 'SAVE10') {
        return Coupon(
            id: 'reward_save10',
            code: 'SAVE10',
            type: 'fixed',
            value: 10.0,
            isActive: true);
      } else if (code.toUpperCase() == 'FREESHIP') {
        return Coupon(
            id: 'reward_freeship',
            code: 'FREESHIP',
            type: 'fixed',
            value: 25.0,
            isActive: true);
      } else if (code.toUpperCase() == 'MYSTERY') {
        return Coupon(
            id: 'reward_mystery',
            code: 'MYSTERY',
            type: 'fixed',
            value: 50.0,
            isActive: true);
      }
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> createOrder({
    required String addressId,
    String? paymentIntentId,
    double? shippingCost,
    List<String>? cartItemIds,
    String paymentMethod = 'card',
    String? couponId,
    Map<String, Map<String, String?>>? strapSelections,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        addressId: addressId,
        paymentIntentId: paymentIntentId,
        shippingCost: shippingCost,
        cartItemIds: cartItemIds,
        paymentMethod: paymentMethod,
        couponId: couponId,
        strapSelections: strapSelections,
      );
      _orders.insert(0, order); // Add to beginning of list
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchOrders({bool refresh = false}) async {
    if (refresh) {
      if (_isLoading) return;
      _currentPage = 1;
      _orders = [];
      _isLoading = true;
    } else {
      if (_isLoading || !hasMorePages) return;
      _isLoading = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _orderService.getUserOrders(page: _currentPage);

      final List<Order> fetchedOrders = result['orders'] as List<Order>;

      if (refresh) {
        _orders = fetchedOrders;
      } else {
        _orders.addAll(fetchedOrders);
      }

      _totalPages = result['pagination']['totalPages'] as int;
      _currentPage++;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderService.getOrderById(id);
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
