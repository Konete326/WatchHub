import 'package:cloud_firestore/cloud_firestore.dart';

class Brand {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final DateTime createdAt;

  Brand({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.createdAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
    );
  }

  factory Brand.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Brand(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      logoUrl: data['logoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'createdAt': createdAt,
    };
  }
}

