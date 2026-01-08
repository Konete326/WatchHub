import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/watch.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> getCart() async {
    if (uid == null) throw Exception('User not logged in');

    final snapshot =
        await _firestore.collection('users').doc(uid).collection('cart').get();

    final cartItems = <CartItem>[];
    double subtotal = 0;

    for (var doc in snapshot.docs) {
      final item = CartItem.fromFirestore(doc);
      // Fetch watch details for each cart item
      final watchDoc =
          await _firestore.collection('watches').doc(item.watchId).get();
      if (watchDoc.exists) {
        final watch = Watch.fromFirestore(watchDoc);
        final fullItem = CartItem(
          id: item.id,
          userId: item.userId,
          watchId: item.watchId,
          quantity: item.quantity,
          createdAt: item.createdAt,
          watch: watch,
          productColor: item.productColor,
          strapType: item.strapType,
          strapColor: item.strapColor,
        );
        cartItems.add(fullItem);
        subtotal += fullItem.subtotal;
      }
    }

    return {
      'cartItems': cartItems,
      'subtotal': subtotal,
      'itemCount': cartItems.length,
    };
  }

  Future<CartItem> addToCart(String watchId,
      {int quantity = 1, String? productColor}) async {
    if (uid == null) throw Exception('User not logged in');

    // Check if item既に exists in cart with SAME watchId and SAME productColor
    Query query = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .where('watchId', isEqualTo: watchId);

    if (productColor != null) {
      query = query.where('productColor', isEqualTo: productColor);
    } else {
      // If no color selected, we look for items where productColor is null
      // Note: Firestore where null might be tricky depending on how it's stored
      query = query.where('productColor', isNull: true);
    }

    final existing = await query.limit(1).get();

    if (existing.docs.isNotEmpty) {
      final docId = existing.docs.first.id;
      final existingData = existing.docs.first.data() as Map<String, dynamic>;
      final newQuantity = (existingData['quantity'] as int? ?? 0) + quantity;
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(docId)
          .update({
        'quantity': newQuantity,
      });
      final updatedDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(docId)
          .get();
      return CartItem.fromFirestore(updatedDoc);
    } else {
      final docRef =
          await _firestore.collection('users').doc(uid).collection('cart').add({
        'userId': uid,
        'watchId': watchId,
        'quantity': quantity,
        'productColor': productColor,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final newDoc = await docRef.get();
      return CartItem.fromFirestore(newDoc);
    }
  }

  Future<CartItem> updateCartItem(String id, int quantity) async {
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(id)
        .update({
      'quantity': quantity,
    });
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(id)
        .get();
    return CartItem.fromFirestore(doc);
  }

  Future<void> removeFromCart(String id) async {
    if (uid == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(id)
        .delete();
  }

  Future<void> clearCart() async {
    if (uid == null) throw Exception('User not logged in');
    final snapshot =
        await _firestore.collection('users').doc(uid).collection('cart').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
