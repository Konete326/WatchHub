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
  StreamSubscription<QuerySnapshot>? _announcementSubscription;
  List<String> _dismissedAnnouncementIds = [];
  List<String> _readAnnouncementIds = [];

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get uid => _auth.currentUser?.uid;

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load dismissed announcements
    if (uid != null) {
      try {
        final dismissedSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('dismissed_announcements')
            .get();
        _dismissedAnnouncementIds =
            dismissedSnapshot.docs.map((d) => d.id).toList();

        final readSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('read_announcements')
            .get();
        _readAnnouncementIds = readSnapshot.docs.map((d) => d.id).toList();
      } catch (e) {
        print('Error loading user notification preferences: $e');
      }
    }
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription?.cancel();
    _announcementSubscription?.cancel();

    if (uid == null) {
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    // 1. User Notifications
    final userStream = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();

    // 2. Broadcast Announcements
    final announcementStream = _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();

    List<NotificationModel> userNotifications = [];
    List<NotificationModel> announcements = [];

    _notificationSubscription = userStream.listen((snapshot) {
      userNotifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      _mergeAndNotify(userNotifications, announcements);
    }, onError: (e) => print('User notifications error: $e'));

    _announcementSubscription = announcementStream.listen((snapshot) {
      announcements = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      _mergeAndNotify(userNotifications, announcements);
    }, onError: (e) => print('Announcements error: $e'));
  }

  void _mergeAndNotify(
      List<NotificationModel> userList, List<NotificationModel> allList) {
    // Filter expired announcements
    final now = DateTime.now();
    final validAnnouncements = allList.where((n) {
      if (n.expiresAt != null && n.expiresAt!.isBefore(now)) return false;
      if (_dismissedAnnouncementIds.contains(n.id)) return false;
      return true;
    }).map((n) {
      if (_readAnnouncementIds.contains(n.id)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    // Merge
    final merged = [...userList, ...validAnnouncements];

    // Sort desc
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _notifications = merged;
    _calculateUnreadCount();
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    if (uid == null) return;
    _listenToNotifications();
  }

  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    if (uid == null) return;

    // Check if it's user notification or announcement
    // For announcement, we can't update 'isRead' on the document itself as it's shared.
    // We should track 'read_announcements' in user subcollection or local storage.
    // For simplicity: broadcasts are considered "read" if clicked, but we don't persist it perfectly in this simple version
    // UNLESS we merge them into user notifications when read.
    // Let's try to find it in user collection.

    // Simplification: We only support marking USER notifications as read in DB.
    // For broadcasts, we update local state.

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    final notification = _notifications[index];
    if (notification.isRead) return; // Already read

    // Optimistic update
    _notifications[index] = notification.copyWith(isRead: true);
    _calculateUnreadCount();
    notifyListeners();

    try {
      // 1. Check if it's a private user notification
      final userNotifRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId);

      final userNotifDoc = await userNotifRef.get();
      if (userNotifDoc.exists) {
        await userNotifRef.update({'isRead': true});
      } else {
        // 2. It's an announcement (Broadcast)
        // Mark as read for this user specifically
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('read_announcements')
            .doc(notificationId)
            .set({'readAt': FieldValue.serverTimestamp()});
        _readAnnouncementIds.add(notificationId);
      }

      // 3. Update Global Seen Count in History
      final historySnapshot = await _firestore
          .collection('admin_notification_history')
          .where('notificationId', isEqualTo: notificationId)
          .limit(1)
          .get();

      if (historySnapshot.docs.isNotEmpty) {
        await historySnapshot.docs.first.reference
            .update({'seenCount': FieldValue.increment(1)});
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (uid == null) return;

    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      // Only update actual user notifications
      final userNotifs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in userNotifs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (uid == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        // Assume announcement -> Dismiss
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('dismissed_announcements')
            .doc(notificationId)
            .set({'dismissedAt': FieldValue.serverTimestamp()});
        _dismissedAnnouncementIds.add(notificationId);
      }

      _notifications.removeWhere((n) => n.id == notificationId);
      _calculateUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Method to add notification manually
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
  }
}
