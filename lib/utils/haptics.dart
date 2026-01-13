import 'package:flutter/services.dart';

class HapticHelper {
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> success() async {
    // Some platforms don't support success haptics directly via this call,
    // so we simulate it or use appropriate platform calls if available.
    // For Flutter, light + light can sometimes simulate success vibes.
    await HapticFeedback.vibrate();
  }

  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
