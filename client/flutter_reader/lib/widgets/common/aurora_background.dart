import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared animated aurora background with subtle grid shimmer.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -140 + math.sin(t * 2 * math.pi) * 60,
              left: -80 + math.cos(t * 2 * math.pi) * 40,
              child: const AuroraGlowBlob(
                size: 280,
                colors: [Color(0xFF4C1D95), Color(0xFF6366F1)],
                opacity: 0.8,
              ),
            ),
            Positioned(
              right: -100 + math.sin((t + 0.35) * 2 * math.pi) * 70,
              top: -80,
              child: const AuroraGlowBlob(
                size: 240,
                colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                opacity: 0.7,
              ),
            ),
            Positioned(
              bottom: -140 + math.cos((t + 0.65) * 2 * math.pi) * 50,
              left: math.sin((t + 0.5) * 2 * math.pi) * 90,
              child: const AuroraGlowBlob(
                size: 260,
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                opacity: 0.6,
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: AuroraGridPainter(progress: t)),
            ),
          ],
        );
      },
    );
  }
}

class AuroraGlowBlob extends StatelessWidget {
  const AuroraGlowBlob({
    super.key,
    required this.size,
    required this.colors,
    required this.opacity,
  });

  final double size;
  final List<Color> colors;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: size * 0.17, sigmaY: size * 0.17),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              colors.first.withValues(alpha: 0.0),
              colors.first.withValues(alpha: 0.35 * opacity),
              colors.last.withValues(alpha: 0.75 * opacity),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

class AuroraGridPainter extends CustomPainter {
  const AuroraGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final verticalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.2;

    final horizontalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const verticalLines = 8;
    const horizontalLines = 6;

    final waveOffset = math.sin(progress * 2 * math.pi) * 8;

    for (var i = 0; i <= verticalLines; i++) {
      final x = (size.width / verticalLines) * i;
      canvas.drawLine(
        Offset(x + waveOffset, 0),
        Offset(x - waveOffset, size.height),
        verticalPaint,
      );
    }

    for (var j = 0; j <= horizontalLines; j++) {
      final y = (size.height / horizontalLines) * j;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horizontalPaint);
    }
  }

  @override
  bool shouldRepaint(AuroraGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
