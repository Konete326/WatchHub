import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';
import 'order_item.dart';
import 'user.dart';

class Order {
  final String id;
  final String userId;
  final String addressId;
  final double totalAmount;
  final double shippingCost;
  final String? couponId;
  final String status;
  final String? paymentIntentId;
  final String? paymentMethod;
  final DateTime createdAt;
  final Address? address;
  final List<OrderItem>? orderItems;
  final User? user; // User info from admin endpoint

  Order({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.totalAmount,
    this.shippingCost = 0.0,
    this.couponId,
    required this.status,
    this.paymentIntentId,
    this.paymentMethod,
    required this.createdAt,
    this.address,
    this.orderItems,
    this.user,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String? ?? '0',
      userId: json['userId'] as String? ?? '0',
      addressId: json['addressId'] as String? ?? '0',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      shippingCost: (json['shippingCost'] ?? 0.0).toDouble(),
      couponId: json['couponId'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      paymentIntentId: json['paymentIntentId'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      orderItems: json['orderItems'] != null
          ? (json['orderItems'] as List)
              .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
              .toList()
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      addressId: data['addressId'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0.0).toDouble(),
      couponId: data['couponId'],
      status: data['status'] ?? 'PENDING',
      paymentIntentId: data['paymentIntentId'],
      paymentMethod: data['paymentMethod'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'addressId': addressId,
      'totalAmount': totalAmount,
      'shippingCost': shippingCost,
      'couponId': couponId,
      'status': status,
      'paymentIntentId': paymentIntentId,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'SHIPPED':
        return 'Shipped';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

