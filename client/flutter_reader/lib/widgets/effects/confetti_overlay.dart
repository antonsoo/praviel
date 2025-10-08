import 'dart:math';
import 'package:flutter/material.dart';

/// Confetti particle overlay for celebrations
/// Can be used as a wrapper or standalone fullscreen overlay
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    this.child,
    this.isActive = false,
    this.particleCount = 100,
    this.duration = const Duration(milliseconds: 4000),
    this.colors,
    super.key,
  });

  final Widget? child;
  final bool isActive;
  final int particleCount;
  final Duration duration;
  final List<Color>? colors;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Auto-start if active on init
    if (widget.isActive) {
      Future.microtask(() => _explode());
    }

    _controller.addListener(() {
      setState(() {
        for (final particle in _particles) {
          particle.update(_controller.value);
        }
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _explode();
    }
  }

  void _explode() {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_ConfettiParticle(
        color: _randomColor(),
        startX: 0.5,
        startY: 0.5,
        velocityX: _random.nextDouble() * 2 - 1,
        velocityY: _random.nextDouble() * -2 - 0.5,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: _random.nextDouble() * 4 - 2,
        size: _random.nextDouble() * 8 + 4,
      ));
    }
    _controller.forward(from: 0);
  }

  Color _randomColor() {
    final colorList = widget.colors ?? [
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFFF6B35), // Orange
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFEF4444), // Red
      const Color(0xFFFBBF24), // Yellow
    ];
    return colorList[_random.nextInt(colorList.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fullscreen mode if no child
    if (widget.child == null) {
      return Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(_particles),
          ),
        ),
      );
    }

    // Wrapper mode
    return Stack(
      children: [
        widget.child!,
        if (widget.isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(_particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
  });

  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double size;

  double x = 0.5;
  double y = 0.5;
  double currentRotation = 0;
  double opacity = 1.0;

  void update(double progress) {
    // Physics simulation
    final gravity = 0.5;
    final drag = 0.98;

    x = startX + velocityX * progress * drag;
    y = startY + velocityY * progress + gravity * progress * progress;
    currentRotation = rotation + rotationSpeed * progress;
    opacity = (1 - progress).clamp(0.0, 1.0);
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles);

  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        particle.x * size.width,
        particle.y * size.height,
      );
      canvas.rotate(particle.currentRotation);

      // Draw confetti as small rectangles
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

/// Trigger confetti explosion programmatically
class ConfettiController extends ChangeNotifier {
  bool _isActive = false;

  bool get isActive => _isActive;

  void explode() {
    _isActive = true;
    notifyListeners();

    // Auto-reset after animation completes
    Future.delayed(const Duration(milliseconds: 2500), () {
      _isActive = false;
      notifyListeners();
    });
  }
}
