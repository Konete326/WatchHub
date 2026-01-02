import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBanner {
  final String id;
  final String image;
  final String? title;
  final String? subtitle;
  final String? link;
  final DateTime createdAt;

  HomeBanner({
    required this.id,
    required this.image,
    this.title,
    this.subtitle,
    this.link,
    required this.createdAt,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'] as String? ?? '',
      image: json['image'] as String? ?? '',
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      link: json['link'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
    );
  }

  factory HomeBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Check both 'image' and 'imageUrl' for backward compatibility
    final imageUrl = data['image'] ?? data['imageUrl'] ?? '';
    return HomeBanner(
      id: doc.id,
      image: imageUrl,
      title: data['title'],
      subtitle: data['subtitle'],
      link: data['link'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'title': title,
      'subtitle': subtitle,
      'link': link,
      'createdAt': createdAt,
    };
  }
}
