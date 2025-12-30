import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'watch.dart';

class Review {
  final String id;
  final String userId;
  final String watchId;
  final int rating;
  final String comment;
  final List<String> images;
  final int helpfulCount;
  final DateTime createdAt;
  final User? user;
  final Watch? watch;

  Review({
    required this.id,
    required this.userId,
    required this.watchId,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.helpfulCount,
    required this.createdAt,
    this.user,
    this.watch,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      watchId: json['watchId'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : const [],
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      watch: json['watch'] != null ? Watch.fromJson(json['watch'] as Map<String, dynamic>) : null,
    );
  }

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      watchId: data['watchId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : const [],
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'watchId': watchId,
      'rating': rating,
      'comment': comment,
      'images': images,
      'helpfulCount': helpfulCount,
      'createdAt': createdAt,
    };
  }
}

