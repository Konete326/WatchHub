import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class FirebaseErrorHandler {
  static String getMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The email address is already in use by another account.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'operation-not-allowed':
          return 'Operation not allowed.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return e.message ?? 'An unknown authentication error occurred.';
      }
    } else if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'The service is currently unavailable. Please check your internet.';
        case 'not-found':
          return 'The requested document was not found.';
        case 'already-exists':
          return 'The document already exists.';
        case 'deadline-exceeded':
          return 'The operation timed out. Please try again.';
        case 'network-error':
          return 'Network error occurred. Please check your connection.';
        default:
          return e.message ?? 'A database error occurred.';
      }
    } else if (e is SocketException) {
      return 'No internet connection. Please check your network settings.';
    } else if (e is Exception) {
      final errorStr = e.toString();
      // Try to extract a meaningful message
      if (errorStr.contains('Exception:')) {
        return errorStr.split('Exception:').last.trim();
      }
      if (errorStr.contains('Error:')) {
        return errorStr.split('Error:').last.trim();
      }
      return errorStr.replaceAll('Exception: ', '').replaceAll('Error: ', '');
    } else if (e is String) {
      return e;
    }

    // For any other type, try to convert to string
    try {
      final errorStr = e.toString();
      if (errorStr.isNotEmpty && errorStr != 'null') {
        return errorStr;
      }
    } catch (_) {
      // If conversion fails, use default
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
