import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final String type; // 'percentage' or 'fixed'
  final double value;
  final double? minAmount;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final bool isActive;
  final bool isStackable;
  final int? usageLimit;
  final int usageCount;
  final int? limitPerUser;
  final List<String>? allowedSegments;
  final String? abTestId;
  final String? version; // 'A' or 'B'
  final Map<String, int> stats; // { 'conversions': 10, 'failed_attempts': 2 }

  Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minAmount,
    this.startDate,
    this.expiryDate,
    this.isActive = true,
    this.isStackable = false,
    this.usageLimit,
    this.usageCount = 0,
    this.limitPerUser,
    this.allowedSegments,
    this.abTestId,
    this.version,
    this.stats = const {},
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'percentage',
      value:
          json['value'] != null ? double.parse(json['value'].toString()) : 0.0,
      minAmount: json['minAmount'] != null
          ? double.parse(json['minAmount'].toString())
          : null,
      startDate: json['startDate'] != null
          ? (json['startDate'] is Timestamp
              ? (json['startDate'] as Timestamp).toDate()
              : DateTime.parse(json['startDate'] as String))
          : null,
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] is Timestamp
              ? (json['expiryDate'] as Timestamp).toDate()
              : DateTime.parse(json['expiryDate'] as String))
          : null,
      isActive: json['isActive'] as bool? ?? true,
      isStackable: json['isStackable'] as bool? ?? false,
      usageLimit: json['usageLimit'] as int?,
      usageCount: json['usageCount'] as int? ?? 0,
      limitPerUser: json['limitPerUser'] as int?,
      allowedSegments: json['allowedSegments'] != null
          ? List<String>.from(json['allowedSegments'])
          : null,
      abTestId: json['abTestId'] as String?,
      version: json['version'] as String?,
      stats: json['stats'] != null ? Map<String, int>.from(json['stats']) : {},
    );
  }

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      code: data['code'] ?? '',
      type: data['type'] ?? 'percentage',
      value: (data['value'] ?? 0.0).toDouble(),
      minAmount: data['minAmount'] != null
          ? (data['minAmount'] as num).toDouble()
          : null,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      isStackable: data['isStackable'] ?? false,
      usageLimit: data['usageLimit'] as int?,
      usageCount: data['usageCount'] ?? 0,
      limitPerUser: data['limitPerUser'] as int?,
      allowedSegments: data['allowedSegments'] != null
          ? List<String>.from(data['allowedSegments'])
          : null,
      abTestId: data['abTestId'] as String?,
      version: data['version'] as String?,
      stats: data['stats'] != null ? Map<String, int>.from(data['stats']) : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type,
      'value': value,
      'minAmount': minAmount,
      'startDate': startDate,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'isStackable': isStackable,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'limitPerUser': limitPerUser,
      'allowedSegments': allowedSegments,
      'abTestId': abTestId,
      'version': version,
      'stats': stats,
    };
  }

  bool isValid(double amount, {String? userSegment}) {
    final now = DateTime.now();
    if (!isActive) return false;
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (expiryDate != null && now.isAfter(expiryDate!)) return false;
    if (minAmount != null && amount < minAmount!) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    if (allowedSegments != null &&
        userSegment != null &&
        !allowedSegments!.contains(userSegment.toUpperCase())) return false;
    return true;
  }

  double calculateDiscount(double amount) {
    if (type == 'percentage') {
      return (amount * value) / 100;
    } else {
      return value > amount ? amount : value;
    }
  }
}
