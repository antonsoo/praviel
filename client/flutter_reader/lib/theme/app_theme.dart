import "dart:ui" show FontFeature, lerpDouble;

import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class ReaderSpacing extends ThemeExtension<ReaderSpacing> {
  const ReaderSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  const ReaderSpacing.fallback() : xs = 4, sm = 8, md = 12, lg = 16, xl = 24;

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  ReaderSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return ReaderSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  ReaderSpacing lerp(ThemeExtension<ReaderSpacing>? other, double t) {
    if (other is! ReaderSpacing) {
      return this;
    }
    return ReaderSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}

class ReaderTypography extends ThemeExtension<ReaderTypography> {
  const ReaderTypography({
    required this.greekDisplay,
    required this.greekBody,
    required this.uiTitle,
    required this.uiBody,
    required this.label,
  });

  ReaderTypography.fallback()
    : greekDisplay = const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.018,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: <FontFeature>[FontFeature.enable('kern')],
      ),
      greekBody = const TextStyle(
        fontSize: 20,
        height: 1.46,
        letterSpacing: 0.012,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: <FontFeature>[FontFeature.enable('kern')],
      ),
      uiTitle = const TextStyle(
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: 0.045,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      uiBody = const TextStyle(
        height: 1.55,
        letterSpacing: 0.01,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      label = const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.09,
        height: 1.2,
      );

  final TextStyle greekDisplay;
  final TextStyle greekBody;
  final TextStyle uiTitle;
  final TextStyle uiBody;
  final TextStyle label;

  @override
  ReaderTypography copyWith({
    TextStyle? greekDisplay,
    TextStyle? greekBody,
    TextStyle? uiTitle,
    TextStyle? uiBody,
    TextStyle? label,
  }) {
    return ReaderTypography(
      greekDisplay: greekDisplay ?? this.greekDisplay,
      greekBody: greekBody ?? this.greekBody,
      uiTitle: uiTitle ?? this.uiTitle,
      uiBody: uiBody ?? this.uiBody,
      label: label ?? this.label,
    );
  }

  @override
  ReaderTypography lerp(ThemeExtension<ReaderTypography>? other, double t) {
    if (other is! ReaderTypography) {
      return this;
    }
    return ReaderTypography(
      greekDisplay: TextStyle.lerp(greekDisplay, other.greekDisplay, t)!,
      greekBody: TextStyle.lerp(greekBody, other.greekBody, t)!,
      uiTitle: TextStyle.lerp(uiTitle, other.uiTitle, t)!,
      uiBody: TextStyle.lerp(uiBody, other.uiBody, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF1F4C79);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFF8F7F4),
          surfaceContainerHighest: const Color(0xFFE6ECF4),
          outlineVariant: const Color(0xFFD5DBE6),
          secondary: const Color(0xFF9C7A4B),
          tertiary: const Color(0xFF4B6652),
        );

    const spacing = ReaderSpacing(xs: 4, sm: 8, md: 12, lg: 16, xl: 24);

    final base = ThemeData(brightness: Brightness.light);
    final uiText = GoogleFonts.notoSansTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final textTheme = uiText.copyWith(
      titleLarge: uiText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.028,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      titleMedium: uiText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.024,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      bodyLarge: uiText.bodyLarge?.copyWith(
        height: 1.55,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      bodyMedium: uiText.bodyMedium?.copyWith(
        height: 1.52,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      bodySmall: uiText.bodySmall?.copyWith(
        height: 1.46,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      labelLarge: uiText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );

    const greekFeatures = <FontFeature>[FontFeature.enable('kern')];
    final typography = ReaderTypography(
      greekDisplay: const TextStyle(
        fontFamily: 'NotoSerif',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.018,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: greekFeatures,
      ),
      greekBody: const TextStyle(
        fontFamily: 'NotoSerif',
        fontSize: 18,
        height: 1.6,
        letterSpacing: 0.3,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: greekFeatures,
      ),
      uiTitle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: 0.045,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      uiBody: const TextStyle(
        fontFamily: 'Inter',
        height: 1.55,
        letterSpacing: 0.01,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      label: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.09,
        height: 1.2,
      ),
    );

    const motion = Duration(milliseconds: 190);
    final baseButtonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final filledButtonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: textTheme.labelLarge,
      shape: baseButtonShape,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ).copyWith(animationDuration: motion);

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: textTheme.labelLarge,
      shape: baseButtonShape,
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.22)),
    ).copyWith(animationDuration: motion);

    final chipTheme = ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.primaryContainer,
    );

    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3F2ED),
      textTheme: textTheme,
      chipTheme: chipTheme,
      inputDecorationTheme: inputDecorationTheme,
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      extensions: <ThemeExtension<dynamic>>[spacing, typography],
    );
  }

  static ThemeData dark() {
    const seed = Color(0xFF4A7BA7);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1A1C1E),
          surfaceContainerHighest: const Color(0xFF2B2D30),
          outlineVariant: const Color(0xFF44464F),
          secondary: const Color(0xFFBFA078),
          tertiary: const Color(0xFF7BA888),
        );

    const spacing = ReaderSpacing(xs: 4, sm: 8, md: 12, lg: 16, xl: 24);

    final base = ThemeData(brightness: Brightness.dark);
    final uiText = GoogleFonts.notoSansTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final textTheme = uiText.copyWith(
      titleLarge: uiText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.028,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      titleMedium: uiText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.024,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      bodyLarge: uiText.bodyLarge?.copyWith(
        height: 1.55,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      bodyMedium: uiText.bodyMedium?.copyWith(
        height: 1.52,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      bodySmall: uiText.bodySmall?.copyWith(
        height: 1.46,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      labelLarge: uiText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );

    const greekFeatures = <FontFeature>[FontFeature.enable('kern')];
    final typography = ReaderTypography(
      greekDisplay: const TextStyle(
        fontFamily: 'NotoSerif',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.018,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: greekFeatures,
      ),
      greekBody: const TextStyle(
        fontFamily: 'NotoSerif',
        fontSize: 18,
        height: 1.6,
        letterSpacing: 0.3,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: greekFeatures,
      ),
      uiTitle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: 0.045,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      uiBody: const TextStyle(
        fontFamily: 'Inter',
        height: 1.55,
        letterSpacing: 0.01,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      label: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.09,
        height: 1.2,
      ),
    );

    const motion = Duration(milliseconds: 190);
    final baseButtonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final filledButtonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: textTheme.labelLarge,
      shape: baseButtonShape,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ).copyWith(animationDuration: motion);

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: textTheme.labelLarge,
      shape: baseButtonShape,
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.22)),
    ).copyWith(animationDuration: motion);

    final chipTheme = ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.primaryContainer,
    );

    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF131517),
      textTheme: textTheme,
      chipTheme: chipTheme,
      inputDecorationTheme: inputDecorationTheme,
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      extensions: <ThemeExtension<dynamic>>[spacing, typography],
    );
  }
}

class ReaderTheme {
  const ReaderTheme._();

  static ReaderSpacing spacingOf(BuildContext context) =>
      Theme.of(context).extension<ReaderSpacing>() ??
      const ReaderSpacing.fallback();

  static ReaderTypography typographyOf(BuildContext context) =>
      Theme.of(context).extension<ReaderTypography>() ??
      ReaderTypography.fallback();
}
