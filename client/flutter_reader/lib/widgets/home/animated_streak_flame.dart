import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Animated streak flame that ACTUALLY BURNS! 🔥
/// Gets more intense with higher streaks
class AnimatedStreakFlame extends StatefulWidget {
  const AnimatedStreakFlame({
    super.key,
    required this.streakDays,
    this.size = 48,
  });

  final int streakDays;
  final double size;

  @override
  State<AnimatedStreakFlame> createState() => _AnimatedStreakFlameState();
}

class _AnimatedStreakFlameState extends State<AnimatedStreakFlame>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Main flame flicker animation
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Pulse animation for high streaks
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Intensity based on streak
    final intensity = (widget.streakDays / 30).clamp(0.5, 1.5);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect (gets stronger with streak)
          if (widget.streakDays >= 7)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: widget.size * (1 + _pulseController.value * 0.3),
                  height: widget.size * (1 + _pulseController.value * 0.3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF6B35)
                            .withValues(alpha: 0.3 * _pulseController.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

          // Animated flame
          AnimatedBuilder(
            animation: _flameController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _FlamePainter(
                  animation: _flameController.value,
                  intensity: intensity,
                  streakDays: widget.streakDays,
                ),
              );
            },
          ),

          // Streak number overlay
          Text(
            '${widget.streakDays}',
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.size * 0.35,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: Color(0xFFFF6B35),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({
    required this.animation,
    required this.intensity,
    required this.streakDays,
  });

  final double animation;
  final double intensity;
  final int streakDays;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Create multiple flame layers for depth
    _drawFlameLayer(
      canvas,
      center,
      size,
      const Color(0xFFFBBF24), // Yellow core
      0.3,
      animation,
    );
    _drawFlameLayer(
      canvas,
      center,
      size,
      const Color(0xFFF59E0B), // Orange middle
      0.5,
      animation + 0.2,
    );
    _drawFlameLayer(
      canvas,
      center,
      size,
      const Color(0xFFFF6B35), // Red outer
      0.7,
      animation + 0.4,
    );
  }

  void _drawFlameLayer(
    Canvas canvas,
    Offset center,
    Size size,
    Color color,
    double scale,
    double animationOffset,
  ) {
    final path = Path();
    final points = <Offset>[];

    // Generate flame shape with animated flicker
    final segments = 20;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * pi * 2 - pi / 2;
      final t = i / segments;

      // Flicker effect using sine waves
      final flicker1 = sin(animationOffset * 2 * pi + t * 4 * pi) * 0.1;
      final flicker2 = sin(animationOffset * 3 * pi + t * 6 * pi) * 0.05;

      // Flame shape (wider at bottom, pointed at top)
      final baseRadius = size.width * 0.4 * scale;
      final heightFactor = 1 - (t * t); // Taper towards top
      final radius = baseRadius * heightFactor * (1 + flicker1 + flicker2);

      final x = center.dx + cos(angle) * radius * 0.6; // Narrower horizontally
      final y = center.dy - (t * size.height * 0.8 * scale) + flicker1 * 5;

      points.add(Offset(x, y));
    }

    // Draw flame
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.3),
          ],
        ).createShader(
          Rect.fromCenter(
            center: center,
            width: size.width,
            height: size.height,
          ),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => true;
}

/// Compact streak indicator for app bar
class StreakIndicator extends StatelessWidget {
  const StreakIndicator({
    super.key,
    required this.streakDays,
  });

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: VibrantTheme.streakGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            '$streakDays',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
