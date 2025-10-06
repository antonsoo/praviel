import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Beautiful animated progress ring with glow effects
/// Perfect for displaying XP progress, lesson completion, streaks
class AnimatedProgressRing extends StatefulWidget {
  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.size,
    this.strokeWidth = 12.0,
    this.gradient,
    this.backgroundColor,
    this.glowColor,
    this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? glowColor;
  final Widget? child;
  final Duration duration;

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ProgressRingPainter(
            progress: _progressAnimation.value,
            strokeWidth: widget.strokeWidth,
            gradient: widget.gradient ??
                const LinearGradient(
                  colors: [
                    Color(0xFFFBBF24),
                    Color(0xFFF59E0B),
                  ],
                ),
            backgroundColor:
                widget.backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
            glowColor: widget.glowColor ?? const Color(0xFFFBBF24),
          ),
          size: Size(widget.size, widget.size),
          child: widget.child != null
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Center(child: widget.child),
                )
              : null,
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
    required this.backgroundColor,
    required this.glowColor,
  });

  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final Color backgroundColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with glow
    if (progress > 0) {
      // Glow layer
      final glowPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);

      final glowRect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(glowRect, startAngle, sweepAngle, false, glowPaint);

      // Main progress arc
      final progressPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // Animated sparkle at the end
      if (progress < 1.0) {
        final endAngle = startAngle + sweepAngle;
        final sparkleX = center.dx + radius * math.cos(endAngle);
        final sparkleY = center.dy + radius * math.sin(endAngle);

        final sparklePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(
          Offset(sparkleX, sparkleY),
          strokeWidth / 2,
          sparklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Pulsing progress indicator for loading states
class PulsingRing extends StatefulWidget {
  const PulsingRing({
    super.key,
    required this.size,
    this.color = const Color(0xFF667EEA),
  });

  final double size;
  final Color color;

  @override
  State<PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PulsingRingPainter(
            progress: _controller.value,
            color: widget.color,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }
}

class _PulsingRingPainter extends CustomPainter {
  _PulsingRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw multiple pulsing rings
    for (var i = 0; i < 3; i++) {
      final ringProgress = ((progress - i * 0.3) % 1.0);
      final radius = (size.width / 2) * ringProgress;
      final opacity = (1 - ringProgress) * 0.8;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
