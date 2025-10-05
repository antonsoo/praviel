import 'package:flutter/services.dart';

/// Provides haptic feedback for user interactions to enhance UX
class HapticService {
  const HapticService._();

  /// Light impact - for subtle interactions (tap, hover)
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for standard interactions (button press)
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important interactions (submission, completion)
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection changed - for picker/slider interactions
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Success feedback - correct answer
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error feedback - wrong answer
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Celebration feedback - level up, streak milestone
  static Future<void> celebrate() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
}
