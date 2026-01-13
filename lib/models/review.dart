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

  // New Moderation & UGC Fields
  final String status; // 'pending', 'approved', 'rejected', 'flagged'
  final bool isFeatured;
  final String? adminReply;
  final DateTime? adminReplyAt;
  final String? flagReason;
  final double? sentimentScore; // -1.0 to 1.0
  final List<String>? tags; // ['verified', 'photo', 'helpful']

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
    this.status = 'approved',
    this.isFeatured = false,
    this.adminReply,
    this.adminReplyAt,
    this.flagReason,
    this.sentimentScore,
    this.tags,
  });

  bool get hasMedia => images.isNotEmpty;
  String get sentimentLabel {
    if (sentimentScore == null) return 'Neutral';
    if (sentimentScore! > 0.2) return 'Positive';
    if (sentimentScore! < -0.2) return 'Negative';
    return 'Neutral';
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      watchId: json['watchId'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      images:
          json['images'] != null ? List<String>.from(json['images']) : const [],
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      status: json['status'] as String? ?? 'approved',
      isFeatured: json['isFeatured'] as bool? ?? false,
      adminReply: json['adminReply'] as String?,
      adminReplyAt: json['adminReplyAt'] != null
          ? (json['adminReplyAt'] is Timestamp
              ? (json['adminReplyAt'] as Timestamp).toDate()
              : DateTime.parse(json['adminReplyAt'] as String))
          : null,
      flagReason: json['flagReason'] as String?,
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      watch: json['watch'] != null
          ? Watch.fromJson(json['watch'] as Map<String, dynamic>)
          : null,
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
      images:
          data['images'] != null ? List<String>.from(data['images']) : const [],
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'approved',
      isFeatured: data['isFeatured'] ?? false,
      adminReply: data['adminReply'],
      adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
      flagReason: data['flagReason'],
      sentimentScore: (data['sentimentScore'] as num?)?.toDouble(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
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
      'status': status,
      'isFeatured': isFeatured,
      'adminReply': adminReply,
      'adminReplyAt': adminReplyAt,
      'flagReason': flagReason,
      'sentimentScore': sentimentScore,
      'tags': tags,
    };
  }
}
