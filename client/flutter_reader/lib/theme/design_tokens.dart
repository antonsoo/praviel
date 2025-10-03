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

  // Primary - Deep Blue (trust, learning)
  static const Color primaryLight = Color(0xFF1E40AF);
  static const Color primaryContainerLight = Color(0xFFDEE7FF);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryContainerLight = Color(0xFF001B3D);

  // Secondary - Warm Amber (achievement, energy)
  static const Color secondaryLight = Color(0xFFF59E0B);
  static const Color secondaryContainerLight = Color(0xFFFFECC7);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryContainerLight = Color(0xFF2A1800);

  // Success - Vibrant Green (progress)
  static const Color successLight = Color(0xFF10B981);
  static const Color successContainerLight = Color(0xFFC7F5DE);
  static const Color onSuccessLight = Color(0xFFFFFFFF);

  // Error - Coral Red (gentle correction)
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorContainerLight = Color(0xFFFFDAD6);
  static const Color onErrorLight = Color(0xFFFFFFFF);

  // Surface & Background
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color onSurfaceLight = Color(0xFF1F2937);
  static const Color onSurfaceVariantLight = Color(0xFF6B7280);
  static const Color outlineLight = Color(0xFFD1D5DB);
  static const Color outlineVariantLight = Color(0xFFE5E7EB);

  // Dark Theme
  static const Color primaryDark = Color(0xFF60A5FA);
  static const Color primaryContainerDark = Color(0xFF1E3A5F);
  static const Color onPrimaryDark = Color(0xFF001B3D);
  static const Color onPrimaryContainerDark = Color(0xFFDEE7FF);

  static const Color secondaryDark = Color(0xFFFBBF24);
  static const Color secondaryContainerDark = Color(0xFF4A3300);
  static const Color onSecondaryDark = Color(0xFF2A1800);
  static const Color onSecondaryContainerDark = Color(0xFFFFECC7);

  static const Color successDark = Color(0xFF34D399);
  static const Color successContainerDark = Color(0xFF064E3B);
  static const Color onSuccessDark = Color(0xFF064E3B);

  static const Color errorDark = Color(0xFFF87171);
  static const Color errorContainerDark = Color(0xFF7F1D1D);
  static const Color onErrorDark = Color(0xFF7F1D1D);

  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color onSurfaceDark = Color(0xFFF9FAFB);
  static const Color onSurfaceVariantDark = Color(0xFF9CA3AF);
  static const Color outlineDark = Color(0xFF4B5563);
  static const Color outlineVariantDark = Color(0xFF374151);
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
