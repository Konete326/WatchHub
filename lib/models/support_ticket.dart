import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status; // OPEN, IN_PROGRESS, PENDING_USER, RESOLVED, CLOSED
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final String? assigneeId;
  final String? category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime slaDeadline;
  final DateTime? lastRespondedAt;
  final DateTime? resolvedAt;
  final String? closeReason;
  final String? mergedIntoId;
  final List<String> attachments;
  final List<TicketMessage>? messages;
  final User? user;
  final User? assignee;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.slaDeadline,
    this.updatedAt,
    this.assigneeId,
    this.category,
    this.lastRespondedAt,
    this.resolvedAt,
    this.closeReason,
    this.mergedIntoId,
    this.attachments = const [],
    this.messages,
    this.user,
    this.assignee,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      return DateTime.parse(date.toString());
    }

    return SupportTicket(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      priority: json['priority'] as String? ?? 'MEDIUM',
      assigneeId: json['assigneeId'] as String?,
      category: json['category'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
      slaDeadline: parseDate(json['slaDeadline']),
      lastRespondedAt: json['lastRespondedAt'] != null
          ? parseDate(json['lastRespondedAt'])
          : null,
      resolvedAt:
          json['resolvedAt'] != null ? parseDate(json['resolvedAt']) : null,
      closeReason: json['closeReason'] as String?,
      mergedIntoId: json['mergedIntoId'] as String?,
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
              .toList()
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] != null
          ? User.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
    );
  }

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'subject': subject,
      'message': message,
      'status': status,
      'priority': priority,
      'assigneeId': assigneeId,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'slaDeadline': slaDeadline,
      'lastRespondedAt': lastRespondedAt,
      'resolvedAt': resolvedAt,
      'closeReason': closeReason,
      'mergedIntoId': mergedIntoId,
      'attachments': attachments,
    };
  }

  bool get isExpired =>
      DateTime.now().isAfter(slaDeadline) &&
      status != 'RESOLVED' &&
      status != 'CLOSED';

  Duration get timeRemaining => slaDeadline.difference(DateTime.now());

  String get statusDisplay {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String message;
  final bool isAdmin;
  final String? senderId;
  final String? senderName;
  final List<String> attachments;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.attachments = const [],
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      return DateTime.parse(date.toString());
    }

    return TicketMessage(
      id: json['id'] as String? ?? '',
      ticketId: json['ticketId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'message': message,
      'isAdmin': isAdmin,
      'senderId': senderId,
      'senderName': senderName,
      'attachments': attachments,
      'createdAt': createdAt,
    };
  }
}
