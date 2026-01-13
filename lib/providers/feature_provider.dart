import 'package:flutter/material.dart';
import '../services/feature_service.dart';

class FeatureProvider with ChangeNotifier {
  final FeatureFlagService _service = FeatureFlagService();

  Map<String, FeatureFlag> _flags = {};
  bool _isLoading = false;
  String? _userId;

  bool get isLoading => _isLoading;

  void setUserId(String? uid) {
    _userId = uid;
    notifyListeners();
  }

  Future<void> loadFlags() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedFlags = await _service.getFlags();
      _flags = {for (var f in fetchedFlags) f.id: f};
    } catch (e) {
      debugPrint('Error loading feature flags: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isEnabled(String flagId) {
    final flag = _flags[flagId];
    if (flag == null) return FeatureFlagService.defaults[flagId] ?? false;
    return _service.isFeatureEnabled(flag, _userId ?? 'anonymous');
  }

  dynamic getVariation(String flagId, String key) {
    return _flags[flagId]?.variations[key];
  }
}
