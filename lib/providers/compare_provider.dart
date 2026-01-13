import 'package:flutter/material.dart';
import '../models/watch.dart';

class CompareProvider with ChangeNotifier {
  final List<Watch> _compareList = [];
  static const int maxItems = 3;

  List<Watch> get compareList => _compareList;

  void toggleCompare(Watch watch) {
    if (isInCompare(watch.id)) {
      _compareList.removeWhere((w) => w.id == watch.id);
    } else {
      if (_compareList.length < maxItems) {
        _compareList.add(watch);
      }
    }
    notifyListeners();
  }

  bool isInCompare(String watchId) {
    return _compareList.any((w) => w.id == watchId);
  }

  void clearCompare() {
    _compareList.clear();
    notifyListeners();
  }

  bool get isFull => _compareList.length >= maxItems;
}
