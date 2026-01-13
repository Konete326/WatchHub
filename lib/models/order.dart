import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';
import 'order_item.dart';
import 'user.dart';

/// Represents a single event in the order timeline
class OrderTimelineEvent {
  final String
      event; // e.g., 'PAYMENT_RECEIVED', 'PICKED', 'PACKED', 'SHIPPED', 'OUT_FOR_DELIVERY', 'DELIVERED'
  final DateTime timestamp;
  final String? note;
  final String? actor; // Admin user or system

  OrderTimelineEvent({
    required this.event,
    required this.timestamp,
    this.note,
    this.actor,
  });

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      event: json['event'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']),
      note: json['note'],
      actor: json['actor'],
    );
  }

  Map<String, dynamic> toJson() => {
        'event': event,
        'timestamp': timestamp,
        'note': note,
        'actor': actor,
      };
}

/// Refund details for an order
class RefundInfo {
  final double amount;
  final String reason;
  final String type; // 'FULL', 'PARTIAL'
  final DateTime createdAt;
  final String? stripeRefundId;
  final String status; // 'PENDING', 'PROCESSED', 'FAILED'

  RefundInfo({
    required this.amount,
    required this.reason,
    required this.type,
    required this.createdAt,
    this.stripeRefundId,
    this.status = 'PENDING',
  });

  factory RefundInfo.fromJson(Map<String, dynamic> json) {
    return RefundInfo(
      amount: (json['amount'] ?? 0.0).toDouble(),
      reason: json['reason'] ?? '',
      type: json['type'] ?? 'FULL',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      stripeRefundId: json['stripeRefundId'],
      status: json['status'] ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'reason': reason,
        'type': type,
        'createdAt': createdAt,
        'stripeRefundId': stripeRefundId,
        'status': status,
      };
}

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
  final User? user;

  // New fields for enhanced order management
  final List<OrderTimelineEvent> timeline;
  final List<String> tags; // e.g., 'VIP', 'PRIORITY', 'FRAGILE', 'GIFT'
  final List<String> internalNotes;
  final RefundInfo? refund;
  final String? exchangeOrderId; // If this order was created as an exchange
  final String? trackingNumber;
  final String? courierName; // e.g., 'FedEx', 'UPS', 'DHL'
  final String? courierTrackingUrl;
  final double fraudScore; // 0.0 to 1.0 (higher = more suspicious)
  final List<String>
      fraudSignals; // e.g., 'NEW_ACCOUNT', 'HIGH_VALUE', 'MISMATCH_ADDRESS'
  final bool isOnHold;
  final String? holdReason;

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
    this.timeline = const [],
    this.tags = const [],
    this.internalNotes = const [],
    this.refund,
    this.exchangeOrderId,
    this.trackingNumber,
    this.courierName,
    this.courierTrackingUrl,
    this.fraudScore = 0.0,
    this.fraudSignals = const [],
    this.isOnHold = false,
    this.holdReason,
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
      timeline: json['timeline'] != null
          ? (json['timeline'] as List)
              .map((e) => OrderTimelineEvent.fromJson(e))
              .toList()
          : [],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      internalNotes: json['internalNotes'] != null
          ? List<String>.from(json['internalNotes'])
          : [],
      refund:
          json['refund'] != null ? RefundInfo.fromJson(json['refund']) : null,
      exchangeOrderId: json['exchangeOrderId'],
      trackingNumber: json['trackingNumber'],
      courierName: json['courierName'],
      courierTrackingUrl: json['courierTrackingUrl'],
      fraudScore: (json['fraudScore'] ?? 0.0).toDouble(),
      fraudSignals: json['fraudSignals'] != null
          ? List<String>.from(json['fraudSignals'])
          : [],
      isOnHold: json['isOnHold'] ?? false,
      holdReason: json['holdReason'],
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
      timeline: data['timeline'] != null
          ? (data['timeline'] as List)
              .map((e) => OrderTimelineEvent.fromJson(e))
              .toList()
          : [],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      internalNotes: data['internalNotes'] != null
          ? List<String>.from(data['internalNotes'])
          : [],
      refund:
          data['refund'] != null ? RefundInfo.fromJson(data['refund']) : null,
      exchangeOrderId: data['exchangeOrderId'],
      trackingNumber: data['trackingNumber'],
      courierName: data['courierName'],
      courierTrackingUrl: data['courierTrackingUrl'],
      fraudScore: (data['fraudScore'] ?? 0.0).toDouble(),
      fraudSignals: data['fraudSignals'] != null
          ? List<String>.from(data['fraudSignals'])
          : [],
      isOnHold: data['isOnHold'] ?? false,
      holdReason: data['holdReason'],
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
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'tags': tags,
      'internalNotes': internalNotes,
      'refund': refund?.toJson(),
      'exchangeOrderId': exchangeOrderId,
      'trackingNumber': trackingNumber,
      'courierName': courierName,
      'courierTrackingUrl': courierTrackingUrl,
      'fraudScore': fraudScore,
      'fraudSignals': fraudSignals,
      'isOnHold': isOnHold,
      'holdReason': holdReason,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Ordered';
      case 'PROCESSING':
        return 'Processing';
      case 'SHIPPED':
        return 'Shipped';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'ON_HOLD':
        return 'On Hold';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }

  bool get hasRefund => refund != null;
  bool get isHighRisk => fraudScore >= 0.7;
  bool get isMediumRisk => fraudScore >= 0.4 && fraudScore < 0.7;

  Order copyWith({
    String? id,
    String? userId,
    String? addressId,
    double? totalAmount,
    double? shippingCost,
    String? couponId,
    String? status,
    String? paymentIntentId,
    String? paymentMethod,
    DateTime? createdAt,
    Address? address,
    List<OrderItem>? orderItems,
    User? user,
    List<OrderTimelineEvent>? timeline,
    List<String>? tags,
    List<String>? internalNotes,
    RefundInfo? refund,
    String? exchangeOrderId,
    String? trackingNumber,
    String? courierName,
    String? courierTrackingUrl,
    double? fraudScore,
    List<String>? fraudSignals,
    bool? isOnHold,
    String? holdReason,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressId: addressId ?? this.addressId,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      couponId: couponId ?? this.couponId,
      status: status ?? this.status,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      orderItems: orderItems ?? this.orderItems,
      user: user ?? this.user,
      timeline: timeline ?? this.timeline,
      tags: tags ?? this.tags,
      internalNotes: internalNotes ?? this.internalNotes,
      refund: refund ?? this.refund,
      exchangeOrderId: exchangeOrderId ?? this.exchangeOrderId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      courierName: courierName ?? this.courierName,
      courierTrackingUrl: courierTrackingUrl ?? this.courierTrackingUrl,
      fraudScore: fraudScore ?? this.fraudScore,
      fraudSignals: fraudSignals ?? this.fraudSignals,
      isOnHold: isOnHold ?? this.isOnHold,
      holdReason: holdReason ?? this.holdReason,
    );
  }
}
