import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettings {
  final double deliveryCharge;
  final int freeDeliveryThreshold; // Number of items for free delivery
  final double? freeDeliveryAmountThreshold; // Optional amount threshold
  final String currencyCode; // e.g., 'USD', 'PKR', 'EUR'
  final double currencyExchangeRate; // Rate relative to a base (default 1.0)

  AppSettings({
    required this.deliveryCharge,
    required this.freeDeliveryThreshold,
    this.freeDeliveryAmountThreshold,
    this.currencyCode = 'USD',
    this.currencyExchangeRate = 1.0,
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
    );
  }

  factory AppSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppSettings(
      deliveryCharge: (data['deliveryCharge'] ?? 0.0).toDouble(),
      freeDeliveryThreshold: data['freeDeliveryThreshold'] ?? 0,
      freeDeliveryAmountThreshold: data['freeDeliveryAmountThreshold'] != null
          ? (data['freeDeliveryAmountThreshold'] as num).toDouble()
          : null,
      currencyCode: data['currencyCode'] as String? ?? 'USD',
      currencyExchangeRate: (data['currencyExchangeRate'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryCharge': deliveryCharge,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'freeDeliveryAmountThreshold': freeDeliveryAmountThreshold,
      'currencyCode': currencyCode,
      'currencyExchangeRate': currencyExchangeRate,
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
