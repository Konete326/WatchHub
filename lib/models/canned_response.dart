import 'package:cloud_firestore/cloud_firestore.dart';

class CannedResponse {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;

  CannedResponse({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
  });

  factory CannedResponse.fromJson(Map<String, dynamic> json) {
    return CannedResponse(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
    );
  }

  factory CannedResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CannedResponse.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'createdAt': createdAt,
    };
  }
}
