import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/order.dart';
import '../models/watch.dart';
import '../models/home_banner.dart';
import '../models/app_settings.dart';
import '../models/coupon.dart';
import '../models/promotion_banner.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../utils/error_handler.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();

  // Dashboard Stats
  Map<String, dynamic>? _dashboardStats;
  String _period = 'week';
  List<Order> _recentOrders = [];
  List<Watch> _lowStockWatches = [];
  List<HomeBanner> _banners = [];
  List<Coupon> _coupons = [];
  List<Brand> _brands = [];
  List<Category> _categories = [];
  AppSettings? _settings;
  PromotionBanner? _promotionHighlight;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  String get period => _period;
  List<Order> get recentOrders => _recentOrders;
  List<Watch> get lowStockWatches => _lowStockWatches;
  List<HomeBanner> get banners => _banners;
  List<Coupon> get coupons => _coupons;
  List<Brand> get brands => _brands;
  List<Category> get categories => _categories;
  AppSettings? get settings => _settings;
  PromotionBanner? get promotionHighlight => _promotionHighlight;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setPeriod(String newPeriod) {
    if (_period != newPeriod) {
      _period = newPeriod;
      fetchDashboardStats();
    }
  }

  // Getters for stats
  int get totalUsers {
    final value = _dashboardStats?['totalUsers'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return (value as num).toInt();
  }

  int get totalOrders {
    final value = _dashboardStats?['totalOrders'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return (value as num).toInt();
  }

  int get totalWatches {
    final value = _dashboardStats?['totalWatches'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return (value as num).toInt();
  }

  double get totalRevenue {
    final value = _dashboardStats?['totalRevenue'];
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }

  double get aov {
    final value = _dashboardStats?['aov'];
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }

  double get conversionRate {
    final value = _dashboardStats?['conversion'];
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }

  double get returningRate {
    final value = _dashboardStats?['returningRate'];
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }

  Map<String, double> get salesTrend {
    final trend = _dashboardStats?['salesTrend'];
    if (trend == null) return {};
    return Map<String, double>.from(trend);
  }

  List<Watch> get topSelling {
    final top = _dashboardStats?['topSelling'];
    if (top == null) return [];
    return List<Watch>.from(top);
  }

  Map<String, double> get categoryRevenue {
    final revenue = _dashboardStats?['categoryRevenue'];
    if (revenue == null) return {};
    return Map<String, double>.from(revenue);
  }

  Map<String, double> get brandSales {
    final revenue = _dashboardStats?['brandRevenue'];
    if (revenue == null) return {};
    return Map<String, double>.from(revenue);
  }

  Map<String, double> get paymentMethodStats {
    final stats = _dashboardStats?['paymentMethodStats'];
    if (stats == null) return {};
    return Map<String, double>.from(stats);
  }

  List<Map<String, dynamic>> get recentActivity {
    final activity = _dashboardStats?['recentActivity'];
    if (activity == null) return [];
    return List<Map<String, dynamic>>.from(activity);
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _adminService.getDashboardStats(period: _period);
      _dashboardStats = data;

      // Extract low stock watches
      final allWatches = data['allWatches'] as List<Watch>? ?? [];
      if (allWatches.isNotEmpty) {
        _lowStockWatches = allWatches.where((w) => w.isLowStock).toList();
      } else {
        _lowStockWatches = [];
      }

      _recentOrders = [];
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Banners Management
  Future<void> fetchAllBanners() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _banners = await _adminService.getAllBanners();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBanner({
    required dynamic imageFile, // XFile for web, File for mobile
    String? title,
    String? subtitle,
    String? link,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? allowedSegments,
    List<String>? targetDevices,
    String? abTestId,
    String? version,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.createBanner(
        imageFile: imageFile,
        title: title,
        subtitle: subtitle,
        link: link,
        startDate: startDate,
        endDate: endDate,
        allowedSegments: allowedSegments,
        targetDevices: targetDevices,
        abTestId: abTestId,
        version: version,
      );
      await fetchAllBanners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBanner(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.updateBanner(id, data);
      await fetchAllBanners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBanner(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.deleteBanner(id);
      await fetchAllBanners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // App Settings Management
  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _adminService.getSettings();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(AppSettings settings) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _adminService.updateSettings(settings);
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Coupon Management
  Future<void> fetchAllCoupons() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _coupons = await _adminService.getAllCoupons();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCoupon(Coupon coupon) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newCoupon = await _adminService.createCoupon(coupon);
      _coupons.insert(0, newCoupon);
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCoupon(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.updateCoupon(id, data);
      await fetchAllCoupons();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCoupon(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.deleteCoupon(id);
      _coupons.removeWhere((c) => c.id == id);
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Promotion Highlight Management
  Future<void> fetchPromotionHighlight() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _promotionHighlight = await _adminService.getPromotionHighlight();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePromotionHighlight({
    required String type,
    dynamic imageFile, // XFile for web, File for mobile
    String? title,
    String? subtitle,
    String? backgroundColor,
    String? textColor,
    String? link,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _promotionHighlight = await _adminService.updatePromotionHighlight(
        type: type,
        imageFile: imageFile,
        title: title,
        subtitle: subtitle,
        backgroundColor: backgroundColor,
        textColor: textColor,
        link: link,
        isActive: isActive,
      );
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Brand Management
  Future<void> fetchAllBrands() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _brands = await _adminService.getAllBrands();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBrand({
    required String name,
    String? description,
    dynamic logoFile, // XFile for web, File for mobile
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Pehle check karein ke kya is naam ka brand list mein maujood hai
      // Case-insensitive check ke liye .toLowerCase() use kiya hai
      bool exists = _brands.any((brand) =>
          brand.name.trim().toLowerCase() == name.trim().toLowerCase());

      if (exists) {
        _errorMessage = "Brand with this name already exists!";
        _isLoading = false;
        notifyListeners();
        return false; // Function yahan stop ho jayega
      }

      // 2. Agar nahi hai, toh service call karein
      await _adminService.createBrand(
        name: name,
        description: description,
        logoFile: logoFile,
      );

      await fetchAllBrands();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBrand({
    required String id,
    String? name,
    String? description,
    dynamic logoFile, // XFile for web, File for mobile
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.updateBrand(
        id: id,
        name: name,
        description: description,
        logoFile: logoFile,
      );
      await fetchAllBrands();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBrand(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.deleteBrand(id);
      await fetchAllBrands();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Category Management
  Future<void> fetchAllCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _categories = await _adminService.getAllCategories();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    String? description,
    dynamic imageFile, // XFile for web, File for mobile
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.createCategory(
        name: name,
        description: description,
        imageFile: imageFile,
      );
      await fetchAllCategories();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    dynamic imageFile, // XFile for web, File for mobile
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.updateCategory(
        id: id,
        name: name,
        description: description,
        imageFile: imageFile,
      );
      await fetchAllCategories();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.deleteCategory(id);
      await fetchAllCategories();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateWatchStock(String watchId, int newStock) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _adminService.updateWatch(id: watchId, stock: newStock);
      // Update local state if successful
      if (_dashboardStats != null) {
        // Update in all watches
        final allWatches = _dashboardStats!['allWatches'] as List<Watch>?;
        if (allWatches != null) {
          final index = allWatches.indexWhere((w) => w.id == watchId);
          if (index != -1) {
            allWatches[index] = allWatches[index].copyWith(stock: newStock);
          }

          // Re-evaluate low stock list
          _lowStockWatches = allWatches.where((w) => w.isLowStock).toList();
        }
      }
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
