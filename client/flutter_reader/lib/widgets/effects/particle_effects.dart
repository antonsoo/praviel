import 'dart:math';
import 'package:flutter/material.dart';

/// Star burst effect for achievements
class StarBurst extends StatefulWidget {
  const StarBurst({
    super.key,
    this.color = const Color(0xFFFBBF24),
    this.particleCount = 20,
    this.size = 200,
  });

  final Color color;
  final int particleCount;
  final double size;

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_StarParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create star particles
    for (int i = 0; i < widget.particleCount; i++) {
      final angle = (2 * pi * i) / widget.particleCount;
      _particles.add(
        _StarParticle(
          angle: angle,
          speed: 0.3 + _random.nextDouble() * 0.4,
          size: 4 + _random.nextDouble() * 8,
          delay: _random.nextDouble() * 0.2,
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _StarBurstPainter(
              particles: _particles,
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _StarParticle {
  _StarParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
  });

  final double angle;
  final double speed;
  final double size;
  final double delay;
}

class _StarBurstPainter extends CustomPainter {
  _StarBurstPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  final List<_StarParticle> particles;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      // Apply delay
      final adjustedProgress =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);

      if (adjustedProgress <= 0) continue;

      // Calculate position
      final distance = adjustedProgress * size.width * 0.4 * particle.speed;
      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;

      // Fade out
      final opacity = (1 - adjustedProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw star
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.angle);
      _drawStar(canvas, paint, particle.size * (1 - adjustedProgress * 0.5));
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final radius = i.isEven ? size : size / 2;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
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
  bool shouldRepaint(_StarBurstPainter oldDelegate) => true;
}

/// Sparkle trail effect for dragging
class SparkleTrail extends StatefulWidget {
  const SparkleTrail({
    super.key,
    required this.position,
    this.color = const Color(0xFFFBBF24),
  });

  final Offset position;
  final Color color;

  @override
  State<SparkleTrail> createState() => _SparkleTrailState();
}

class _SparkleTrailState extends State<SparkleTrail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Sparkle> _sparkles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    // Add sparkles periodically
    _controller.addListener(() {
      if (_controller.value < 0.1) {
        setState(() {
          _sparkles.add(
            _Sparkle(
              position: widget.position,
              startTime: _controller.value,
              size: 2 + _random.nextDouble() * 4,
              velocity: Offset(
                _random.nextDouble() * 20 - 10,
                _random.nextDouble() * 20 - 10,
              ),
            ),
          );

          // Remove old sparkles
          _sparkles.removeWhere((s) => (_controller.value - s.startTime) > 0.8);
        });
      }
    });
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
          painter: _SparkleTrailPainter(
            sparkles: _sparkles,
            currentTime: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _Sparkle {
  _Sparkle({
    required this.position,
    required this.startTime,
    required this.size,
    required this.velocity,
  });

  final Offset position;
  final double startTime;
  final double size;
  final Offset velocity;
}

class _SparkleTrailPainter extends CustomPainter {
  _SparkleTrailPainter({
    required this.sparkles,
    required this.currentTime,
    required this.color,
  });

  final List<_Sparkle> sparkles;
  final double currentTime;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final elapsed = currentTime - sparkle.startTime;
      if (elapsed < 0 || elapsed > 0.8) continue;

      final progress = elapsed / 0.8;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      final x = sparkle.position.dx + sparkle.velocity.dx * progress;
      final y = sparkle.position.dy + sparkle.velocity.dy * progress;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        sparkle.size * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkleTrailPainter oldDelegate) => true;
}

/// Coin rain effect for rewards
class CoinRain extends StatefulWidget {
  const CoinRain({
    super.key,
    required this.coinCount,
    this.duration = const Duration(milliseconds: 2000),
  });

  final int coinCount;
  final Duration duration;

  @override
  State<CoinRain> createState() => _CoinRainState();
}

class _CoinRainState extends State<CoinRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Coin> _coins = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Create coins
    for (int i = 0; i < widget.coinCount; i++) {
      _coins.add(
        _Coin(
          startX: _random.nextDouble(),
          delay: _random.nextDouble() * 0.3,
          rotationSpeed: _random.nextDouble() * 4 - 2,
          wobble: _random.nextDouble() * 0.1 - 0.05,
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _CoinRainPainter(
                coins: _coins,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Coin {
  _Coin({
    required this.startX,
    required this.delay,
    required this.rotationSpeed,
    required this.wobble,
  });

  final double startX;
  final double delay;
  final double rotationSpeed;
  final double wobble;
}

class _CoinRainPainter extends CustomPainter {
  _CoinRainPainter({required this.coins, required this.progress});

  final List<_Coin> coins;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      final adjustedProgress = ((progress - coin.delay) / (1 - coin.delay))
          .clamp(0.0, 1.0);

      if (adjustedProgress <= 0) continue;

      // Calculate position
      final x =
          (coin.startX + sin(adjustedProgress * pi * 2) * coin.wobble) *
          size.width;
      final y = adjustedProgress * size.height;

      // Rotation
      final rotation = adjustedProgress * coin.rotationSpeed * 2 * pi;

      // Draw coin
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Coin gradient
      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ).createShader(const Rect.fromLTWH(-12, -12, 24, 24));

      // Coin shape
      canvas.drawCircle(Offset.zero, 12, paint);

      // Shine
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(-4, -4), 4, shinePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CoinRainPainter oldDelegate) => true;
}

/// Ripple wave effect on tap
class RippleWave extends StatefulWidget {
  const RippleWave({
    super.key,
    required this.position,
    this.color = const Color(0xFF7C3AED),
    this.maxRadius = 100,
  });

  final Offset position;
  final Color color;
  final double maxRadius;

  @override
  State<RippleWave> createState() => _RippleWaveState();
}

class _RippleWaveState extends State<RippleWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
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
        final radius = _controller.value * widget.maxRadius;
        final opacity = 1 - _controller.value;

        return CustomPaint(
          painter: _RippleWavePainter(
            position: widget.position,
            radius: radius,
            color: widget.color.withValues(alpha: opacity * 0.3),
          ),
        );
      },
    );
  }
}

class _RippleWavePainter extends CustomPainter {
  _RippleWavePainter({
    required this.position,
    required this.radius,
    required this.color,
  });

  final Offset position;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(_RippleWavePainter oldDelegate) => true;
}

/// Glow pulse effect for power-ups
class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.child,
    this.color = const Color(0xFF7C3AED),
    this.glowSize = 20,
  });

  final Widget child;
  final Color color;
  final double glowSize;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 * _controller.value),
                blurRadius: widget.glowSize * _controller.value,
                spreadRadius: widget.glowSize * 0.5 * _controller.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
