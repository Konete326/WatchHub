import 'dart:async';
import 'package:flutter/material.dart';
import '../services/watch_service.dart';
import '../models/watch.dart';
import '../models/brand.dart';
import '../models/home_banner.dart';
import '../models/promotion_banner.dart';
import '../models/category.dart';
import '../utils/error_handler.dart';

class WatchProvider with ChangeNotifier {
  final WatchService _watchService = WatchService();

  List<Watch> _watches = [];
  List<Watch> _featuredWatches = [];
  List<Brand> _brands = [];
  List<Category> _categories = [];
  List<HomeBanner> _banners = [];
  PromotionBanner? _promotionHighlight;
  Watch? _selectedWatch;
  List<Watch> _relatedWatches = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  Map<String, dynamic> _filters = {};
  Timer? _debounceTimer;

  List<Watch> get watches => _watches;
  List<Watch> get featuredWatches => _featuredWatches;
  List<Brand> get brands => _brands;
  List<Category> get categories => _categories;
  List<HomeBanner> get banners => _banners;
  PromotionBanner? get promotionHighlight => _promotionHighlight;
  Watch? get selectedWatch => _selectedWatch;
  List<Watch> get relatedWatches => _relatedWatches;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _currentPage < _totalPages;

  Future<void> fetchFeaturedWatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _featuredWatches = await _watchService.getFeaturedWatches(limit: 10);
      // Don't set error message if empty - just show empty state in UI
      if (_featuredWatches.isEmpty) {
        _errorMessage = null; // Clear error, let UI handle empty state
      }
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _featuredWatches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBrands() async {
    try {
      _brands = await _watchService.getBrands();
      notifyListeners();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _brands = [];
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await _watchService.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _categories = [];
      notifyListeners();
    }
  }

  Future<void> fetchBanners() async {
    try {
      _banners = await _watchService.getBanners();
      notifyListeners();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _banners = [];
      notifyListeners();
    }
  }

  Future<void> fetchPromotionHighlight() async {
    try {
      _promotionHighlight = await _watchService.getPromotionHighlight();
      notifyListeners();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _promotionHighlight = null;
      notifyListeners();
    }
  }

  Future<void> fetchWatches({
    bool refresh = false,
    String? search,
    String? brandId,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool onlySale = false,
    String? strapType,
    bool inStockOnly = false,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    // Prevent multiple calls if already loading
    if (refresh) {
      if (_isLoading) return;
    } else {
      if (_isLoadingMore || !hasMorePages || _isLoading) return;
    }

    // Cancel existing debounce timer if any
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // Use a small debounce for non-refresh calls (pagination/scroll)
    // to prevent accidental multiple triggers from fast scrolling
    if (!refresh) {
      final completer = Completer<void>();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
        try {
          await _executeFetchWatches(
            refresh: refresh,
            search: search,
            brandId: brandId,
            category: category,
            minPrice: minPrice,
            maxPrice: maxPrice,
            onlySale: onlySale,
            strapType: strapType,
            inStockOnly: inStockOnly,
            sortBy: sortBy,
            sortOrder: sortOrder,
          );
        } finally {
          completer.complete();
        }
      });
      return completer.future;
    }

    // Direct execution for refresh
    return _executeFetchWatches(
      refresh: refresh,
      search: search,
      brandId: brandId,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      onlySale: onlySale,
      strapType: strapType,
      inStockOnly: inStockOnly,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  Future<void> _executeFetchWatches({
    bool refresh = false,
    String? search,
    String? brandId,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool onlySale = false,
    String? strapType,
    bool inStockOnly = false,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    if (refresh) {
      _currentPage = 1;
      _watches = [];
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      _filters = {
        'search': search,
        'brandId': brandId,
        'category': category,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'onlySale': onlySale,
        'strapType': strapType,
        'inStockOnly': inStockOnly,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      final result = await _watchService.getWatches(
        page: _currentPage,
        search: search,
        brandId: brandId,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        onlySale: onlySale,
        strapType: strapType,
        inStockOnly: inStockOnly,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      final List<Watch> fetchedWatches = result['watches'];

      if (refresh) {
        _watches = fetchedWatches;
      } else {
        _watches.addAll(fetchedWatches);
      }

      _totalPages = result['pagination']['totalPages'];
      _currentPage++;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchWatchById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedWatch = null;
    _relatedWatches = [];
    notifyListeners();

    try {
      final result = await _watchService.getWatchById(id);
      _selectedWatch = result['watch'];
      _relatedWatches = result['relatedWatches'];
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchWatches(String query) async {
    await fetchWatches(refresh: true, search: query);
  }

  void clearSelectedWatch() {
    _selectedWatch = null;
    _relatedWatches = [];
    notifyListeners();
  }

  Future<List<String>> getSuggestions(String query) async {
    return await _watchService.getSuggestions(query);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
