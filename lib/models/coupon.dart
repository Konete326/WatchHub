import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final String type; // 'percentage' or 'fixed'
  final double value;
  final double? minAmount;
  final DateTime? expiryDate;
  final bool isActive;

  Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minAmount,
    this.expiryDate,
    this.isActive = true,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'percentage',
      value: json['value'] != null ? double.parse(json['value'].toString()) : 0.0,
      minAmount: json['minAmount'] != null ? double.parse(json['minAmount'].toString()) : null,
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] is Timestamp 
              ? (json['expiryDate'] as Timestamp).toDate() 
              : DateTime.parse(json['expiryDate'] as String))
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      code: data['code'] ?? '',
      type: data['type'] ?? 'percentage',
      value: (data['value'] ?? 0.0).toDouble(),
      minAmount: data['minAmount'] != null ? (data['minAmount'] as num).toDouble() : null,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type,
      'value': value,
      'minAmount': minAmount,
      'expiryDate': expiryDate,
      'isActive': isActive,
    };
  }

  double calculateDiscount(double amount) {
    if (type == 'percentage') {
      return (amount * value) / 100;
    } else {
      return value > amount ? amount : value;
    }
  }
}
