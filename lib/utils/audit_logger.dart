import '../models/audit_log.dart';
import '../services/audit_service.dart';

/// Helper class to easily log audit events throughout the application
class AuditLogger {
  static final AuditService _auditService = AuditService();

  // Product audit logs
  static Future<void> logProductCreated(
    String productId,
    String productName,
    Map<String, dynamic> productData,
  ) async {
    await _auditService.logAction(
      action: AuditAction.productCreated,
      actionDescription: 'Created product: $productName',
      targetId: productId,
      targetType: 'product',
      newValues: productData,
    );
  }

  static Future<void> logProductUpdated(
    String productId,
    String productName,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) async {
    await _auditService.logAction(
      action: AuditAction.productUpdated,
      actionDescription: 'Updated product: $productName',
      targetId: productId,
      targetType: 'product',
      oldValues: oldData,
      newValues: newData,
    );
  }

  static Future<void> logProductPriceChanged(
    String productId,
    String productName,
    double oldPrice,
    double newPrice,
  ) async {
    await _auditService.logAction(
      action: AuditAction.productPriceChanged,
      actionDescription:
          'Changed price for $productName from \$$oldPrice to \$$newPrice',
      targetId: productId,
      targetType: 'product',
      oldValues: {'price': oldPrice},
      newValues: {'price': newPrice},
    );
  }

  static Future<void> logProductStockChanged(
    String productId,
    String productName,
    int oldStock,
    int newStock,
  ) async {
    await _auditService.logAction(
      action: AuditAction.productStockChanged,
      actionDescription:
          'Changed stock for $productName from $oldStock to $newStock',
      targetId: productId,
      targetType: 'product',
      oldValues: {'stock': oldStock},
      newValues: {'stock': newStock},
    );
  }

  static Future<void> logProductDeleted(
    String productId,
    String productName,
  ) async {
    await _auditService.logAction(
      action: AuditAction.productDeleted,
      actionDescription: 'Deleted product: $productName',
      targetId: productId,
      targetType: 'product',
    );
  }

  // Order audit logs
  static Future<void> logOrderStatusChanged(
    String orderId,
    String oldStatus,
    String newStatus,
  ) async {
    await _auditService.logAction(
      action: AuditAction.orderStatusChanged,
      actionDescription:
          'Changed order #$orderId status from $oldStatus to $newStatus',
      targetId: orderId,
      targetType: 'order',
      oldValues: {'status': oldStatus},
      newValues: {'status': newStatus},
    );
  }

  static Future<void> logOrderCancelled(
    String orderId,
    String reason,
  ) async {
    await _auditService.logAction(
      action: AuditAction.orderCancelled,
      actionDescription: 'Cancelled order #$orderId',
      targetId: orderId,
      targetType: 'order',
      metadata: {'reason': reason},
    );
  }

  // User audit logs
  static Future<void> logUserCreated(
    String userId,
    String userEmail,
  ) async {
    await _auditService.logAction(
      action: AuditAction.userCreated,
      actionDescription: 'Created user: $userEmail',
      targetId: userId,
      targetType: 'user',
    );
  }

  static Future<void> logUserRoleChanged(
    String userId,
    String userEmail,
    String oldRole,
    String newRole,
  ) async {
    await _auditService.logAction(
      action: AuditAction.userRoleChanged,
      actionDescription:
          'Changed role for $userEmail from $oldRole to $newRole',
      targetId: userId,
      targetType: 'user',
      oldValues: {'role': oldRole},
      newValues: {'role': newRole},
    );
  }

  static Future<void> logUserDeleted(
    String userId,
    String userEmail,
  ) async {
    await _auditService.logAction(
      action: AuditAction.userDeleted,
      actionDescription: 'Deleted user: $userEmail',
      targetId: userId,
      targetType: 'user',
    );
  }

  // Category audit logs
  static Future<void> logCategoryCreated(
    String categoryId,
    String categoryName,
  ) async {
    await _auditService.logAction(
      action: AuditAction.categoryCreated,
      actionDescription: 'Created category: $categoryName',
      targetId: categoryId,
      targetType: 'category',
    );
  }

  static Future<void> logCategoryUpdated(
    String categoryId,
    String categoryName,
  ) async {
    await _auditService.logAction(
      action: AuditAction.categoryUpdated,
      actionDescription: 'Updated category: $categoryName',
      targetId: categoryId,
      targetType: 'category',
    );
  }

  static Future<void> logCategoryDeleted(
    String categoryId,
    String categoryName,
  ) async {
    await _auditService.logAction(
      action: AuditAction.categoryDeleted,
      actionDescription: 'Deleted category: $categoryName',
      targetId: categoryId,
      targetType: 'category',
    );
  }

  // Brand audit logs
  static Future<void> logBrandCreated(
    String brandId,
    String brandName,
  ) async {
    await _auditService.logAction(
      action: AuditAction.brandCreated,
      actionDescription: 'Created brand: $brandName',
      targetId: brandId,
      targetType: 'brand',
    );
  }

