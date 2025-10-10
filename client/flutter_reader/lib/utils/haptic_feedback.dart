import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized haptic feedback utilities
/// Provides consistent tactile feedback across the app
class AppHaptics {
  /// Light haptic feedback for button taps
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently fail on platforms that don't support haptics
    }
  }

  /// Medium haptic feedback for selections
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail
    }
  }

  /// Heavy haptic feedback for important actions
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail
    }
  }

  /// Selection haptic (for pickers, sliders)
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail
    }
  }

  /// Success haptic pattern (for achievements, level ups)
  static Future<void> success() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [0, 50, 50, 100],
          intensities: [0, 128, 0, 255],
        );
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Error haptic pattern (for mistakes, failures)
  static Future<void> error() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [0, 100, 100, 100],
          intensities: [0, 200, 0, 200],
        );
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Celebration haptic pattern (for completing challenges)
  static Future<void> celebration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [0, 50, 50, 50, 50, 100],
          intensities: [0, 128, 0, 128, 0, 255],
        );
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Warning haptic (for destructive actions)
  static Future<void> warning() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [0, 100, 50, 100],
          intensities: [0, 200, 0, 200],
        );
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Double tap confirmation
  static Future<void> doubleTap() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently fail
    }
  }

  /// Streak milestone haptic (for maintaining streaks)
  static Future<void> streakMilestone(int days) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Longer celebration for longer streaks
        final pattern = days >= 30
            ? [0, 50, 50, 50, 50, 100, 50, 150]
            : days >= 7
                ? [0, 50, 50, 100, 50, 150]
                : [0, 50, 50, 100];

        await Vibration.vibrate(
          pattern: pattern,
          intensities: List.generate(
            pattern.length,
            (i) => i == 0 ? 0 : (i.isEven ? 0 : 200),
          ),
        );
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Combo achieved haptic (for correct answer streaks)
  static Future<void> combo(int comboCount) async {
    try {
      if (comboCount % 5 == 0 && comboCount > 0) {
        // Special haptic for milestone combos (5, 10, 15, etc.)
        await celebration();
      } else {
        await light();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Level up haptic
  static Future<void> levelUp() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [0, 100, 100, 100, 100, 200],
          intensities: [0, 150, 0, 200, 0, 255],
        );
      } else {
        await heavy();
        await Future.delayed(const Duration(milliseconds: 100));
        await heavy();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Cancel all haptics
  static Future<void> cancel() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.cancel();
      }
    } catch (e) {
      // Silently fail
    }
  }
}
