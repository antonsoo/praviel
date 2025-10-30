import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/haptic_service.dart';

/// Full-screen overlay that shows when user levels up
/// Displays celebration animation, new level, and rewards
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    required this.onDismiss,
  });

  final int oldLevel;
  final int newLevel;
  final VoidCallback onDismiss;

  /// Show the level-up overlay as a modal dialog
  static Future<void> show({
    required BuildContext context,
    required int oldLevel,
    required int newLevel,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => LevelUpOverlay(
        oldLevel: oldLevel,
        newLevel: newLevel,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Haptic feedback
    HapticService.celebrate();

    // Scale animation for the level badge
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Rotation animation for rays
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Particle explosion animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.forward();
        _particleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Animated rays background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RaysPainter(
                      rotation: _rotationAnimation.value,
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  );
                },
              ),
            ),

            // Particle explosion
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlesPainter(
                      progress: _particleController.value,
                      color: Colors.amber,
                    ),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "LEVEL UP!" text
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.amber.shade300,
                          Colors.orange.shade400,
                          Colors.amber.shade300,
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'LEVEL UP!',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Level badge with scale animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.orange.shade500,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LEVEL',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.newLevel}',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 72,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Level title
                  Text(
                    _getLevelTitle(widget.newLevel),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Continue button
                  ElevatedButton(
                    onPressed: () {
                      HapticService.light();
                      widget.onDismiss();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CONTINUE',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black87,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level <= 5) return 'Novice Scholar';
    if (level <= 10) return 'Apprentice Linguist';
    if (level <= 20) return 'Scholar of the Ancients';
    if (level <= 30) return 'Master of Dead Tongues';
    if (level <= 50) return 'Keeper of Ancient Wisdom';
    return 'Living Library';
  }
}

/// Custom painter for animated rays
class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.rotation, required this.color});

  final double rotation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Draw 12 rays
    for (int i = 0; i < 12; i++) {
      final angle = (2 * math.pi / 12) * i;
      canvas.save();
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(30, -maxRadius)
        ..lineTo(-30, -maxRadius)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

/// Custom painter for particle explosion
class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 1.0 - progress)
      ..style = PaintingStyle.fill;

    // Draw 30 particles
    for (int i = 0; i < 30; i++) {
      final angle = (2 * math.pi / 30) * i;
      final distance = progress * 300;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      final radius = 8 * (1 - progress);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
