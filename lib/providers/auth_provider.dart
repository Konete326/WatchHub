import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/error_handler.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isPrivileged => _user?.isPrivileged ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isEmployee => _user?.isEmployee ?? false;

  Future<void> _updateFcmToken() async {
    if (!kIsWeb) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await NotificationService.saveTokenToFirestore(token);
      }
    }
  }

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn && _authService.currentUser != null) {
        _user = await _authService.getUserData(_authService.currentUser!.uid);
        if (_user != null) {
          await _updateFcmToken();
          return true;
        }
      }
      _user = null;
      return false;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (_user != null) {
        await _updateFcmToken();
      }

      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(
        email: email,
        password: password,
      );

      if (_user != null) {
        await _updateFcmToken();
      }

      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();
      if (_user != null) {
        await _updateFcmToken();
      }
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
