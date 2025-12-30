import 'package:cloud_firestore/cloud_firestore.dart';
import 'watch.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String watchId;
  final int quantity;
  final double priceAtPurchase;
  final Watch? watch;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.watchId,
    required this.quantity,
    required this.priceAtPurchase,
    this.watch,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      watchId: json['watchId'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      priceAtPurchase: double.parse(json['priceAtPurchase'].toString()),
      watch: json['watch'] != null ? Watch.fromJson(json['watch'] as Map<String, dynamic>) : null,
    );
  }

  factory OrderItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderItem(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      watchId: data['watchId'] ?? '',
      quantity: data['quantity'] ?? 1,
      priceAtPurchase: (data['priceAtPurchase'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'watchId': watchId,
      'quantity': quantity,
      'priceAtPurchase': priceAtPurchase,
    };
  }

  double get subtotal => priceAtPurchase * quantity;
}

