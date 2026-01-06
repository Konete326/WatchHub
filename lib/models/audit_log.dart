import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction {
  // Product Actions
  productCreated,
  productUpdated,
  productDeleted,
  productPriceChanged,
  productStockChanged,

  // Order Actions
  orderStatusChanged,
  orderCreated,
  orderCancelled,

  // User Actions
  userCreated,
  userUpdated,
  userDeleted,
  userRoleChanged,

  // Category Actions
  categoryCreated,
  categoryUpdated,
  categoryDeleted,

  // Brand Actions
  brandCreated,
  brandUpdated,
  brandDeleted,

  // Coupon Actions
  couponCreated,
  couponUpdated,
  couponDeleted,

  // Banner Actions
  bannerCreated,
  bannerUpdated,
  bannerDeleted,

  // Promotion Actions
  promotionCreated,
  promotionUpdated,
  promotionDeleted,

  // Settings Actions
  settingsUpdated,
  shippingSettingsUpdated,

  // Notification Actions
  notificationSent,

  // Other Actions
  other,
}

class AuditLog {
  final String id;
  final String adminId;
  final String adminEmail;
  final String adminName;
  final AuditAction action;
  final String actionDescription;
  final String? targetId; // ID of the affected resource (product, order, etc.)
  final String? targetType; // Type of resource (product, order, user, etc.)
  final Map<String, dynamic>? oldValues; // Previous values before change
  final Map<String, dynamic>? newValues; // New values after change
  final DateTime timestamp;
  final String? ipAddress;
  final Map<String, dynamic>? metadata; // Additional context

  AuditLog({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.adminName,
    required this.action,
    required this.actionDescription,
    this.targetId,
    this.targetType,
    this.oldValues,
    this.newValues,
    required this.timestamp,
    this.ipAddress,
    this.metadata,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      adminName: data['adminName'] ?? '',
      action: _parseAction(data['action']),
      actionDescription: data['actionDescription'] ?? '',
      targetId: data['targetId'],
      targetType: data['targetType'],
      oldValues: data['oldValues'] != null
          ? Map<String, dynamic>.from(data['oldValues'])
          : null,
      newValues: data['newValues'] != null
          ? Map<String, dynamic>.from(data['newValues'])
          : null,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminEmail': adminEmail,
      'adminName': adminName,
      'action': action.toString().split('.').last,
      'actionDescription': actionDescription,
      'targetId': targetId,
      'targetType': targetType,
      'oldValues': oldValues,
      'newValues': newValues,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'metadata': metadata,
    };
  }

  static AuditAction _parseAction(String? actionStr) {
    if (actionStr == null) return AuditAction.other;
    try {
      return AuditAction.values.firstWhere(
        (e) => e.toString().split('.').last == actionStr,
        orElse: () => AuditAction.other,
      );
    } catch (e) {
      return AuditAction.other;
    }
  }

  // Helper method to get a human-readable action name
  String get actionName {
    switch (action) {
      case AuditAction.productCreated:
        return 'Product Created';
      case AuditAction.productUpdated:
        return 'Product Updated';
      case AuditAction.productDeleted:
        return 'Product Deleted';
      case AuditAction.productPriceChanged:
        return 'Product Price Changed';
      case AuditAction.productStockChanged:
        return 'Product Stock Changed';
      case AuditAction.orderStatusChanged:
        return 'Order Status Changed';
      case AuditAction.orderCreated:
        return 'Order Created';
      case AuditAction.orderCancelled:
        return 'Order Cancelled';
      case AuditAction.userCreated:
        return 'User Created';
      case AuditAction.userUpdated:
        return 'User Updated';
      case AuditAction.userDeleted:
        return 'User Deleted';
      case AuditAction.userRoleChanged:
        return 'User Role Changed';
      case AuditAction.categoryCreated:
        return 'Category Created';
      case AuditAction.categoryUpdated:
        return 'Category Updated';
      case AuditAction.categoryDeleted:
        return 'Category Deleted';
      case AuditAction.brandCreated:
        return 'Brand Created';
      case AuditAction.brandUpdated:
        return 'Brand Updated';
      case AuditAction.brandDeleted:
        return 'Brand Deleted';
      case AuditAction.couponCreated:
        return 'Coupon Created';
      case AuditAction.couponUpdated:
        return 'Coupon Updated';
      case AuditAction.couponDeleted:
        return 'Coupon Deleted';
      case AuditAction.bannerCreated:
        return 'Banner Created';
      case AuditAction.bannerUpdated:
        return 'Banner Updated';
      case AuditAction.bannerDeleted:
        return 'Banner Deleted';
      case AuditAction.promotionCreated:
        return 'Promotion Created';
      case AuditAction.promotionUpdated:
        return 'Promotion Updated';
      case AuditAction.promotionDeleted:
        return 'Promotion Deleted';
      case AuditAction.settingsUpdated:
        return 'Settings Updated';
      case AuditAction.shippingSettingsUpdated:
        return 'Shipping Settings Updated';
      case AuditAction.notificationSent:
        return 'Notification Sent';
      case AuditAction.other:
        return 'Other Action';
    }
  }
}
