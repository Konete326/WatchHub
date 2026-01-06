import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../services/admin_service.dart';
import '../utils/error_handler.dart';

class SettingsProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();

  AppSettings? _settings;
  bool _isLoading = false;
  String? _errorMessage;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _adminService.getSettings();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      // Provide default settings on error to prevent app from breaking
      _settings ??= AppSettings(
        deliveryCharge: 0.0,
        freeDeliveryThreshold: 0,
        currencyCode: 'USD',
        currencyExchangeRate: 1.0,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Format price based on settings
  String formatPrice(double price) {
    if (_settings == null) {
      return NumberFormat.currency(symbol: r'$', decimalDigits: 0)
          .format(price);
    }

    final double convertedPrice = price * _settings!.currencyExchangeRate;
    final String symbol = _getCurrencySymbol(_settings!.currencyCode);

    // Customize decimal digits based on currency
    int decimalDigits = 0;
    if (_settings!.currencyCode == 'USD' || _settings!.currencyCode == 'EUR') {
      decimalDigits = 2;
    }

    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(convertedPrice);
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'PKR':
        return 'Rs ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'USD':
      default:
        return r'$';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
