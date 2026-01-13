import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_models.dart';

class AppSettings {
  final double deliveryCharge;
  final int freeDeliveryThreshold; // Number of items for free delivery
  final double? freeDeliveryAmountThreshold; // Optional amount threshold
  final String currencyCode; // e.g., 'USD', 'PKR', 'EUR'
  final double currencyExchangeRate; // Rate relative to a base (default 1.0)

  // Advanced Settings
  final List<ShippingZone> shippingZones;
  final List<TaxRule> taxRules;
  final List<ReturnPolicyTemplate> returnPolicies;
  final List<AppChannel> channels;
  final String locale; // e.g., 'en_US', 'de_DE'

  AppSettings({
    required this.deliveryCharge,
    required this.freeDeliveryThreshold,
    this.freeDeliveryAmountThreshold,
    this.currencyCode = 'USD',
    this.currencyExchangeRate = 1.0,
    this.locale = 'en_US',
    this.shippingZones = const [],
    this.taxRules = const [],
    this.returnPolicies = const [],
    this.channels = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      deliveryCharge: json['deliveryCharge'] != null
          ? double.parse(json['deliveryCharge'].toString())
          : 0.0,
      freeDeliveryThreshold: json['freeDeliveryThreshold'] as int? ?? 0,
      freeDeliveryAmountThreshold: json['freeDeliveryAmountThreshold'] != null
          ? double.parse(json['freeDeliveryAmountThreshold'].toString())
          : null,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      currencyExchangeRate: json['currencyExchangeRate'] != null
          ? double.parse(json['currencyExchangeRate'].toString())
          : 1.0,
      locale: json['locale'] as String? ?? 'en_US',
      shippingZones: (json['shippingZones'] as List? ?? [])
          .map((e) => ShippingZone.fromJson(e as Map<String, dynamic>))
          .toList(),
      taxRules: (json['taxRules'] as List? ?? [])
          .map((e) => TaxRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      returnPolicies: (json['returnPolicies'] as List? ?? [])
          .map((e) => ReturnPolicyTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      channels: (json['channels'] as List? ?? [])
          .map((e) => AppChannel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory AppSettings.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return AppSettings(deliveryCharge: 0, freeDeliveryThreshold: 0);
    }
    final data = doc.data() as Map<String, dynamic>;
    return AppSettings.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryCharge': deliveryCharge,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'freeDeliveryAmountThreshold': freeDeliveryAmountThreshold,
      'currencyCode': currencyCode,
      'currencyExchangeRate': currencyExchangeRate,
      'locale': locale,
      'shippingZones': shippingZones.map((e) => e.toJson()).toList(),
      'taxRules': taxRules.map((e) => e.toJson()).toList(),
      'returnPolicies': returnPolicies.map((e) => e.toJson()).toList(),
      'channels': channels.map((e) => e.toJson()).toList(),
    };
  }

  // Helper method to calculate delivery charge
  double calculateDelivery(int itemCount, double totalAmount) {
    if (freeDeliveryThreshold > 0 && itemCount >= freeDeliveryThreshold) {
      return 0.0;
    }
    if (freeDeliveryAmountThreshold != null &&
        freeDeliveryAmountThreshold! > 0 &&
        totalAmount >= freeDeliveryAmountThreshold!) {
      return 0.0;
    }
    return deliveryCharge;
  }
}
