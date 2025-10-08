import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Circular XP progress ring with level in center
/// Pulses when close to leveling up
class XPRingProgress extends StatefulWidget {
  const XPRingProgress({
    super.key,
    required this.currentLevel,
    required this.progressToNextLevel,
    required this.xpInCurrentLevel,
    required this.xpNeededForNextLevel,
    this.size = 120,
  });

  final int currentLevel;
  final double progressToNextLevel; // 0.0 to 1.0
  final int xpInCurrentLevel;
  final int xpNeededForNextLevel;
  final double size;

  @override
  State<XPRingProgress> createState() => _XPRingProgressState();
}

class _XPRingProgressState extends State<XPRingProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Pulse when >= 80% progress
    final shouldPulse = widget.progressToNextLevel >= 0.8;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect when close to level up
          if (shouldPulse)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: widget.size * (1 + _pulseController.value * 0.2),
                  height: widget.size * (1 + _pulseController.value * 0.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.3 * _pulseController.value),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                );
              },
            ),

          // Progress ring
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingProgressPainter(
              progress: widget.progressToNextLevel,
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundGradient: VibrantTheme.xpGradient,
              strokeWidth: widget.size * 0.12,
            ),
          ),

          // Level number in center
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.currentLevel}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: widget.size * 0.35,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = VibrantTheme.heroGradient.createShader(
                      Rect.fromLTWH(0, 0, widget.size, widget.size),
                    ),
                ),
              ),
              Text(
                'Level',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Sparkle particles when close to level up
          if (shouldPulse)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _SparklePainter(
                    animation: _pulseController.value,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  _RingProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundGradient,
    required this.strokeWidth,
  });

  final double progress;
  final Color backgroundColor;
  final Gradient foregroundGradient;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground progress arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..shader = foregroundGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = -pi / 2; // Start from top
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        fgPaint,
      );

      // Add a glow dot at the end of the progress
      final endAngle = startAngle + sweepAngle;
      final dotX = center.dx + radius * cos(endAngle);
      final dotY = center.dy + radius * sin(endAngle);

      final dotPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth * 0.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.animation,
  });

  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw sparkles around the ring
    final sparkleCount = 6;
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * pi + animation * 2 * pi;
      final sparkleRadius = radius * 0.85;

      final x = center.dx + cos(angle) * sparkleRadius;
      final y = center.dy + sin(angle) * sparkleRadius;

      // Sparkle opacity varies with animation
      final opacity = (sin(animation * pi * 2 + i) * 0.5 + 0.5).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw star shape
      _drawStar(canvas, Offset(x, y), 4 + opacity * 2, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) - pi / 4;
      final x = center.dx + cos(angle) * size;
      final y = center.dy + sin(angle) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => true;
}

/// Compact XP bar for inline display
class CompactXPBar extends StatelessWidget {
  const CompactXPBar({
    super.key,
    required this.currentXP,
    required this.maxXP,
    this.height = 8,
  });

  final int currentXP;
  final int maxXP;
  final double height;

  @override
  Widget build(BuildContext context) {
    final progress = maxXP > 0 ? (currentXP / maxXP).clamp(0.0, 1.0) : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: VibrantTheme.xpGradient,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
