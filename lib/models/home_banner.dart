import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBanner {
  final String id;
  final String image;
  final String? title;
  final String? subtitle;
  final String? link;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? allowedSegments;
  final List<String>? targetDevices; // ['mobile', 'tablet', 'desktop']
  final String? abTestId;
  final String? version; // 'A', 'B'
  final int clicks;
  final int impressions;

  HomeBanner({
    required this.id,
    required this.image,
    this.title,
    this.subtitle,
    this.link,
    required this.createdAt,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.allowedSegments,
    this.targetDevices = const ['mobile'],
    this.abTestId,
    this.version,
    this.clicks = 0,
    this.impressions = 0,
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
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null
          ? (json['startDate'] is Timestamp
              ? (json['startDate'] as Timestamp).toDate()
              : DateTime.parse(json['startDate']))
          : null,
      endDate: json['endDate'] != null
          ? (json['endDate'] is Timestamp
              ? (json['endDate'] as Timestamp).toDate()
              : DateTime.parse(json['endDate']))
          : null,
      allowedSegments: json['allowedSegments'] != null
          ? List<String>.from(json['allowedSegments'])
          : null,
      targetDevices: json['targetDevices'] != null
          ? List<String>.from(json['targetDevices'])
          : const ['mobile'],
      abTestId: json['abTestId'] as String?,
      version: json['version'] as String?,
      clicks: json['clicks'] as int? ?? 0,
      impressions: json['impressions'] as int? ?? 0,
    );
  }

  factory HomeBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['image'] ?? data['imageUrl'] ?? '';
    return HomeBanner(
      id: doc.id,
      image: imageUrl,
      title: data['title'],
      subtitle: data['subtitle'],
      link: data['link'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      allowedSegments: data['allowedSegments'] != null
          ? List<String>.from(data['allowedSegments'])
          : null,
      targetDevices: data['targetDevices'] != null
          ? List<String>.from(data['targetDevices'])
          : const ['mobile'],
      abTestId: data['abTestId'] as String?,
      version: data['version'] as String?,
      clicks: data['clicks'] ?? 0,
      impressions: data['impressions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'title': title,
      'subtitle': subtitle,
      'link': link,
      'createdAt': createdAt,
      'isActive': isActive,
      'startDate': startDate,
      'endDate': endDate,
      'allowedSegments': allowedSegments,
      'targetDevices': targetDevices,
      'abTestId': abTestId,
      'version': version,
      'clicks': clicks,
      'impressions': impressions,
    };
  }

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0.0;
}
