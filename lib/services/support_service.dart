import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/support_ticket.dart';
import '../models/faq.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // Support Tickets
  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
  }) async {
    if (uid == null) throw Exception('User not logged in');

    final docRef = await _firestore.collection('support_tickets').add({
      'userId': uid,
      'subject': subject,
      'message': message,
      'status': 'OPEN',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return SupportTicket.fromFirestore(doc);
  }

  Future<void> updateTicket({
    required String id,
    required String subject,
    required String message,
  }) async {
    await _firestore.collection('support_tickets').doc(id).update({
      'subject': subject,
      'message': message,
    });
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

    final messagesSnapshot = await doc.reference.collection('messages').get();

    final ticket = SupportTicket.fromFirestore(doc);
    final messages = messagesSnapshot.docs
        .map((m) => TicketMessage.fromFirestore(m))
        .toList();
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SupportTicket(
      id: ticket.id,
      userId: ticket.userId,
      subject: ticket.subject,
      message: ticket.message,
      status: ticket.status,
      createdAt: ticket.createdAt,
      messages: messages,
    );
  }

  Future<void> addMessageToTicket(String ticketId, String message) async {
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .add({
      'ticketId': ticketId,
      'message': message,
      'isAdmin': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
}
