import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VIBRANT theme system for engaging, fun language learning
/// Inspired by modern language apps with personality and polish
class VibrantTheme {
  // REFINED COLOR PALETTE - Professional yet engaging
  static const _primaryPurple = Color(0xFF6366F1); // Sophisticated indigo
  static const _primaryLight = Color(0xFF818CF8);
  static const _primaryDark = Color(0xFF4F46E5);

  static const _accentAmber = Color(0xFFF59E0B); // For XP/achievements
  static const _accentOrange = Color(0xFFF97316); // For streak flames
  static const _successGreen = Color(0xFF10B981); // For correct answers
  static const _errorRed = Color(0xFFF43F5E); // For mistakes (rose, less harsh)
  static const _teal = Color(0xFF14B8A6); // For gradients and accents

  // REFINED NEUTRALS
  static const _gray50 = Color(0xFFFAFAFA);
  static const _gray100 = Color(0xFFF5F5F5);
  static const _gray200 = Color(0xFFE5E5E5);
  static const _gray300 = Color(0xFFD4D4D4);
  static const _gray400 = Color(0xFFA3A3A3);
  static const _gray500 = Color(0xFF737373);
  static const _gray600 = Color(0xFF525252);
  static const _gray700 = Color(0xFF404040);
  static const _gray800 = Color(0xFF262626);
  static const _gray900 = Color(0xFF171717);

  // GRADIENTS - Key to modern feel
  static const heroGradient = LinearGradient(
    colors: [_primaryPurple, _teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const xpGradient = LinearGradient(
    colors: [_accentAmber, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successGradient = LinearGradient(
    colors: [_successGreen, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const streakGradient = LinearGradient(
    colors: [_accentOrange, Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const subtleGradient = LinearGradient(
    colors: [_primaryLight, _primaryPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // TYPOGRAPHY - Multi-font system for hierarchy and personality
  static TextTheme _buildTextTheme(ColorScheme colorScheme, bool isDark) {
    // Headlines: Poppins (bold, geometric, friendly)
    final displayFont = GoogleFonts.poppins(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w800,
    );

    // Body: Inter (clean, readable)
    final bodyFont = GoogleFonts.inter(
      color: colorScheme.onSurface,
      letterSpacing: -0.01,
    );

    // Numbers/Stats: Montserrat (strong, clear)
    final numberFont = GoogleFonts.montserrat(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    return TextTheme(
      // Display - Hero text (Poppins)
      displayLarge: displayFont.copyWith(
        fontSize: 57,
        height: 1.1,
        letterSpacing: -1.5,
      ),
      displayMedium: displayFont.copyWith(
        fontSize: 45,
        height: 1.15,
        letterSpacing: -1.0,
      ),
      displaySmall: displayFont.copyWith(
        fontSize: 36,
        height: 1.2,
        letterSpacing: -0.5,
      ),

      // Headlines (Poppins)
      headlineLarge: displayFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineMedium: displayFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineSmall: displayFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),

      // Titles (Inter with punch)
      titleLarge: bodyFont.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      titleMedium: bodyFont.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),

      // Body text (Inter)
      bodyLarge: bodyFont.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      bodyMedium: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      bodySmall: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),

      // Labels / stats (Montserrat)
      labelLarge: numberFont.copyWith(
        fontSize: 16,
        height: 1.25,
        letterSpacing: 0.4,
      ),
      labelMedium: numberFont.copyWith(
        fontSize: 14,
        height: 1.2,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: numberFont.copyWith(
        fontSize: 12,
        height: 1.2,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // LIGHT THEME - Vibrant and energetic
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _primaryPurple,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFF5F3FF),
      onPrimaryContainer: _primaryDark,

      secondary: _accentAmber,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: const Color(0xFF78350F),

      tertiary: _successGreen,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFD1FAE5),
      onTertiaryContainer: const Color(0xFF064E3B),

      error: _errorRed,
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

      shadow: Colors.black.withValues(alpha: 0.08),
      scrim: Colors.black.withValues(alpha: 0.5),
    );

    final textTheme = _buildTextTheme(colorScheme, false);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: _gray50,

      // CARDS - Elevated, modern
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      // BUTTONS - Bold and inviting
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 56),
          elevation: 4,
          shadowColor: _primaryPurple.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _primaryPurple,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 56),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _gray200, width: 2),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gray700,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          minimumSize: const Size(100, 52),
          side: BorderSide(color: _gray300, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryPurple,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(64, 44),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // APP BAR - Clean with shadow
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _gray900,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _gray900,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: _gray700, size: 24),
      ),

      // INPUTS - Friendly, approachable
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hoverColor: _gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _gray300, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _gray300, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryPurple, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _errorRed, width: 3),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _gray600),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _gray400),
      ),

      // FLOATING ACTION BUTTON - Bold CTA
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // BOTTOM NAV - Clean and clear
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: _primaryPurple.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryPurple, size: 28);
          }
          return IconThemeData(color: _gray400, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: _primaryPurple,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: _gray500,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // PROGRESS INDICATORS
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryPurple,
        linearTrackColor: _gray200,
        circularTrackColor: _gray200,
      ),

      // SNACKBARS - Bold feedback
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _gray900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: 16,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // CHIPS - Fun tags
      chipTheme: ChipThemeData(
        backgroundColor: _gray100,
        selectedColor: _primaryPurple.withValues(alpha: 0.12),
        disabledColor: _gray100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // DARK THEME - Vibrant in darkness
  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: _primaryLight,
      onPrimary: _gray900,
      primaryContainer: _primaryDark,
      onPrimaryContainer: _primaryLight,

      secondary: _accentAmber,
      onSecondary: _gray900,
      secondaryContainer: const Color(0xFF78350F),
      onSecondaryContainer: const Color(0xFFFEF3C7),

      tertiary: const Color(0xFF34D399),
      onTertiary: _gray900,
      tertiaryContainer: const Color(0xFF064E3B),
      onTertiaryContainer: const Color(0xFFD1FAE5),

      error: const Color(0xFFFCA5A5),
      onError: _gray900,
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFEE2E2),

      surface: const Color(0xFF0F0F0F),
      onSurface: _gray100,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF171717),
      surfaceContainer: _gray800,
      surfaceContainerHigh: _gray700,
      surfaceContainerHighest: _gray600,
      onSurfaceVariant: _gray400,

      outline: _gray700,
      outlineVariant: _gray800,

      shadow: Colors.black.withValues(alpha: 0.3),
      scrim: Colors.black.withValues(alpha: 0.7),
    );

    final textTheme = _buildTextTheme(colorScheme, true);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.black,

      // Similar theme structure as light, adapted for dark mode
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        color: _gray900,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: _gray900,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 56),
          elevation: 8,
          shadowColor: _primaryLight.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _gray800,
          foregroundColor: _gray100,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 56),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _gray700, width: 2),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gray100,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          minimumSize: const Size(100, 52),
          side: BorderSide(color: _gray600, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(64, 44),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _gray100,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _gray100,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: _gray300, size: 24),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: _gray900,
        indicatorColor: _primaryLight.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _primaryLight, size: 28);
          }
          return IconThemeData(color: _gray500, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: _primaryLight,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: _gray500,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _primaryLight,
        linearTrackColor: _gray800,
        circularTrackColor: _gray800,
      ),
    );
  }
}

/// Spacing system - 4px base
class VibrantSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Radius system - Generous curves
class VibrantRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;
}

/// Shadow system - Subtle depth
class VibrantShadow {
  static List<BoxShadow> sm(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> md(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lg(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> xl(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
