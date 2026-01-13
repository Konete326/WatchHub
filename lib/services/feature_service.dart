import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureFlag {
  final String id;
  final String description;
  final bool isEnabled;
  final double rolloutPercentage; // 0.0 to 1.0
  final Map<String, dynamic> variations;

  FeatureFlag({
    required this.id,
    required this.description,
    required this.isEnabled,
    this.rolloutPercentage = 1.0,
    this.variations = const {},
  });

  factory FeatureFlag.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeatureFlag(
      id: doc.id,
      description: data['description'] ?? '',
      isEnabled: data['isEnabled'] ?? false,
      rolloutPercentage: (data['rolloutPercentage'] ?? 1.0).toDouble(),
      variations: data['variations'] ?? {},
    );
  }
}

class FeatureFlagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FeatureFlag>> getFlags() async {
    final snapshot = await _firestore.collection('feature_flags').get();
    return snapshot.docs.map((doc) => FeatureFlag.fromFirestore(doc)).toList();
  }

  // Check if a feature is enabled for a specific user (deterministic based on UID hash)
  bool isFeatureEnabled(FeatureFlag flag, String userId) {
    if (!flag.isEnabled) return false;
    if (flag.rolloutPercentage >= 1.0) return true;

    // Simple deterministic hash for rollout
    final hash = userId.hashCode.abs() % 100;
    return hash < (flag.rolloutPercentage * 100);
  }

  Future<void> updateFlag(String id, bool enabled, {double? rollout}) async {
    await _firestore.collection('feature_flags').doc(id).update({
      'isEnabled': enabled,
      if (rollout != null) 'rolloutPercentage': rollout,
    });
  }

  // Default flags for cold start
  static Map<String, bool> get defaults => {
        'new_checkout_ui': false,
        'personalized_recommendations': true,
        'flash_sale_banner_v2': false,
        'apple_pay_integration': false,
      };
}
