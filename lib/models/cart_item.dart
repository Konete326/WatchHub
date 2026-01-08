import 'package:cloud_firestore/cloud_firestore.dart';
import 'watch.dart';

class CartItem {
  final String id;
  final String userId;
  final String watchId;
  final int quantity;
  final DateTime createdAt;
  final Watch? watch;
  final String? strapType; // 'belt' or 'chain' (selected by user)
  final String? strapColor; // Color in hex format (selected by user)
  final String? productColor; // Main color of the watch (name)

  CartItem({
    required this.id,
    required this.userId,
    required this.watchId,
    required this.quantity,
    required this.createdAt,
    this.watch,
    this.strapType,
    this.strapColor,
    this.productColor,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      watchId: json['watchId'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      watch: json['watch'] != null
          ? Watch.fromJson(json['watch'] as Map<String, dynamic>)
          : null,
      strapType: json['strapType'] as String?,
      strapColor: json['strapColor'] as String?,
      productColor: json['productColor'] as String?,
    );
  }

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      watchId: data['watchId'] ?? '',
      quantity: data['quantity'] ?? 1,
      strapType: data['strapType'] as String?,
      strapColor: data['strapColor'] as String?,
      productColor: data['productColor'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'watchId': watchId,
      'quantity': quantity,
      'strapType': strapType,
      'strapColor': strapColor,
      'productColor': productColor,
      'createdAt': createdAt,
    };
  }

  double get subtotal {
    if (watch == null) return 0;
    return watch!.currentPrice * quantity;
  }
}
