import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Advanced particle system for celebrations (2025 gamification UX)
class AdvancedConfettiExplosion extends StatefulWidget {
  const AdvancedConfettiExplosion({
    super.key,
    required this.child,
    this.trigger = false,
    this.particleCount = 50,
    this.colors,
  });

  final Widget child;
  final bool trigger;
  final int particleCount;
  final List<Color>? colors;

  @override
  State<AdvancedConfettiExplosion> createState() =>
      _AdvancedConfettiExplosionState();
}

class _AdvancedConfettiExplosionState extends State<AdvancedConfettiExplosion> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void didUpdateWidget(AdvancedConfettiExplosion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.play();
    }
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
        widget.child,
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: widget.particleCount,
            gravity: 0.1,
            colors: widget.colors ??
                const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                ],
          ),
        ),
      ],
    );
  }
}

/// Particle burst for XP gain animations
class XPBurst extends StatefulWidget {
  const XPBurst({
    super.key,
    required this.xpAmount,
    required this.position,
    this.onComplete,
  });

  final int xpAmount;
  final Offset position;
  final VoidCallback? onComplete;

  @override
  State<XPBurst> createState() => _XPBurstState();
}

class _XPBurstState extends State<XPBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -100),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: _positionAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    '+${widget.xpAmount} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Floating particles background effect
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({
    super.key,
    this.particleCount = 20,
    this.particleColor,
  });

  final int particleCount;
  final Color? particleColor;

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle(
        Random().nextDouble(),
        Random().nextDouble(),
        Random().nextDouble() * 2 + 1,
        Random().nextDouble() * 0.5 + 0.3,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.particleColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _controller.value,
            color: color,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  _Particle(this.x, this.y, this.size, this.speed);

  final double x;
  final double y;
  final double size;
  final double speed;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  final List<_Particle> particles;
  final double animationValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = ((particle.y + animationValue * particle.speed) % 1.0) *
          size.height;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

/// Achievement unlock burst effect
class AchievementBurst extends StatefulWidget {
  const AchievementBurst({
    super.key,
    required this.show,
    this.onComplete,
  });

  final bool show;
  final VoidCallback? onComplete;

  @override
  State<AchievementBurst> createState() => _AchievementBurstState();
}

class _AchievementBurstState extends State<AchievementBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didUpdateWidget(AchievementBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0).then((_) {
        widget.onComplete?.call();
      });
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return Stack(
      children: [
        // Golden rays
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _RaysPainter(
                animationValue: _controller.value,
                color: Colors.amber.withValues(alpha: 0.3),
              ),
              child: Container(),
            );
          },
        ),
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            particleDrag: 0.05,
            emissionFrequency: 0.02,
            numberOfParticles: 100,
            gravity: 0.3,
            colors: const [
              Colors.amber,
              Colors.orange,
              Colors.yellow,
              Colors.red,
            ],
          ),
        ),
      ],
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.animationValue, required this.color});

  final double animationValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final rayCount = 12;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * pi + animationValue * 2 * pi;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + cos(angle) * size.width,
          center.dy + sin(angle) * size.height,
        )
        ..lineTo(
          center.dx + cos(angle + 0.1) * size.width,
          center.dy + sin(angle + 0.1) * size.height,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => true;
}
