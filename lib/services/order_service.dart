import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watchhub/models/watch.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/address.dart';
import '../models/coupon.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> createPaymentIntent(double amount) async {
    if (Constants.useFakePayment) {
      // Return fake data for testing
      await Future.delayed(const Duration(seconds: 1));
      return {
        'clientSecret':
            'pi_fake_secret_${DateTime.now().millisecondsSinceEpoch}',
        'paymentIntentId': 'pi_fake_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    try {
      // For real Stripe integration, we use Firebase Cloud Functions for security
      // This keeps the Stripe Secret Key hidden on the server side

      // Note: Make sure to replace this URL with your actual deployed Firebase function URL
      // Or use the cloud_functions package
      final url = Uri.parse(
          'https://us-central1-watchhub-f4ec6.cloudfunctions.net/createPaymentIntent');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _auth.currentUser?.getIdToken()}',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Amount in cents
          'currency': 'usd',
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'clientSecret': body['clientSecret'],
          'paymentIntentId': body['paymentIntentId'],
        };
      } else {
        throw Exception(body['error'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<Coupon?> validateCoupon(String code,
      {double? amount, String? userSegment}) async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final coupon = Coupon.fromFirestore(snapshot.docs.first);
        if (coupon.isValid(amount ?? 0, userSegment: userSegment)) {
          return coupon;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Coupon>> getAvailableCoupons({String? userSegment}) async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Coupon.fromFirestore(doc))
          .where((c) => c.isValid(0, userSegment: userSegment))
          .toList();
    } catch (e) {
      print('Error fetching available coupons: $e');
      return [];
    }
  }

  Future<Order> createOrder({
    required String addressId,
    String? paymentIntentId,
    double? shippingCost,
    List<String>? cartItemIds,
    String paymentMethod = 'card',
    String? couponId,
    Map<String, Map<String, String?>>? strapSelections,
  }) async {
    if (uid == null) throw Exception('User not logged in');

    return await _firestore.runTransaction((transaction) async {
      // 0. Get User Segment for Coupon Validation
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await transaction.get(userRef);
      final userSegment = userDoc.data()?['rfmSummary'];

      // 1. Get Cart Items
      final cartQuery =
          _firestore.collection('users').doc(uid).collection('cart');
      final cartSnapshot = await cartQuery.get();

      if (cartSnapshot.docs.isEmpty) throw Exception('Cart is empty');

      double subtotal = 0;
      final orderItemsData = <Map<String, dynamic>>[];
      final watchesToUpdate = <DocumentReference, int>{};

      for (var doc in cartSnapshot.docs) {
        if (cartItemIds != null && !cartItemIds.contains(doc.id)) continue;

        final data = doc.data();
        final watchRef = _firestore.collection('watches').doc(data['watchId']);
        final watchDoc = await transaction.get(watchRef);

        if (!watchDoc.exists) throw Exception('Watch not found');

        final watchData = watchDoc.data()!;
        final price = (watchData['salePrice'] ?? watchData['price']).toDouble();
        final quantity = data['quantity'];
        final stock = watchData['stock'] ?? 0;

        if (stock < quantity)
          throw Exception('Not enough stock for ${watchData['name']}');

        subtotal += price * quantity;

        orderItemsData.add({
          'watchId': data['watchId'],
          'quantity': quantity,
          'priceAtPurchase': price,
          'productColor': data['productColor'],
          'strapType':
              strapSelections?[doc.id]?['strapType'] ?? data['strapType'],
          'strapColor':
              strapSelections?[doc.id]?['strapColor'] ?? data['strapColor'],
        });

        watchesToUpdate[watchRef] = stock - quantity;
      }

      if (orderItemsData.isEmpty) throw Exception('No selected items to order');

      // 2. Apply coupon if any (re-validate in transaction)
      double totalAmount = subtotal + (shippingCost ?? 0.0);
      if (couponId != null) {
        final couponRef = _firestore.collection('coupons').doc(couponId);
        final couponDoc = await transaction.get(couponRef);
        if (couponDoc.exists) {
          final coupon = Coupon.fromFirestore(couponDoc);
          if (coupon.isValid(subtotal, userSegment: userSegment)) {
            final discount = coupon.calculateDiscount(subtotal);
            totalAmount -= discount;

            // Increment usage count and stats
            transaction.update(couponRef, {
              'usageCount': FieldValue.increment(1),
              'stats.conversions': FieldValue.increment(1),
            });
          } else {
            // Record failed attempt
            transaction.update(couponRef, {
              'stats.failed_attempts': FieldValue.increment(1),
            });
            throw Exception('Coupon no longer valid');
          }
        }
      }

      // 4. Create Order
      final orderRef = _firestore.collection('orders').doc();
      final orderData = {
        'userId': uid,
        'addressId': addressId,
        'totalAmount': totalAmount,
        'shippingCost': shippingCost ?? 0.0,
        'couponId': couponId,
        'status': 'PENDING',
        'paymentIntentId': paymentIntentId,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.set(orderRef, orderData);

      // 5. Create Order Items
      for (var item in orderItemsData) {
        final itemRef = orderRef.collection('orderItems').doc();
        transaction.set(itemRef, item);
      }

      // 6. Update Stocks and Popularity
      watchesToUpdate.forEach((ref, newStock) {
        transaction.update(ref, {
          'stock': newStock,
          'popularity': FieldValue.increment(1),
          'salesCount': FieldValue.increment(1),
        });
      });

      // 7. Clear ordered items from cart
      for (var doc in cartSnapshot.docs) {
        if (cartItemIds != null && !cartItemIds.contains(doc.id)) continue;
        transaction.delete(doc.reference);
      }

      // 8. Send Notification
      NotificationService.sendNotification(
        userId: uid!,
        title: 'Order Placed! 🎊',
        body:
            'Your order #${orderRef.id} has been placed successfully. Thank you for shopping with us!',
        type: 'order_placed',
        data: {'orderId': orderRef.id},
      );

      return Order(
        id: orderRef.id,
        userId: uid!,
        addressId: addressId,
        totalAmount: totalAmount,
        shippingCost: shippingCost ?? 0.0,
        couponId: couponId,
        status: 'PENDING',
        paymentIntentId: paymentIntentId,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );
    });
  }

  Future<Map<String, dynamic>> getUserOrders(
      {int page = 1, int limit = 10}) async {
    if (uid == null) throw Exception('User not logged in');

    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .get();

    final allOrders =
        snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

    // Sort client-side: most recent first
    allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Manual slicing for migration speed
    final startIndex = (page - 1) * limit;
    final paginatedOrders = allOrders.length > startIndex
        ? allOrders.sublist(
            startIndex, (startIndex + limit).clamp(0, allOrders.length))
        : <Order>[];

    return {
      'orders': paginatedOrders,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': allOrders.length,
        'totalPages': (allOrders.length / limit).ceil()
      },
    };
  }

  Future<Order> getOrderById(String id) async {
    final doc = await _firestore.collection('orders').doc(id).get();
    if (!doc.exists) throw Exception('Order not found');

    final order = Order.fromFirestore(doc);

    // Fetch address
    final addressDoc =
        await _firestore.collection('addresses').doc(order.addressId).get();
    Address? address;
    if (addressDoc.exists) {
      address = Address.fromFirestore(addressDoc);
    }

    // Fetch order items
    final itemsSnapshot = await doc.reference.collection('orderItems').get();
    final items = <OrderItem>[];
    for (var itemDoc in itemsSnapshot.docs) {
      final item = OrderItem.fromFirestore(itemDoc);
      // Fetch watch details for each item
      final watchDoc =
          await _firestore.collection('watches').doc(item.watchId).get();
      if (watchDoc.exists) {
        final watch = Watch.fromFirestore(watchDoc);
        items.add(OrderItem(
          id: item.id,
          orderId: item.orderId,
          watchId: item.watchId,
          quantity: item.quantity,
          priceAtPurchase: item.priceAtPurchase,
          watch: watch,
        ));
      } else {
        items.add(item);
      }
    }

    return Order(
      id: order.id,
      userId: order.userId,
      addressId: order.addressId,
      totalAmount: order.totalAmount,
      shippingCost: order.shippingCost,
      couponId: order.couponId,
      status: order.status,
      paymentIntentId: order.paymentIntentId,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      address: address,
      orderItems: items,
    );
  }
}
