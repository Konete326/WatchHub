import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wishlist_item.dart';
import '../models/watch.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<List<WishlistItem>> getWishlist() async {
    if (uid == null) throw Exception('User not logged in');

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .get();

    final wishlistItems = <WishlistItem>[];

    for (var doc in snapshot.docs) {
      final item = WishlistItem.fromFirestore(doc);
      final watchDoc =
          await _firestore.collection('watches').doc(item.watchId).get();
      if (watchDoc.exists) {
        final watch = Watch.fromFirestore(watchDoc);
        wishlistItems.add(WishlistItem(
          id: item.id,
          userId: item.userId,
          watchId: item.watchId,
          addedAt: item.addedAt,
          watch: watch,
        ));
      }
    }
    return wishlistItems;
  }

  Future<WishlistItem> addToWishlist(String watchId) async {
    if (uid == null) throw Exception('User not logged in');

    final existing = await _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .where('watchId', isEqualTo: watchId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return WishlistItem.fromFirestore(existing.docs.first);
    }

    final docRef = await _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .add({
      'userId': uid,
      'watchId': watchId,
      'addedAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return WishlistItem.fromFirestore(doc);
  }

  Future<void> removeFromWishlist(String id) async {
    if (uid == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(id)
        .delete();
  }

  Future<void> moveToCart(String id) async {
    if (uid == null) throw Exception('User not logged in');

    final wishlistDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(id)
        .get();
    if (!wishlistDoc.exists) throw Exception('Wishlist item not found');

    final watchId = wishlistDoc.data()!['watchId'];

    // Check if already in cart
    final cartExisting = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .where('watchId', isEqualTo: watchId)
        .limit(1)
        .get();

    if (cartExisting.docs.isNotEmpty) {
      // Update quantity
      final cartDoc = cartExisting.docs.first;
      await cartDoc.reference.update({
        'quantity': (cartDoc.data()['quantity'] ?? 0) + 1,
      });
    } else {
      // Add new
      await _firestore.collection('users').doc(uid).collection('cart').add({
        'userId': uid,
        'watchId': watchId,
        'quantity': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Remove from wishlist
    await wishlistDoc.reference.delete();
  }
}
