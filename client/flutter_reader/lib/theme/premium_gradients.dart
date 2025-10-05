import 'package:flutter/material.dart';

/// Premium gradient system for stunning visual design
/// Inspired by Linear, Stripe, and modern SaaS apps
class PremiumGradients {
  const PremiumGradients._();

  // ============================================================================
  // Hero Gradients (Full-screen backgrounds)
  // ============================================================================

  /// Oceanic blue gradient - Premium, trustworthy
  static const LinearGradient oceanicHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9), // Sky blue
      Color(0xFF2563EB), // Blue
      Color(0xFF7C3AED), // Purple
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Sunset gradient - Warm, inviting
  static const LinearGradient sunsetHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFFEC4899), // Pink
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// Forest gradient - Growth, learning
  static const LinearGradient forestHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Emerald
      Color(0xFF059669), // Green
      Color(0xFF0D9488), // Teal
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Aurora gradient - Magical, ethereal
  static const LinearGradient auroraHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6), // Violet
      Color(0xFFEC4899), // Pink
      Color(0xFF06B6D4), // Cyan
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // Card Gradients (Subtle, for cards & surfaces)
  // ============================================================================

  /// Soft blue card gradient
  static const LinearGradient softBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEFF6FF), // Very light blue
      Color(0xFFDEEAFE), // Light blue
    ],
  );

  /// Soft purple card gradient
  static const LinearGradient softPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5F3FF), // Very light purple
      Color(0xFFEDE9FE), // Light purple
    ],
  );

  /// Soft green card gradient
  static const LinearGradient softGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFECFDF5), // Very light green
      Color(0xFFD1FAE5), // Light green
    ],
  );

  /// Soft orange card gradient
  static const LinearGradient softOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF7ED), // Very light orange
      Color(0xFFFFEDD5), // Light orange
    ],
  );

  // ============================================================================
  // Button Gradients (Vibrant, for CTAs)
  // ============================================================================

  /// Primary button gradient
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // Blue
      Color(0xFF2563EB), // Darker blue
    ],
  );

  /// Success button gradient
  static const LinearGradient successButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Emerald
      Color(0xFF059669), // Darker emerald
    ],
  );

  /// Streak button gradient (fire theme)
  static const LinearGradient streakButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
    ],
  );

  /// Premium button gradient (gold)
  static const LinearGradient premiumButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBBF24), // Yellow
      Color(0xFFF59E0B), // Amber
      Color(0xFFEA580C), // Orange
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // Mesh Gradients (Complex, multi-color backgrounds)
  // ============================================================================

  /// Learning mesh gradient
  static const RadialGradient learningMesh = RadialGradient(
    center: Alignment(0.3, -0.5),
    radius: 1.5,
    colors: [
      Color(0xFF60A5FA), // Light blue
      Color(0xFF3B82F6), // Blue
      Color(0xFF1D4ED8), // Dark blue
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Achievement mesh gradient
  static const RadialGradient achievementMesh = RadialGradient(
    center: Alignment(0.0, -0.3),
    radius: 1.2,
    colors: [
      Color(0xFFFCD34D), // Yellow
      Color(0xFFF59E0B), // Amber
      Color(0xFFD97706), // Dark amber
    ],
    stops: [0.0, 0.6, 1.0],
  );

  // ============================================================================
  // Shimmer Gradients (For loading states)
  // ============================================================================

  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    stops: [0.0, 0.5, 1.0],
  );
}

/// Glass morphism effect with blur
class GlassMorphism {
  const GlassMorphism._();

  /// Light glass effect
  static BoxDecoration light({BorderRadius? borderRadius, Border? border}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border:
          border ??
          Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Dark glass effect
  static BoxDecoration dark({BorderRadius? borderRadius, Border? border}) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border:
          border ??
          Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

/// Premium shadow system for depth
class PremiumShadows {
  const PremiumShadows._();

  /// Soft elevation (cards)
  static List<BoxShadow> soft({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: 0.02),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Medium elevation (floating elements)
  static List<BoxShadow> medium({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: 0.04),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Strong elevation (modals, dialogs)
  static List<BoxShadow> strong({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: 0.08),
        blurRadius: 48,
        offset: const Offset(0, 16),
      ),
    ];
  }

  /// Glow effect (for highlights)
  static List<BoxShadow> glow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 40,
        spreadRadius: 4,
      ),
    ];
  }

  /// Colored shadow (for themed elements)
  static List<BoxShadow> colored(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.1),
        blurRadius: 48,
        offset: const Offset(0, 16),
      ),
    ];
  }
}
