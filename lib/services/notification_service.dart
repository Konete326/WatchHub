import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    int expiryDays = 7,
  }) async {
    final notificationData = {
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(Duration(days: expiryDays)),
      ),
    };

    // 1. Add to user's notifications subcollection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notificationData);

    // 2. Add to global notification queue (for FCM)
    await _firestore.collection('notification_queue').add({
      ...notificationData,
      'targetUser': userId,
      'status': 'pending',
    });
  }

  /// Send order status update notification
  static Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String newStatus,
    String? trackingNumber,
  }) async {
    final statusInfo = _getOrderStatusInfo(newStatus);

    String body =
        statusInfo['message'] ?? 'Your order status has been updated.';
    if (trackingNumber != null && newStatus == 'SHIPPED') {
      body += ' Tracking: $trackingNumber';
    }

    await sendNotification(
      userId: userId,
      title: statusInfo['title'] ?? 'Order Update',
      body: body,
      type: 'order_status',
      data: {
        'orderId': orderId,
        'status': newStatus,
        'trackingNumber': trackingNumber,
      },
      expiryDays: 14,
    );
  }

  /// Send sale/promotion notification to all users or specific user
  static Future<void> sendSaleNotification({
    String? userId,
    required String saleName,
    required String discountPercent,
    String? promoCode,
    DateTime? expiresAt,
  }) async {
    final title = '🎉 $saleName is Live!';
    final body = 'Get up to $discountPercent off on selected watches!'
        '${promoCode != null ? ' Use code: $promoCode' : ''}';

    if (userId != null) {
      // Send to specific user
      await sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: 'sale',
        data: {
          'saleName': saleName,
          'discountPercent': discountPercent,
          'promoCode': promoCode,
        },
        expiryDays: expiresAt != null
            ? expiresAt.difference(DateTime.now()).inDays.clamp(1, 30)
            : 7,
      );
    } else {
      // Broadcast to all users
      await sendBroadcastNotification(
        title: title,
        body: body,
        type: 'sale',
        data: {
          'saleName': saleName,
          'discountPercent': discountPercent,
          'promoCode': promoCode,
        },
        expiryDays: expiresAt != null
            ? expiresAt.difference(DateTime.now()).inDays.clamp(1, 30)
            : 7,
      );
    }
  }

  /// Send price drop notification for wishlist items
  static Future<void> sendPriceDropNotification({
    required String userId,
    required String watchId,
    required String watchName,
    required double oldPrice,
    required double newPrice,
  }) async {
    final discount = ((oldPrice - newPrice) / oldPrice * 100).round();

    await sendNotification(
      userId: userId,
      title: '💰 Price Drop Alert!',
      body:
          '$watchName is now $discount% off! Was \$${oldPrice.toStringAsFixed(0)}, now \$${newPrice.toStringAsFixed(0)}',
      type: 'price_drop',
      data: {
        'watchId': watchId,
        'watchName': watchName,
        'oldPrice': oldPrice,
        'newPrice': newPrice,
      },
      expiryDays: 3,
    );
  }

  /// Send back-in-stock notification
  static Future<void> sendBackInStockNotification({
    required String userId,
    required String watchId,
    required String watchName,
  }) async {
    await sendNotification(
      userId: userId,
      title: '✨ Back in Stock!',
      body:
          'Great news! $watchName is available again. Get it before it sells out!',
      type: 'back_in_stock',
      data: {
        'watchId': watchId,
        'watchName': watchName,
      },
      expiryDays: 3,
    );
  }

  static Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    int expiryDays = 7,
  }) async {
    final notificationData = {
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(Duration(days: expiryDays)),
      ),
    };

    // 1. Add to announcements collection
    await _firestore.collection('announcements').add(notificationData);

    // 2. Add to global notification queue (for FCM)
    await _firestore.collection('notification_queue').add({
      ...notificationData,
      'targetTopic': 'all_users',
      'status': 'pending',
    });
  }

  static Future<void> saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Helper method to get order status info for notifications
  static Map<String, String> _getOrderStatusInfo(String status) {
    switch (status) {
      case 'PENDING':
        return {
          'title': '📦 Order Confirmed',
          'message':
              'Your order has been placed successfully and is being processed.',
        };
      case 'PROCESSING':
        return {
          'title': '⚙️ Order Processing',
          'message': 'We are preparing your order for shipment.',
        };
      case 'SHIPPED':
        return {
          'title': '🚚 Order Shipped',
          'message': 'Your order is on its way! Track your package.',
        };
      case 'OUT_FOR_DELIVERY':
        return {
          'title': '🏃 Out for Delivery',
          'message': 'Your order will be delivered today!',
        };
      case 'DELIVERED':
        return {
          'title': '✅ Order Delivered',
          'message': 'Your order has been delivered. Enjoy your new watch!',
        };
      case 'CANCELLED':
        return {
          'title': '❌ Order Cancelled',
          'message': 'Your order has been cancelled. Refund will be processed.',
        };
      default:
        return {
          'title': '📋 Order Update',
          'message': 'Your order status has been updated.',
        };
    }
  }
}
