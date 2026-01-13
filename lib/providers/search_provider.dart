import 'package:flutter/material.dart';

class FilterPreset {
  final String name;
  final String? category;
  final String? brandId;
  final double minPrice;
  final double maxPrice;
  final bool onlySale;
  final String? strapType;

  FilterPreset({
    required this.name,
    this.category,
    this.brandId,
    this.minPrice = 0,
    this.maxPrice = 50000,
    this.onlySale = false,
    this.strapType,
  });
}

class SearchProvider with ChangeNotifier {
  List<String> _recentSearches = ['Rolex', 'Omega', 'Automatic', 'Leather'];
  List<String> _trendingTerms = [
    'Limited Edition',
    'Dive Watch',
    'Skeleton',
    'Chrono'
  ];
  List<FilterPreset> _presets = [];
  bool _isGridView = true;

  List<String> get recentSearches => _recentSearches;
  List<String> get trendingTerms => _trendingTerms;
  List<FilterPreset> get presets => _presets;
  bool get isGridView => _isGridView;

  void addRecentSearch(String term) {
    if (term.isEmpty) return;
    _recentSearches.remove(term);
    _recentSearches.insert(0, term);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
    notifyListeners();
  }

  void removeRecentSearch(String term) {
    _recentSearches.remove(term);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches = [];
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void savePreset(FilterPreset preset) {
    _presets.add(preset);
    notifyListeners();
  }

  void removePreset(String name) {
    _presets.removeWhere((p) => p.name == name);
    notifyListeners();
  }
}
