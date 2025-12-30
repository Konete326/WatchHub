import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;
  final List<TicketMessage>? messages;
  final User? user;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.messages,
    this.user,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      messages: json['messages'] != null
          ? (json['messages'] as List).map((m) => TicketMessage.fromJson(m as Map<String, dynamic>)).toList()
          : null,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'OPEN',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': createdAt,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'OPEN':
        return 'Open';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String message;
  final bool isAdmin;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String? ?? '',
      ticketId: json['ticketId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
    );
  }

  factory TicketMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TicketMessage(
      id: doc.id,
      ticketId: data['ticketId'] ?? '',
      message: data['message'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'message': message,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
    };
  }
}

