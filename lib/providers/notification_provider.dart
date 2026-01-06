import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  String? get uid => _auth.currentUser?.uid;

  NotificationProvider() {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription?.cancel();

    if (uid == null) {
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    _notificationSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      _calculateUnreadCount();
      notifyListeners();
    }, onError: (e) {
      print('Error listening to notifications: $e');
    });
  }

  // Fallback for manual refresh
  Future<void> fetchNotifications() async {
    if (uid == null) return;
    _listenToNotifications(); // Re-trigger listener if needed
  }

  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _calculateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (uid == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead);

      for (var n in unreadNotifications) {
        final docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(n.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();

      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      _calculateUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Method to add notification manually (useful for testing or app-triggered ones)
  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    if (uid == null) return;

    final n = NotificationModel(
      id: '',
      title: title,
      body: body,
      type: type,
      data: data,
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add(n.toMap());

    await fetchNotifications();
  }
}
