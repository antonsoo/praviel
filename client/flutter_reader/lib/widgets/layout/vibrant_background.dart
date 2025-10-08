import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_reader/theme/vibrant_theme.dart';

/// Decorative background used for vibrant experiences.
///
/// Provides a softly blurred gradient canvas with a few accent glows so that
/// foreground cards can float on top without requiring every screen to
/// reimplement the same Stack boilerplate.
class VibrantBackground extends StatelessWidget {
  const VibrantBackground({
    super.key,
    required this.child,
    this.gradient,
    this.addGlows = true,
  });

  /// Content displayed on top of the gradient background.
  final Widget child;

  /// Optional override for the background gradient.
  final Gradient? gradient;

  /// When true, subtle decorative glows are rendered behind the content.
  final bool addGlows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseGradient =
        gradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHigh,
            colorScheme.surface,
            colorScheme.surface.withValues(alpha: 0.96),
          ],
          stops: const [0, 0.55, 1],
        );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: baseGradient),
      child: Stack(
        children: [
          if (addGlows) ...[
            const _GlowCircle(
              diameter: 280,
              offset: Offset(-120, -100),
              gradient: RadialGradient(
                colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
              ),
            ),
            const _GlowCircle(
              diameter: 220,
              offset: Offset(220, 40),
              gradient: RadialGradient(
                colors: [Color(0x4465A8F7), Color(0x003C46A3)],
              ),
            ),
            _GlowCircle(
              diameter: 320,
              offset: const Offset(-40, 320),
              gradient: RadialGradient(
                colors: [
                  VibrantTheme.heroGradient.colors.first.withValues(
                    alpha: 0.35,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ],
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox.expand(),
              ),
            ),
          ),
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