  static Future<void> logBrandUpdated(
    String brandId,
    String brandName,
  ) async {
    await _auditService.logAction(
      action: AuditAction.brandUpdated,
      actionDescription: 'Updated brand: $brandName',
      targetId: brandId,
      targetType: 'brand',
    );
  }

  static Future<void> logBrandDeleted(
    String brandId,
    String brandName,
  ) async {
    await _auditService.logAction(
      action: AuditAction.brandDeleted,
      actionDescription: 'Deleted brand: $brandName',
      targetId: brandId,
      targetType: 'brand',
    );
  }

  // Coupon audit logs
  static Future<void> logCouponCreated(
    String couponId,
    String couponCode,
  ) async {
    await _auditService.logAction(
      action: AuditAction.couponCreated,
      actionDescription: 'Created coupon: $couponCode',
      targetId: couponId,
      targetType: 'coupon',
    );
  }

  static Future<void> logCouponUpdated(
    String couponId,
    String couponCode,
  ) async {
    await _auditService.logAction(
      action: AuditAction.couponUpdated,
      actionDescription: 'Updated coupon: $couponCode',
      targetId: couponId,
      targetType: 'coupon',
    );
  }

  static Future<void> logCouponDeleted(
    String couponId,
    String couponCode,
  ) async {
    await _auditService.logAction(
      action: AuditAction.couponDeleted,
      actionDescription: 'Deleted coupon: $couponCode',
      targetId: couponId,
      targetType: 'coupon',
    );
  }

  // Banner audit logs
  static Future<void> logBannerCreated(String bannerId) async {
    await _auditService.logAction(
      action: AuditAction.bannerCreated,
      actionDescription: 'Created banner',
      targetId: bannerId,
      targetType: 'banner',
    );
  }

  static Future<void> logBannerUpdated(String bannerId) async {
    await _auditService.logAction(
      action: AuditAction.bannerUpdated,
      actionDescription: 'Updated banner',
      targetId: bannerId,
      targetType: 'banner',
    );
  }

  static Future<void> logBannerDeleted(String bannerId) async {
    await _auditService.logAction(
      action: AuditAction.bannerDeleted,
      actionDescription: 'Deleted banner',
      targetId: bannerId,
      targetType: 'banner',
    );
  }

  // Promotion audit logs
  static Future<void> logPromotionCreated(
    String promotionId,
    String promotionTitle,
  ) async {
    await _auditService.logAction(
      action: AuditAction.promotionCreated,
      actionDescription: 'Created promotion: $promotionTitle',
      targetId: promotionId,
      targetType: 'promotion',
    );
  }

  static Future<void> logPromotionUpdated(
    String promotionId,
    String promotionTitle,
  ) async {
    await _auditService.logAction(
      action: AuditAction.promotionUpdated,
      actionDescription: 'Updated promotion: $promotionTitle',
      targetId: promotionId,
      targetType: 'promotion',
    );
  }

  static Future<void> logPromotionDeleted(
    String promotionId,
    String promotionTitle,
  ) async {
    await _auditService.logAction(
      action: AuditAction.promotionDeleted,
      actionDescription: 'Deleted promotion: $promotionTitle',
      targetId: promotionId,
      targetType: 'promotion',
    );
  }

  // Settings audit logs
  static Future<void> logSettingsUpdated(
    Map<String, dynamic> oldSettings,
    Map<String, dynamic> newSettings,
  ) async {
    await _auditService.logAction(
      action: AuditAction.settingsUpdated,
      actionDescription: 'Updated application settings',
      targetType: 'settings',
      oldValues: oldSettings,
      newValues: newSettings,
    );
  }

  static Future<void> logShippingSettingsUpdated(
    Map<String, dynamic> oldSettings,
    Map<String, dynamic> newSettings,
  ) async {
    await _auditService.logAction(
      action: AuditAction.shippingSettingsUpdated,
      actionDescription: 'Updated shipping settings',
      targetType: 'shipping_settings',
      oldValues: oldSettings,
      newValues: newSettings,
    );
  }

  // Notification audit logs
  static Future<void> logNotificationSent(
    String notificationType,
    int recipientCount,
  ) async {
    await _auditService.logAction(
      action: AuditAction.notificationSent,
      actionDescription:
          'Sent $notificationType notification to $recipientCount users',
      targetType: 'notification',
      metadata: {
        'type': notificationType,
        'recipientCount': recipientCount,
      },
    );
  }

  // Generic audit log
  static Future<void> logCustomAction(
    String actionDescription, {
    String? targetId,
    String? targetType,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    Map<String, dynamic>? metadata,
  }) async {
    await _auditService.logAction(
      action: AuditAction.other,
      actionDescription: actionDescription,
      targetId: targetId,
      targetType: targetType,
      oldValues: oldValues,
      newValues: newValues,
      metadata: metadata,
    );
  }
}
