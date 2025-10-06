import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PROFESSIONAL design system inspired by Linear, Stripe, and Apple
/// This is what $10M+ apps look like
class ProfessionalTheme {
  // SOPHISTICATED COLOR PALETTE - No childish gradients
  static const _brandPrimary = Color(0xFF0F172A); // Deep slate
  static const _brandAccent = Color(0xFF6366F1); // Indigo
  static const _brandSuccess = Color(0xFF10B981); // Emerald
  static const _brandWarning = Color(0xFFF59E0B); // Amber
  static const _brandError = Color(0xEF4444FF); // Red

  // REFINED NEUTRALS - Professional gray scale
  static const _gray50 = Color(0xFFF8FAFC);
  static const _gray100 = Color(0xFFF1F5F9);
  static const _gray200 = Color(0xFFE2E8F0);
  static const _gray300 = Color(0xFFCBD5E1);
  static const _gray400 = Color(0xFF94A3B8);
  static const _gray500 = Color(0xFF64748B);
  static const _gray600 = Color(0xFF475569);
  static const _gray700 = Color(0xFF334155);
  static const _gray800 = Color(0xFF1E293B);
  static const _gray900 = Color(0xFF0F172A);

  // TYPOGRAPHY - Professional hierarchy
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    // Using Inter for UI (like Linear, Stripe, Apple)
    final baseStyle = GoogleFonts.inter(
      color: colorScheme.onSurface,
      letterSpacing: -0.01,
      height: 1.5,
    );

    return TextTheme(
      // Display - Hero text
      displayLarge: baseStyle.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: baseStyle.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.15,
      ),
      displaySmall: baseStyle.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),

      // Headlines - Section titles
      headlineLarge: baseStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineMedium: baseStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineSmall: baseStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      ),

      // Titles - Card/component titles
      titleLarge: baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.4,
      ),
      titleMedium: baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      titleSmall: baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        height: 1.4,
      ),

      // Body - Content text
      bodyLarge: baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.6,
      ),
      bodyMedium: baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.6,
      ),
      bodySmall: baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
      ),

      // Labels - UI elements
      labelLarge: baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.3,
      ),
      labelSmall: baseStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
      ),
    );
  }

  // LIGHT THEME - Clean, sophisticated
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _brandAccent,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEEF2FF),
      onPrimaryContainer: const Color(0xFF312E81),

      secondary: _brandPrimary,
      onSecondary: Colors.white,
      secondaryContainer: _gray100,
      onSecondaryContainer: _gray900,

      tertiary: _brandSuccess,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFD1FAE5),
      onTertiaryContainer: const Color(0xFF064E3B),

      error: _brandError,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),

      surface: Colors.white,
      onSurface: _gray900,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: _gray50,
      surfaceContainer: _gray100,
      surfaceContainerHigh: _gray200,
      surfaceContainerHighest: _gray300,
      onSurfaceVariant: _gray600,

      outline: _gray300,
      outlineVariant: _gray200,

      shadow: Colors.black.withValues(alpha: 0.05),
      scrim: Colors.black.withValues(alpha: 0.5),
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: _gray50,

      // CARDS - Subtle, refined
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _gray200, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // BUTTONS - Professional, not playful
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brandAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(64, 44),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gray700,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(64, 44),
          side: BorderSide(color: _gray300, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _gray700,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // APP BAR - Minimal, clean
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _gray900,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: _gray900),
        iconTheme: const IconThemeData(color: _gray700, size: 20),
      ),

      // INPUTS - Clean, refined
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hoverColor: _gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _gray300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _gray300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _brandAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _brandError, width: 1),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _gray600),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _gray400),
      ),

      // DIVIDERS - Subtle
      dividerTheme: DividerThemeData(
        color: _gray200,
        thickness: 1,
        space: 1,
      ),

      // SNACKBARS - Professional
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _gray900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // DARK THEME - True black like pros use
  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFF818CF8),
      onPrimary: _gray900,
      primaryContainer: const Color(0xFF3730A3),
      onPrimaryContainer: const Color(0xFFE0E7FF),

      secondary: _gray100,
      onSecondary: _gray900,
      secondaryContainer: _gray800,
      onSecondaryContainer: _gray100,

      tertiary: const Color(0xFF34D399),
      onTertiary: _gray900,
      tertiaryContainer: const Color(0xFF065F46),
      onTertiaryContainer: const Color(0xFFD1FAE5),

      error: const Color(0xFFFCA5A5),
      onError: _gray900,
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFEE2E2),

      surface: const Color(0xFF0A0E1A),
      onSurface: _gray100,
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0F172A),
      surfaceContainer: const Color(0xFF1E293B),
      surfaceContainerHigh: _gray800,
      surfaceContainerHighest: _gray700,
      onSurfaceVariant: _gray400,

      outline: _gray700,
      outlineVariant: _gray800,

      shadow: Colors.black.withValues(alpha: 0.3),
      scrim: Colors.black.withValues(alpha: 0.7),
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF0A0E1A),

      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _gray800, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF818CF8),
          foregroundColor: _gray900,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(64, 44),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gray100,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(64, 44),
          side: BorderSide(color: _gray700, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF0A0E1A),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _gray100,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: _gray100),
        iconTheme: IconThemeData(color: _gray400, size: 20),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        hoverColor: _gray800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _gray700, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _gray700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _gray400),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _gray600),
      ),

      dividerTheme: DividerThemeData(
        color: _gray800,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _gray100,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _gray900),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Professional spacing system - 4px base
class ProSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Professional radius system
class ProRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
}

/// Professional elevation/shadow system
class ProElevation {
  // Subtle shadows like Apple/Linear use
  static List<BoxShadow> sm(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> md(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> lg(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> xl(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
