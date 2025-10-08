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

  /// Warning feedback - time running out
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.mediumImpact();
  }

  /// Combo feedback - increasing intensity with combo level
  static Future<void> combo(int level) async {
    if (level >= 10) {
      // Epic combo
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
    } else if (level >= 5) {
      // Great combo
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
    } else {
      // Standard combo
      await HapticFeedback.lightImpact();
    }
  }

  /// Unlock feedback - badge/achievement unlock
  static Future<void> unlock() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Swipe feedback - card swipe
  static Future<void> swipe() async {
    await HapticFeedback.selectionClick();
  }

  /// Drag start feedback
  static Future<void> dragStart() async {
    await HapticFeedback.mediumImpact();
  }

  /// Drag snap feedback - snapping to target
  static Future<void> dragSnap() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 30));
    await HapticFeedback.mediumImpact();
  }

  /// Power-up activation feedback
  static Future<void> powerUp() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    await HapticFeedback.lightImpact();
  }
}
