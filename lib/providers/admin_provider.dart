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
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return (value as num).toDouble();
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _adminService.getDashboardStats();
      _dashboardStats = data;

      // In the new Firestore-based getDashboardStats, I don't fetch recent orders or low stock watches
      // yet to keep it simple. If the UI needs them, I should add them back or let the UI fetch them.
      // For now, I'll clear them to avoid showing stale data.
      _recentOrders = [];
      _lowStockWatches = [];
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
        brand.name.trim().toLowerCase() == name.trim().toLowerCase()
      );

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
