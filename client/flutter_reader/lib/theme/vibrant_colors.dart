import 'package:flutter/material.dart';

/// Vibrant color system inspired by modern language learning apps
/// These colors are designed to be energetic, motivating, and fun
class VibrantColors {
  VibrantColors._();

  // Primary Brand Colors - Energetic and inviting
  static const primary = Color(0xFF1CB0F6); // Bright turquoise
  static const primaryDark = Color(0xFF0099DD);
  static const primaryLight = Color(0xFF4EC5FF);

  // Secondary - Warm and friendly
  static const secondary = Color(0xFFFF9600); // Warm orange
  static const secondaryDark = Color(0xFFE88000);
  static const secondaryLight = Color(0xFFFFAD33);

  // Success - Positive feedback
  static const success = Color(0xFF58CC02); // Vibrant green
  static const successDark = Color(0xFF46A302);
  static const successLight = Color(0xFF89E219);

  // Error - Gentle but clear
  static const error = Color(0xFFFF4B4B); // Soft red
  static const errorDark = Color(0xFFE03131);
  static const errorLight = Color(0xFFFF6B6B);

  // Warning - Attention grabbing
  static const warning = Color(0xFFFFC800); // Bright yellow
  static const warningDark = Color(0xFFE6B400);
  static const warningLight = Color(0xFFFFD42E);

  // XP & Leveling
  static const xpGold = Color(0xFFFFC800);
  static const xpSilver = Color(0xFFCDCDCD);
  static const xpBronze = Color(0xFFCD7F32);

  // Streak Colors
  static const streakFlame = Color(0xFFFF9600);
  static const streakFire = Color(0xFFFF4B4B);
  static const streakHot = Color(0xFFFFC800);

  // Gamification
  static const combo = Color(0xFFCE82FF); // Purple for combo multipliers
  static const powerUp = Color(0xFF00E5FF); // Cyan for power-ups
  static const achievement = Color(0xFFFFC800); // Gold for achievements
  static const badge = Color(0xFF1CB0F6); // Turquoise for badges

  // Background gradients
  static const gradientStart = Color(0xFF667EEA); // Purple
  static const gradientEnd = Color(0xFF764BA2); // Deep purple
  static const gradientAccent = Color(0xFFF57C00); // Orange accent

  // Surface colors
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF1C1C1E);
  static const surfaceElevated = Color(0xFF2C2C2E);

  // Text colors
  static const textPrimary = Color(0xFF3C3C3C);
  static const textSecondary = Color(0xFF777777);
  static const textHint = Color(0xFFAFAFAF);
  static const textOnDark = Colors.white;

  // Accent colors for variety
  static const accentPink = Color(0xFFFF6EC7);
  static const accentTeal = Color(0xFF00D9D9);
  static const accentMint = Color(0xFF7DFFB5);
  static const accentLavender = Color(0xFFB395FF);

  // Exercise type colors
  static const alphabetColor = Color(0xFF6C5DD3); // Purple
  static const matchColor = Color(0xFFFF6B9D); // Pink
  static const clozeColor = Color(0xFF00CBA9); // Teal
  static const translateColor = Color(0xFFFFD93D); // Yellow

  // Level colors
  static const level1 = Color(0xFF6C5DD3);
  static const level2 = Color(0xFF1CB0F6);
  static const level3 = Color(0xFF58CC02);
  static const level4 = Color(0xFFFFC800);
  static const level5 = Color(0xFFFF9600);

  static Color getLevelColor(int level) {
    final colors = [level1, level2, level3, level4, level5];
    return colors[(level - 1) % colors.length];
  }

  // Glass morphism
  static Color glassLight = Colors.white.withValues(alpha: 0.2);
  static Color glassDark = Colors.black.withValues(alpha: 0.2);
  static Color glassBorder = Colors.white.withValues(alpha: 0.3);

  // Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get strongShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [streakFire, streakFlame, streakHot],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [xpGold, Color(0xFFFFD93D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient comboGradient = LinearGradient(
    colors: [combo, Color(0xFFB265FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.1),
      Colors.white.withValues(alpha: 0.3),
      Colors.white.withValues(alpha: 0.1),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}
