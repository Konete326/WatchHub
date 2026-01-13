import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../models/settings_models.dart';
import '../services/settings_service.dart';
import '../models/audit_log.dart';
import '../services/audit_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  final AuditService _auditService = AuditService();

  AppSettings? _settings;
  AppSettings? get settings => _settings;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  List<AuditLog> _auditLogs = [];
  List<AuditLog> get auditLogs => _auditLogs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String get locale => _settings?.locale ?? 'en_US';

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  String formatPrice(double price) {
    if (_settings == null) return '\$${price.toStringAsFixed(2)}';
    final rate = _settings!.currencyExchangeRate;
    final code = _settings!.currencyCode;
    final converted = price * rate;

    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
      name: code,
    );
    return formatter.format(converted);
  }

  String formatDate(DateTime date) {
    // Uses the configured locale for localized date formats
    return DateFormat.yMMMMd(locale).add_jm().format(date);
  }

  String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> fetchSettings() async {
    await loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _settingsService.getSettings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateShippingZones(List<ShippingZone> zones) async {
    try {
      await _settingsService.updateShippingZones(zones);
      await loadSettings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTaxRules(List<TaxRule> rules) async {
    try {
      await _settingsService.updateTaxRules(rules);
      await loadSettings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateReturnPolicies(List<ReturnPolicyTemplate> policies) async {
    try {
      await _settingsService.updateReturnPolicies(policies);
      await loadSettings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateChannels(List<AppChannel> channels) async {
    try {
      await _settingsService.updateChannels(channels);
      await loadSettings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAuditLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _auditLogs = await _auditService.getAuditLogs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
