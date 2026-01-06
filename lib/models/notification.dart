import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderUpdate,
  promotion,
  discount,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.expiresAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    // Handle timestamp/createdAt
    DateTime timestamp;
    if (map['timestamp'] != null) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['createdAt'] != null) {
      timestamp = (map['createdAt'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _typeFromString(map['type']),
      data: map['data'],
      timestamp: timestamp,
      isRead: map['isRead'] ?? false,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  static NotificationType _typeFromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'orderupdate':
        return NotificationType.orderUpdate;
      case 'promotion':
        return NotificationType.promotion;
      case 'discount':
        return NotificationType.discount;
      default:
        return NotificationType.general;
    }
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
