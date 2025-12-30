import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1076372472812-mitb040uh9ftm7i4l4shpdju22v34bgb.apps.googleusercontent.com',
  );

  Future<User?> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final user = User(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
        role: 'USER', // All registrations default to 'USER' for security
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());
      return user;
    }
    return null;
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      return await getUserData(credential.user!.uid);
    }
    return null;
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final fb.UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!doc.exists) {
        // Create new user in Firestore if they don't exist
        final newUser = User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? 'User',
          role: 'USER',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toJson());
        return newUser;
      }
      return User.fromFirestore(doc);
    }
    return null;
  }

  Future<User?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  fb.User? get currentUser => _auth.currentUser;

  Future<void> forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
