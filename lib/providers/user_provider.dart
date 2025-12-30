import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/address.dart';
import '../utils/error_handler.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  User? _user;
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Address? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (addr) => addr.isDefault,
      orElse: () => _addresses.first,
    );
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _userService.getProfile();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? name, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _userService.updateProfile(name: name, phone: phone);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileImage(String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _userService.updateProfileImage(filePath);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await _userService.getAddresses();
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAddress(Address address) async {
    try {
      final newAddress = await _userService.createAddress(address);
      _addresses.add(newAddress);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(String id, Address address) async {
    try {
      final updatedAddress = await _userService.updateAddress(id, address);
      final index = _addresses.indexWhere((addr) => addr.id == id);
      if (index != -1) {
        _addresses[index] = updatedAddress;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      await _userService.deleteAddress(id);
      _addresses.removeWhere((addr) => addr.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
