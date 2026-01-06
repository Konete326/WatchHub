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

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _typeFromString(map['type']),
      data: map['data'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
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
