import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings.dart';
import '../models/settings_models.dart';
import '../utils/audit_logger.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String settingsDocId = 'general_settings';

  Future<AppSettings> getSettings() async {
    final doc =
        await _firestore.collection('settings').doc(settingsDocId).get();
    return AppSettings.fromFirestore(doc);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final oldSettings = await getSettings();
    await _firestore
        .collection('settings')
        .doc(settingsDocId)
        .set(settings.toJson());

    await AuditLogger.logSettingsUpdated(
      oldSettings.toJson(),
      settings.toJson(),
    );
  }

  // Shipping Specifics
  Future<void> updateShippingZones(List<ShippingZone> zones) async {
    final current = await getSettings();
    final updated = AppSettings(
      deliveryCharge: current.deliveryCharge,
      freeDeliveryThreshold: current.freeDeliveryThreshold,
      freeDeliveryAmountThreshold: current.freeDeliveryAmountThreshold,
      currencyCode: current.currencyCode,
      currencyExchangeRate: current.currencyExchangeRate,
      shippingZones: zones,
      taxRules: current.taxRules,
      returnPolicies: current.returnPolicies,
      channels: current.channels,
    );
    await updateSettings(updated);
  }

  // Tax Specifics
  Future<void> updateTaxRules(List<TaxRule> rules) async {
    final current = await getSettings();
    final updated = AppSettings(
      deliveryCharge: current.deliveryCharge,
      freeDeliveryThreshold: current.freeDeliveryThreshold,
      freeDeliveryAmountThreshold: current.freeDeliveryAmountThreshold,
      currencyCode: current.currencyCode,
      currencyExchangeRate: current.currencyExchangeRate,
      shippingZones: current.shippingZones,
      taxRules: rules,
      returnPolicies: current.returnPolicies,
      channels: current.channels,
    );
    await updateSettings(updated);
  }

  // Return Policy Specifics
  Future<void> updateReturnPolicies(List<ReturnPolicyTemplate> policies) async {
    final current = await getSettings();
    final updated = AppSettings(
      deliveryCharge: current.deliveryCharge,
      freeDeliveryThreshold: current.freeDeliveryThreshold,
      freeDeliveryAmountThreshold: current.freeDeliveryAmountThreshold,
      currencyCode: current.currencyCode,
      currencyExchangeRate: current.currencyExchangeRate,
      shippingZones: current.shippingZones,
      taxRules: current.taxRules,
      returnPolicies: policies,
      channels: current.channels,
    );
    await updateSettings(updated);
  }

  // Channel Specifics
  Future<void> updateChannels(List<AppChannel> channels) async {
    final current = await getSettings();
    final updated = AppSettings(
      deliveryCharge: current.deliveryCharge,
      freeDeliveryThreshold: current.freeDeliveryThreshold,
      freeDeliveryAmountThreshold: current.freeDeliveryAmountThreshold,
      currencyCode: current.currencyCode,
      currencyExchangeRate: current.currencyExchangeRate,
      shippingZones: current.shippingZones,
      taxRules: current.taxRules,
      returnPolicies: current.returnPolicies,
      channels: channels,
    );
    await updateSettings(updated);
  }
}
