import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';

/// Premium celebration animations for achievements and milestones
/// Inspired by modern gamification apps

/// Confetti burst animation
/// Shows colorful confetti falling from the top
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.isActive,
    this.particleCount = 50,
    this.colors,
    this.duration = const Duration(milliseconds: 3000),
    this.onComplete,
  });

  final bool isActive;
  final int particleCount;
  final List<Color>? colors;
  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeParticles();
      _controller.forward(from: 0.0);
      HapticService.celebrate();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    final effectiveColors = widget.colors ??
        [
          VibrantTheme.xpGradient.colors.first,
          VibrantTheme.streakGradient.colors.first,
          VibrantTheme.successGradient.colors.first,
          VibrantTheme.premiumGradient.colors.first,
          VibrantTheme.violetGradient.colors.first,
          Colors.pink,
          Colors.cyan,
        ];

    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_ConfettiParticle(
        color: effectiveColors[random.nextInt(effectiveColors.length)],
        startX: random.nextDouble(),
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * 0.5 + 0.5,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 4,
        shape: random.nextInt(3),
      ));
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
        return IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: _particles.map((particle) {
                  final progress = _controller.value;
                  final x = constraints.maxWidth *
                      (particle.startX + particle.velocityX * progress);
                  final y = constraints.maxHeight *
                      (progress * particle.velocityY + progress * progress * 0.5);

                  return Positioned(
                    left: x,
                    top: y,
                    child: Transform.rotate(
                      angle: particle.rotation + particle.rotationSpeed * progress,
                      child: Opacity(
                        opacity: (1.0 - progress).clamp(0.0, 1.0),
                        child: _buildParticle(particle),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildParticle(_ConfettiParticle particle) {
    switch (particle.shape) {
      case 0: // Circle
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
          ),
        );
      case 1: // Square
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: particle.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 2: // Rectangle
        return Container(
          width: 12,
          height: 6,
          decoration: BoxDecoration(
            color: particle.color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.color,
    required this.startX,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });

  final Color color;
  final double startX;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final int shape;
}

/// Star burst animation - for achievements
class StarBurst extends StatefulWidget {
  const StarBurst({
    super.key,
    required this.isActive,
    this.starCount = 8,
    this.color,
    this.size = 200,
    this.onComplete,
  });

  final bool isActive;
  final int starCount;
  final Color? color;
  final double size;
  final VoidCallback? onComplete;

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: math.pi / 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(StarBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
      HapticService.celebrate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IgnorePointer(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(widget.starCount, (index) {
                final angle = (2 * math.pi * index) / widget.starCount;
                final distance = widget.size * 0.4 * _expandAnimation.value;
                final xOffset = distance * math.cos(angle);
                final yOffset = distance * math.sin(angle);

                return Transform.translate(
                  offset: Offset(xOffset, yOffset),
                  child: Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Icon(
                        Icons.star_rounded,
                        size: 24,
                        color: effectiveColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// Firework explosion effect
class FireworkExplosion extends StatefulWidget {
  const FireworkExplosion({
    super.key,
    required this.isActive,
    this.color,
    this.particleCount = 20,
    this.onComplete,
  });

  final bool isActive;
  final Color? color;
  final int particleCount;
  final VoidCallback? onComplete;

  @override
  State<FireworkExplosion> createState() => _FireworkExplosionState();
}

class _FireworkExplosionState extends State<FireworkExplosion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(FireworkExplosion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
      HapticService.heavy();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IgnorePointer(
          child: CustomPaint(
            size: const Size(300, 300),
            painter: _FireworkPainter(
              progress: _expandAnimation.value,
              opacity: _fadeAnimation.value,
              color: effectiveColor,
              particleCount: widget.particleCount,
            ),
          ),
        );
      },
    );
  }
}

class _FireworkPainter extends CustomPainter {
  _FireworkPainter({
    required this.progress,
    required this.opacity,
    required this.color,
    required this.particleCount,
  });

  final double progress;
  final double opacity;
  final Color color;
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;

    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * math.pi * i) / particleCount;
      final radius = maxRadius * progress;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Draw particle trail
      final trailStart = Offset(
        center.dx + (radius * 0.7) * math.cos(angle),
        center.dy + (radius * 0.7) * math.sin(angle),
      );

      canvas.drawLine(trailStart, endPoint, paint);

      // Draw particle dot
      canvas.drawCircle(endPoint, 3, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(_FireworkPainter oldDelegate) {
    return progress != oldDelegate.progress || opacity != oldDelegate.opacity;
  }
}

/// Success checkmark animation
class SuccessCheckmark extends StatefulWidget {
  const SuccessCheckmark({
    super.key,
    required this.isActive,
    this.color,
    this.size = 80,
    this.strokeWidth = 4.0,
    this.onComplete,
  });

  final bool isActive;
  final Color? color;
  final double size;
  final double strokeWidth;
  final VoidCallback? onComplete;

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(SuccessCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
      HapticService.success();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? VibrantTheme.successGradient.colors.first;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _CheckmarkPainter(
                progress: _checkAnimation.value,
                color: effectiveColor,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw circle background
    final circleCenter = Offset(size.width / 2, size.height / 2);
    final circleRadius = size.width / 2;
    canvas.drawCircle(
      circleCenter,
      circleRadius,
      paint..color = color.withValues(alpha: 0.2)..style = PaintingStyle.fill,
    );

    paint
      ..color = color
      ..style = PaintingStyle.stroke;

    // Draw checkmark
    final path = Path();
    final p1 = Offset(size.width * 0.25, size.height * 0.5);
    final p2 = Offset(size.width * 0.45, size.height * 0.7);
    final p3 = Offset(size.width * 0.75, size.height * 0.3);

    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);

    if (progress > 0.5) {
      final secondLineProgress = (progress - 0.5) * 2;
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * secondLineProgress,
        p2.dy + (p3.dy - p2.dy) * secondLineProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
