import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/user.dart';
import '../models/address.dart';
import 'cloudinary_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<User> getProfile() async {
    if (uid == null) throw Exception('User not logged in');
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return User.fromFirestore(doc);
  }

  Future<User> updateProfile({String? name, String? phone}) async {
    if (uid == null) throw Exception('User not logged in');
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;

    await _firestore.collection('users').doc(uid).update(updates);
    final doc = await _firestore.collection('users').doc(uid).get();
    return User.fromFirestore(doc);
  }

  Future<User> updateProfileImage(XFile file) async {
    if (uid == null) throw Exception('User not logged in');

    final imageUrl = await CloudinaryService.uploadImage(
      file,
      folder: 'users',
      publicId: 'users/$uid/profile',
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .update({'profileImage': imageUrl});
    final doc = await _firestore.collection('users').doc(uid).get();
    return User.fromFirestore(doc);
  }

  Future<List<Address>> getAddresses() async {
    if (uid == null) throw Exception('User not logged in');
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .get();
    return snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();
  }

  Future<Address> createAddress(Address address) async {
    if (uid == null) throw Exception('User not logged in');

    final docRef = await _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .add({
      'userId': uid,
      ...address.toJson(),
    });

    if (address.isDefault) {
      // Set others to non-default
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .get();
      for (var doc in snapshot.docs) {
        if (doc.id != docRef.id) {
          await doc.reference.update({'isDefault': false});
        }
      }
    }

    final doc = await docRef.get();
    return Address.fromFirestore(doc);
  }

  Future<Address> updateAddress(String id, Address address) async {
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(id)
        .update(address.toJson());

    if (address.isDefault) {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .get();
      for (var doc in snapshot.docs) {
        if (doc.id != id) {
          await doc.reference.update({'isDefault': false});
        }
      }
    }

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(id)
        .get();
    return Address.fromFirestore(doc);
  }

  Future<void> deleteAddress(String id) async {
    if (uid == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(id)
        .delete();
  }
}
