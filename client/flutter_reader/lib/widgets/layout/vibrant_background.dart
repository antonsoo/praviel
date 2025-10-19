import 'dart:ui';

import 'package:flutter/material.dart';

/// Premium decorative background with depth and sophistication
///
/// Provides a beautifully layered gradient canvas with subtle glows
/// and blur effects that create depth and premium feel
class VibrantBackground extends StatelessWidget {
  const VibrantBackground({
    super.key,
    required this.child,
    this.gradient,
    this.addGlows = true,
    this.intensity = 1.0,
  });

  /// Content displayed on top of the gradient background.
  final Widget child;

  /// Optional override for the background gradient.
  final Gradient? gradient;

  /// When true, subtle decorative glows are rendered behind the content.
  final bool addGlows;

  /// Intensity of the glow effect (0.0 to 1.0)
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseGradient = gradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A1A),
                  colorScheme.surface,
                ]
              : [
                  colorScheme.surfaceContainerLow,
                  colorScheme.surface,
                  const Color(0xFFFDFDFD),
                ],
          stops: const [0.0, 0.5, 1.0],
        );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: baseGradient),
      child: Stack(
        children: [
          if (addGlows) ...[
            // Top-left glow - soft white/primary
            _GlowCircle(
              diameter: 400 * intensity,
              offset: Offset(-150, -120),
              gradient: RadialGradient(
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.08 * intensity)
                      : Colors.white.withValues(alpha: 0.6 * intensity),
                  Colors.transparent,
                ],
              ),
            ),
            // Top-right glow - primary color
            _GlowCircle(
              diameter: 350 * intensity,
              offset: const Offset(280, -80),
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.15 * intensity),
                  colorScheme.primary.withValues(alpha: 0.05 * intensity),
                  Colors.transparent,
                ],
              ),
            ),
            // Middle glow - secondary color
            _GlowCircle(
              diameter: 420 * intensity,
              offset: const Offset(-80, 350),
              gradient: RadialGradient(
                colors: [
                  colorScheme.tertiary.withValues(alpha: 0.12 * intensity),
                  colorScheme.tertiary.withValues(alpha: 0.04 * intensity),
                  Colors.transparent,
                ],
              ),
            ),
            // Bottom-right glow - accent
            _GlowCircle(
              diameter: 380 * intensity,
              offset: const Offset(250, 550),
              gradient: RadialGradient(
                colors: [
                  colorScheme.secondary.withValues(alpha: 0.1 * intensity),
                  Colors.transparent,
                ],
              ),
            ),
          ],
          // Subtle blur for depth
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 30 * intensity,
                  sigmaY: 30 * intensity,
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.diameter,
    required this.offset,
    required this.gradient,
  });

  final double diameter;
  final Offset offset;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        ),
      ),
    );
  }
}
