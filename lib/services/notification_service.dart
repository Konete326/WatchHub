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
}
