import 'package:flutter/material.dart';

/// Design tokens for the Ancient Languages app
/// Following Material Design 3 and modern language learning app patterns

// ============================================================================
// Typography Scale
// ============================================================================
class AppTypography {
  const AppTypography._();

  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
}

// ============================================================================
// Spacing Scale (8px base)
// ============================================================================
class AppSpacing {
  const AppSpacing._();

  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;
  static const double space80 = 80.0;
}

// ============================================================================
// Border Radius
// ============================================================================
class AppRadius {
  const AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xLarge = 20.0;
  static const double xxLarge = 24.0;
  static const double full = 999.0;
}

// ============================================================================
// Elevation (shadows)
// ============================================================================
class AppElevation {
  const AppElevation._();

  static const double none = 0.0;
  static const double low = 2.0;
  static const double medium = 4.0;
  static const double high = 8.0;
  static const double xHigh = 12.0;
}

// ============================================================================
// Animation Durations
// ============================================================================
class AppDuration {
  const AppDuration._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration xSlow = Duration(milliseconds: 600);
}

// ============================================================================
// Animation Curves
// ============================================================================
class AppCurves {
  const AppCurves._();

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeOutCubic;
}

// ============================================================================
// Color Palette (Light Theme)
// ============================================================================
class AppColors {
  const AppColors._();

  // Primary - Sophisticated Indigo (trust, learning, premium feel)
  static const Color primaryLight = Color(0xFF4F46E5);
  static const Color primaryContainerLight = Color(0xFFEEF2FF);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryContainerLight = Color(0xFF1E1B4B);

  // Secondary - Refined Teal (achievement, progress, calm energy)
  static const Color secondaryLight = Color(0xFF0D9488);
  static const Color secondaryContainerLight = Color(0xFFCCFBF1);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryContainerLight = Color(0xFF134E4A);

  // Success - Professional Emerald (progress, correct answers)
  static const Color successLight = Color(0xFF059669);
  static const Color successContainerLight = Color(0xFFD1FAE5);
  static const Color onSuccessLight = Color(0xFFFFFFFF);

  // Error - Balanced Rose (gentle correction, not alarming)
  static const Color errorLight = Color(0xFFE11D48);
  static const Color errorContainerLight = Color(0xFFFFE4E6);
  static const Color onErrorLight = Color(0xFFFFFFFF);

  // Surface & Background - Clean, spacious
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color onSurfaceLight = Color(0xFF18181B);
  static const Color onSurfaceVariantLight = Color(0xFF71717A);
  static const Color outlineLight = Color(0xFFE4E4E7);
  static const Color outlineVariantLight = Color(0xFFF4F4F5);

  // Dark Theme - Rich, not harsh
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color primaryContainerDark = Color(0xFF312E81);
  static const Color onPrimaryDark = Color(0xFF1E1B4B);
  static const Color onPrimaryContainerDark = Color(0xFFEEF2FF);

  static const Color secondaryDark = Color(0xFF5EEAD4);
  static const Color secondaryContainerDark = Color(0xFF134E4A);
  static const Color onSecondaryDark = Color(0xFF134E4A);
  static const Color onSecondaryContainerDark = Color(0xFFCCFBF1);

  static const Color successDark = Color(0xFF34D399);
  static const Color successContainerDark = Color(0xFF065F46);
  static const Color onSuccessDark = Color(0xFF065F46);

  static const Color errorDark = Color(0xFFFB7185);
  static const Color errorContainerDark = Color(0xFF881337);
  static const Color onErrorDark = Color(0xFF881337);

  static const Color surfaceDark = Color(0xFF18181B);
  static const Color backgroundDark = Color(0xFF09090B);
  static const Color onSurfaceDark = Color(0xFFFAFAFA);
  static const Color onSurfaceVariantDark = Color(0xFFA1A1AA);
  static const Color outlineDark = Color(0xFF3F3F46);
  static const Color outlineVariantDark = Color(0xFF27272A);
}

// ============================================================================
// Semantic Colors
// ============================================================================
extension SemanticColors on ColorScheme {
  Color get success => brightness == Brightness.light
      ? AppColors.successLight
      : AppColors.successDark;

  Color get onSuccess => brightness == Brightness.light
      ? AppColors.onSuccessLight
      : AppColors.onSuccessDark;

  Color get successContainer => brightness == Brightness.light
      ? AppColors.successContainerLight
      : AppColors.successContainerDark;
}
