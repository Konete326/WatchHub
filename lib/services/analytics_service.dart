import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AnalyticsEvent {
  viewProduct,
  addToCart,
  removeFromCart,
  beginCheckout,
  addPaymentInfo,
  purchase,
  viewPromotion,
  search,
  filterApplied,
  errorOccurred,
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logEvent(AnalyticsEvent event,
      {Map<String, dynamic>? parameters}) async {
    final user = _auth.currentUser;
    final eventData = {
      'eventName': event.toString().split('.').last,
      'userId': user?.uid ?? 'anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'parameters': parameters ?? {},
      'platform': 'web/mobile', // In a real app, use DeviceInfoPlugin
    };

    // 1. Log to console for debugging
    developer.log(
        'Analytics Event: ${eventData['eventName']} | Params: ${eventData['parameters']}');

    // 2. Log to Firestore (for custom internal analytics dashboard)
    try {
      await _firestore.collection('analytics_events').add(eventData);
    } catch (e) {
      developer.log('Failed to log event to Firestore: $e');
    }

    // 3. Integration point for Firebase Analytics / Amplitude / Mixpanel
    // FirebaseAnalytics.instance.logEvent(name: eventData['eventName'], parameters: parameters);
  }

  // Funnel tracking helper
  Future<void> logCheckoutStep(int step, String stepName,
      {Map<String, dynamic>? extras}) async {
    await logEvent(AnalyticsEvent.beginCheckout, parameters: {
      'step': step,
      'stepName': stepName,
      ...?extras,
    });
  }

  Future<void> logPurchase(
      String orderId, double total, List<String> productIds) async {
    await logEvent(AnalyticsEvent.purchase, parameters: {
      'orderId': orderId,
      'value': total,
      'currency': 'USD',
      'items': productIds,
    });
  }
}
