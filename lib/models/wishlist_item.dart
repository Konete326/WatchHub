import 'package:cloud_firestore/cloud_firestore.dart';
import 'watch.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String watchId;
  final DateTime addedAt;
  final Watch? watch;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.watchId,
    required this.addedAt,
    this.watch,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      watchId: json['watchId'] as String? ?? '',
      addedAt: json['addedAt'] != null
          ? (json['addedAt'] is Timestamp 
              ? (json['addedAt'] as Timestamp).toDate() 
              : DateTime.parse(json['addedAt'] as String))
          : DateTime.now(),
      watch: json['watch'] != null ? Watch.fromJson(json['watch'] as Map<String, dynamic>) : null,
    );
  }

  factory WishlistItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WishlistItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      watchId: data['watchId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'watchId': watchId,
      'addedAt': addedAt,
    };
  }
}

