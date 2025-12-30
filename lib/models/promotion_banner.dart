import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionBanner {
  final String id;
  final String type; // 'image' or 'text'
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final String? backgroundColor;
  final String? textColor;
  final String? link;
  final bool isActive;

  PromotionBanner({
    required this.id,
    required this.type,
    this.imageUrl,
    this.title,
    this.subtitle,
    this.backgroundColor,
    this.textColor,
    this.link,
    this.isActive = true,
  });

  factory PromotionBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotionBanner(
      id: doc.id,
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      title: data['title'],
      subtitle: data['subtitle'],
      backgroundColor: data['backgroundColor'],
      textColor: data['textColor'],
      link: data['link'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'link': link,
      'isActive': isActive,
    };
  }
}
