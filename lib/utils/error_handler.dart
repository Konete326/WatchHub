import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class FirebaseErrorHandler {
  static String getMessage(dynamic e) {
    String errorStr = e.toString();

    // 1. Check for Connectivity/Network specific errors first
    // Checks both the type and the string representation for wrapped exceptions
    if (e is SocketException ||
        errorStr.contains('SocketException') ||
        errorStr.contains('Network is unreachable') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Connection reset by peer') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('ClientException') ||
        errorStr.contains('XMLHttpRequest error')) {
      return 'Internet Connection Error: Unable to connect to the server. Please check your internet connection.';
    }

    if (e is TimeoutException ||
        errorStr.contains('TimeoutException') ||
        errorStr.contains('deadline-exceeded')) {
      return 'Connection Timeout: The server took too long to respond. Please try again later.';
    }

    if (e is HttpException || errorStr.contains('HttpException')) {
      return 'Server Error: We are having trouble connecting to the server. Please try again.';
    }

    // 2. Firebase Auth Exceptions
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password provided.';
        case 'email-already-in-use':
          return 'The email address is already in use by another account.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'operation-not-allowed':
          return 'Operation not allowed.';
        case 'network-request-failed':
          return 'Internet Connection Error: Unable to connect to authentication server. Check your internet.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        default:
          return e.message ?? 'An unknown authentication error occurred.';
      }
    }

    // 3. Firebase General Exceptions
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Access Denied: You do not have permission to perform this action.';
        case 'unavailable':
          return 'Service Unavailable: The server is currently unreachable. Please check your internet.';
        case 'not-found':
          return 'Not Found: The requested data was not found.';
        case 'already-exists':
          return 'Data Conflict: The document already exists.';
        case 'deadline-exceeded':
          return 'Request Timeout: The operation took too long. Please try again.';
        case 'network-error':
          return 'Internet Connection Error: Please check your connection.';
        default:
          return e.message ?? 'A database error occurred.';
      }
    }

    // 4. Platform Exceptions
    if (e is PlatformException) {
      if (e.code == 'network_error') {
        return 'Internet Connection Error: Please check your connection.';
      }
      return e.message ?? 'A platform error occurred.';
    }

    // 5. Generic Exceptions cleaning
    if (e is Exception || e is Error) {
      // Clean up common prefixes
      if (errorStr.contains('Exception:')) {
        errorStr = errorStr.split('Exception:').last.trim();
      }
      if (errorStr.contains('Error:')) {
        errorStr = errorStr.split('Error:').last.trim();
      }
      return errorStr;
    }

    // 6. Direct String
    if (e is String) {
      return e;
    }

    // Fallback
    return 'An unexpected error occurred. Please try again.';
  }
}
