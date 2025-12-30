import 'package:cloud_firestore/cloud_firestore.dart';

class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;
  final DateTime createdAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
    required this.createdAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      category: json['category'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
    );
  }

  factory FAQ.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FAQ(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      category: data['category'] ?? '',
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

