import 'package:flutter/material.dart';

/// Vibrant color system inspired by modern language learning apps
/// These colors are designed to be energetic, motivating, and fun
class VibrantColors {
  VibrantColors._();

  // Primary Brand Colors - Sophisticated and engaging
  static const primary = Color(0xFF6366F1); // Refined indigo
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);

  // Secondary - Modern and balanced
  static const secondary = Color(0xFF14B8A6); // Professional teal
  static const secondaryDark = Color(0xFF0D9488);
  static const secondaryLight = Color(0xFF2DD4BF);

  // Success - Clear positive feedback
  static const success = Color(0xFF10B981); // Professional emerald
  static const successDark = Color(0xFF059669);
  static const successLight = Color(0xFF34D399);

  // Error - Clear but not harsh
  static const error = Color(0xFFF43F5E); // Balanced rose
  static const errorDark = Color(0xFFE11D48);
  static const errorLight = Color(0xFFFB7185);

  // Warning - Noticeable but refined
  static const warning = Color(0xFFF59E0B); // Refined amber
  static const warningDark = Color(0xFFD97706);
  static const warningLight = Color(0xFFFBBF24);

  // XP & Leveling
  static const xpGold = Color(0xFFF59E0B);
  static const xpSilver = Color(0xFFA1A1AA);
  static const xpBronze = Color(0xFFB45309);

  // Streak Colors
  static const streakFlame = Color(0xFFF97316);
  static const streakFire = Color(0xFFEF4444);
  static const streakHot = Color(0xFFFBBF24);

  // Gamification
  static const combo = Color(
    0xFFA78BFA,
  ); // Refined purple for combo multipliers
  static const powerUp = Color(0xFF06B6D4); // Professional cyan for power-ups
  static const achievement = Color(0xFFF59E0B); // Refined gold for achievements
  static const badge = Color(0xFF6366F1); // Indigo for badges

  // Background gradients
  static const gradientStart = Color(0xFF6366F1); // Indigo
  static const gradientEnd = Color(0xFF8B5CF6); // Violet
  static const gradientAccent = Color(0xFF14B8A6); // Teal accent

  // Surface colors
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF18181B);
  static const surfaceElevated = Color(0xFF27272A);

  // Text colors
  static const textPrimary = Color(0xFF18181B);
  static const textSecondary = Color(0xFF71717A);
  static const textHint = Color(0xFFA1A1AA);
  static const textOnDark = Colors.white;

  // Accent colors for variety
  static const accentPink = Color(0xFFEC4899);
  static const accentTeal = Color(0xFF14B8A6);
  static const accentMint = Color(0xFF10B981);
  static const accentLavender = Color(0xFFA78BFA);

  // Exercise type colors
  static const alphabetColor = Color(0xFF8B5CF6); // Violet
  static const matchColor = Color(0xFFEC4899); // Pink
  static const clozeColor = Color(0xFF14B8A6); // Teal
  static const translateColor = Color(0xFFF59E0B); // Amber

  // Level colors
  static const level1 = Color(0xFF8B5CF6);
  static const level2 = Color(0xFF6366F1);
  static const level3 = Color(0xFF14B8A6);
  static const level4 = Color(0xFFF59E0B);
  static const level5 = Color(0xFFF97316);

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
