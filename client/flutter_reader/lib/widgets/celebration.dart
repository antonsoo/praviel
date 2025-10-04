import 'dart:math';

import 'package:flutter/material.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Generate particles (increased from 50 to 200)
    for (int i = 0; i < 200; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: 0.3 + _random.nextDouble() * 0.2,
        vx: (_random.nextDouble() - 0.5) * 0.6,
        vy: -(_random.nextDouble() * 0.4 + 0.25),
        color: _randomColor(),
        size: _random.nextDouble() * 10 + 5,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 5,
      ));
    }

    _controller.forward().then((_) => widget.onComplete());
  }

  Color _randomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[_random.nextInt(colors.length)];
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
          painter: _CelebrationPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  double x;
  double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Update position
      final px = (particle.x + particle.vx * progress) * size.width;
      final py = (particle.y + particle.vy * progress + 0.5 * progress * progress) * size.height;

      // Update rotation
      final rotation = particle.rotation + particle.rotationSpeed * progress;

      // Fade out near end
      final opacity = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);

      paint.color = particle.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);

      // Draw confetti piece (rectangle)
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) => true;
}
