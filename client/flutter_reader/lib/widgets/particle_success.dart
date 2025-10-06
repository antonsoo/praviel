import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium particle explosion effect for correct answers
/// Makes users FEEL the success
class ParticleSuccess extends StatefulWidget {
  const ParticleSuccess({
    super.key,
    required this.child,
    this.particleCount = 30,
  });

  final Widget child;
  final int particleCount;

  @override
  State<ParticleSuccess> createState() => _ParticleSuccessState();
}

class _ParticleSuccessState extends State<ParticleSuccess>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle(index),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ParticlePainter(
                progress: _controller.value,
                particles: _particles,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class _Particle {
  _Particle(int seed) {
    final random = math.Random(seed);
    angle = random.nextDouble() * math.pi * 2;
    speed = 100 + random.nextDouble() * 200;
    size = 4 + random.nextDouble() * 8;
    color = _colors[random.nextInt(_colors.length)];
    rotation = random.nextDouble() * math.pi * 2;
    rotationSpeed = (random.nextDouble() - 0.5) * 8;
  }

  late final double angle;
  late final double speed;
  late final double size;
  late final Color color;
  late final double rotation;
  late final double rotationSpeed;

  static const _colors = [
    Color(0xFFFBBF24), // Amber
    Color(0xFFF59E0B), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
  ];
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final particle in particles) {
      // Ease out motion
      final easeProgress = Curves.easeOut.transform(progress);

      // Calculate position with gravity
      final x =
          centerX + math.cos(particle.angle) * particle.speed * easeProgress;
      final y = centerY +
          math.sin(particle.angle) * particle.speed * easeProgress +
          (progress * progress * 200); // Gravity

      // Fade out
      final opacity = (1 - progress).clamp(0.0, 1.0);

      // Current rotation
      final currentRotation = particle.rotation + particle.rotationSpeed * progress;

      // Draw particle
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation);

      // Draw star shape
      final path = Path();
      const points = 5;
      for (var i = 0; i < points * 2; i++) {
        final radius = i.isEven ? particle.size : particle.size / 2;
        final angle = (math.pi / points) * i;
        final px = math.cos(angle) * radius;
        final py = math.sin(angle) * radius;

        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Ripple effect for correct answers
class RippleEffect extends StatefulWidget {
  const RippleEffect({
    super.key,
    required this.child,
    this.color = const Color(0xFF10B981),
  });

  final Widget child;
  final Color color;

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _RipplePainter(
                progress: _controller.value,
                color: widget.color,
              ),
              size: const Size(200, 200),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw multiple ripples
    for (var i = 0; i < 3; i++) {
      final rippleProgress = ((progress - i * 0.15).clamp(0.0, 1.0));
      final radius = maxRadius * rippleProgress;
      final opacity = (1 - rippleProgress) * 0.3;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
