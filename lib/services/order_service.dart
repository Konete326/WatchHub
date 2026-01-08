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

  Future<Coupon?> validateCoupon(String code) async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Coupon.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Coupon>> getAvailableCoupons() async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Coupon.fromFirestore(doc)).toList();
    } catch (e) {
      // Log the error or handle it appropriately
      print('Error fetching available coupons: $e');
      return []; // Return an empty list on error
    }
  }

  Future<Order> createOrder({
    required String addressId,
    String? paymentIntentId,
    double? shippingCost,
    List<String>? cartItemIds,
    String paymentMethod = 'card',
    String? couponId,
    Map<String, Map<String, String?>>?
        strapSelections, // cartItemId -> {strapType, strapColor}
  }) async {
    if (uid == null) throw Exception('User not logged in');

    return await _firestore.runTransaction((transaction) async {
      // 1. Get Cart Items
      final cartQuery =
          _firestore.collection('users').doc(uid).collection('cart');
      final cartSnapshot = await cartQuery.get();

      if (cartSnapshot.docs.isEmpty) throw Exception('Cart is empty');

      double totalAmount = 0;
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

        totalAmount += price * quantity;

        // Get strap selections for this cart item
        final strapSelection = strapSelections?[doc.id];

        orderItemsData.add({
          'watchId': data['watchId'],
          'quantity': quantity,
          'priceAtPurchase': price,
          'productColor': data['productColor'],
          'strapType': strapSelection?['strapType'] ?? data['strapType'],
          'strapColor': strapSelection?['strapColor'] ?? data['strapColor'],
        });

        watchesToUpdate[watchRef] = stock - quantity;
      }

      if (orderItemsData.isEmpty) throw Exception('No selected items to order');

      // 2. Add shipping cost
      if (shippingCost != null) totalAmount += shippingCost;

      // 3. Apply coupon if any (re-validate in transaction)
      if (couponId != null) {
        final couponRef = _firestore.collection('coupons').doc(couponId);
        final couponDoc = await transaction.get(couponRef);
        if (couponDoc.exists) {
          final couponData = couponDoc.data()!;
          final discount = couponData['discountAmount'] ?? 0.0;
          totalAmount -= discount;
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

      // 6. Update Stocks
      watchesToUpdate.forEach((ref, newStock) {
        transaction.update(ref, {'stock': newStock});
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
