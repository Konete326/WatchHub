import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/support_ticket.dart';
import '../models/faq.dart';
import '../models/canned_response.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // Support Tickets
  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
    String priority = 'MEDIUM',
    String? category,
    List<String> attachments = const [],
  }) async {
    if (uid == null) throw Exception('User not logged in');

    // Calculate SLA Deadline
    final now = DateTime.now();
    Duration slaDuration;
    switch (priority.toUpperCase()) {
      case 'URGENT':
        slaDuration = const Duration(hours: 4);
        break;
      case 'HIGH':
        slaDuration = const Duration(hours: 12);
        break;
      case 'MEDIUM':
        slaDuration = const Duration(hours: 24);
        break;
      case 'LOW':
        slaDuration = const Duration(hours: 48);
        break;
      default:
        slaDuration = const Duration(hours: 24);
    }
    final slaDeadline = now.add(slaDuration);

    final docRef = await _firestore.collection('support_tickets').add({
      'userId': uid,
      'subject': subject,
      'message': message,
      'status': 'OPEN',
      'priority': priority.toUpperCase(),
      'category': category,
      'attachments': attachments,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'slaDeadline': slaDeadline,
      'lastRespondedAt': null,
      'resolvedAt': null,
      'assigneeId': null,
    });

    final doc = await docRef.get();
    return SupportTicket.fromFirestore(doc);
  }

  Future<void> updateTicket({
    required String id,
    String? subject,
    String? message,
    String? priority,
    String? status,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (subject != null) updates['subject'] = subject;
    if (message != null) updates['message'] = message;
    if (priority != null) updates['priority'] = priority;
    if (status != null) updates['status'] = status;

    await _firestore.collection('support_tickets').doc(id).update(updates);
  }

  Future<void> deleteTicket(String id) async {
    await _firestore.collection('support_tickets').doc(id).delete();
  }

  Future<List<SupportTicket>> getUserTickets() async {
    if (uid == null) throw Exception('User not logged in');

    final snapshot = await _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: uid)
        .get();

    final tickets =
        snapshot.docs.map((doc) => SupportTicket.fromFirestore(doc)).toList();
    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tickets;
  }

  Future<SupportTicket> getTicketById(String id) async {
    final doc = await _firestore.collection('support_tickets').doc(id).get();
    if (!doc.exists) throw Exception('Ticket not found');

    final messagesSnapshot = await doc.reference
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .get();

    final data = doc.data() as Map<String, dynamic>;
    final messages = messagesSnapshot.docs
        .map((m) => TicketMessage.fromJson({...m.data(), 'id': m.id}))
        .toList();

    return SupportTicket.fromJson({
      ...data,
      'id': doc.id,
      'messages': messages.map((m) => m.toJson()).toList(),
    });
  }

  Future<void> addMessageToTicket({
    required String ticketId,
    required String message,
    bool isAdmin = false,
    String? senderId,
    String? senderName,
    List<String> attachments = const [],
  }) async {
    if (!isAdmin && uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .add({
      'ticketId': ticketId,
      'message': message,
      'isAdmin': isAdmin,
      'senderId': senderId ?? uid,
      'senderName': senderName,
      'attachments': attachments,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update status and last responded
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isAdmin) {
      updates['status'] = 'PENDING_USER';
      updates['lastRespondedAt'] = FieldValue.serverTimestamp();
    } else {
      updates['status'] = 'IN_PROGRESS';
    }

    await _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .update(updates);
  }

  // Admin Specific Methods
  Future<void> assignTicket(String ticketId, String adminId) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'assigneeId': adminId,
      'status': 'IN_PROGRESS',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resolveTicket(String ticketId, {String? reason}) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'status': 'RESOLVED',
      'closeReason': reason,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> mergeTickets(String sourceId, String targetId) async {
    await _firestore.runTransaction((transaction) async {
      final sourceRef = _firestore.collection('support_tickets').doc(sourceId);
      final targetRef = _firestore.collection('support_tickets').doc(targetId);

      transaction.update(sourceRef, {
        'status': 'CLOSED',
        'closeReason': 'Merged into $targetId',
        'mergedIntoId': targetId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Move messages if needed, or just link them.
      // Simplified: Just add a message to target ticket
      transaction.set(targetRef.collection('messages').doc(), {
        'ticketId': targetId,
        'message': 'SYSTEM: Ticket #$sourceId was merged into this ticket.',
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Map<String, dynamic>> getSupportStats() async {
    final snapshot = await _firestore.collection('support_tickets').get();
    final tickets =
        snapshot.docs.map((doc) => SupportTicket.fromFirestore(doc)).toList();

    int open = 0, inProgress = 0, resolved = 0, expired = 0;
    Map<String, int> priorityBreakdown = {};
    Map<String, int> categoryBreakdown = {};

    for (var t in tickets) {
      if (t.status == 'OPEN')
        open++;
      else if (t.status == 'IN_PROGRESS' || t.status == 'PENDING_USER')
        inProgress++;
      else if (t.status == 'RESOLVED' || t.status == 'CLOSED') resolved++;

      if (t.isExpired) expired++;

      priorityBreakdown[t.priority] = (priorityBreakdown[t.priority] ?? 0) + 1;
      if (t.category != null) {
        categoryBreakdown[t.category!] =
            (categoryBreakdown[t.category!] ?? 0) + 1;
      }
    }

    return {
      'total': tickets.length,
      'open': open,
      'inProgress': inProgress,
      'resolved': resolved,
      'expired': expired,
      'priorityBreakdown': priorityBreakdown,
      'categoryBreakdown': categoryBreakdown,
    };
  }

  // FAQs
  Future<Map<String, dynamic>> getFAQs(
      {String? category, String? search}) async {
    Query query = _firestore.collection('faqs');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    var faqs = snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
    faqs.sort((a, b) => b.order.compareTo(a.order));

    if (search != null && search.isNotEmpty) {
      faqs = faqs
          .where((f) =>
              f.question.toLowerCase().contains(search.toLowerCase()) ||
              f.answer.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    final categories = faqs.map((f) => f.category).toSet().toList();

    return {
      'faqs': faqs,
      'categories': categories,
    };
  }

  // Canned Responses
  Future<List<CannedResponse>> getCannedResponses() async {
    final snapshot = await _firestore.collection('canned_responses').get();
    return snapshot.docs
        .map((doc) => CannedResponse.fromFirestore(doc))
        .toList();
  }

  Future<void> createCannedResponse(
      String title, String content, String category) async {
    await _firestore.collection('canned_responses').add({
      'title': title,
      'content': content,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
