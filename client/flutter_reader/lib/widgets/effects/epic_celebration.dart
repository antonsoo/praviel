import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../../theme/vibrant_colors.dart';

/// Epic celebration overlay with confetti, particles, and animations
/// Used for major achievements like completing lessons, leveling up, streaks
class EpicCelebration extends StatefulWidget {
  const EpicCelebration({
    super.key,
    required this.type,
    this.message,
    this.onComplete,
    this.customColor,
  });

  final CelebrationType type;
  final String? message;
  final VoidCallback? onComplete;
  final Color? customColor;

  @override
  State<EpicCelebration> createState() => _EpicCelebrationState();
}

class _EpicCelebrationState extends State<EpicCelebration>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: Duration(
        seconds: widget.type == CelebrationType.lessonComplete ? 3 : 5,
      ),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _startCelebration();
  }

  Future<void> _startCelebration() async {
    // Haptic feedback
    await HapticService.heavy();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticService.medium();

    // Sound effect
    switch (widget.type) {
      case CelebrationType.levelUp:
        await SoundService.instance.levelUp();
        break;
      case CelebrationType.streakMilestone:
        await SoundService.instance.streakMilestone();
        break;
      case CelebrationType.achievement:
        await SoundService.instance.achievement();
        break;
      case CelebrationType.lessonComplete:
        await SoundService.instance.success();
        await SoundService.instance.confetti();
        break;
      case CelebrationType.perfectScore:
        await SoundService.instance.achievement();
        await Future.delayed(const Duration(milliseconds: 200));
        await SoundService.instance.confetti();
        break;
    }

    // Start confetti
    _confettiController.play();
    _scaleController.forward();

    // Auto-complete
    Future.delayed(
      widget.type == CelebrationType.lessonComplete
          ? const Duration(seconds: 2)
          : const Duration(seconds: 4),
      () {
        widget.onComplete?.call();
      },
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Stack(
      children: [
        // Background overlay
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),

        // Top confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // Down
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.03,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: config.colors,
            createParticlePath: _createConfettiPath,
          ),
        ),

        // Left confetti
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 0, // Right
            maxBlastForce: 15,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            numberOfParticles: 15,
            gravity: 0.2,
            colors: config.colors,
            createParticlePath: _createConfettiPath,
          ),
        ),

        // Right confetti
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi, // Left
            maxBlastForce: 15,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            numberOfParticles: 15,
            gravity: 0.2,
            colors: config.colors,
            createParticlePath: _createConfettiPath,
          ),
        ),

        // Center message
        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _scaleController,
              curve: Curves.elasticOut,
            ),
            child:
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [config.primaryColor, config.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: VibrantColors.glowShadow(
                          config.primaryColor,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.1),
                                child: Icon(
                                  config.icon,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.message ?? config.defaultMessage,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .shimmer(
                      duration: const Duration(seconds: 2),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
          ),
        ),

        // Sparkles
        ...List.generate(20, (index) {
          return _buildSparkle(index);
        }),
      ],
    );
  }

  Widget _buildSparkle(int index) {
    final random = Random(index);
    final delay = random.nextInt(500);
    final left = random.nextDouble();
    final top = random.nextDouble() * 0.8 + 0.1;
    final size = random.nextDouble() * 8 + 4;
    final duration = random.nextInt(1000) + 1500;

    return Positioned(
          left: MediaQuery.of(context).size.width * left,
          top: MediaQuery.of(context).size.height * top,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: duration),
            builder: (context, value, child) {
              return Opacity(
                opacity: (sin(value * pi * 2) + 1) / 2,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 300),
        );
  }

  Path _createConfettiPath(Size size) {
    final path = Path();
    final random = Random();
    final shapes = [
      // Square
      () {
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      },
      // Circle
      () {
        path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
      },
      // Star
      () {
        final centerX = size.width / 2;
        final centerY = size.height / 2;
        final outerRadius = size.width / 2;
        final innerRadius = size.width / 4;
        final points = 5;

        for (int i = 0; i < points * 2; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = (i * pi) / points - pi / 2;
          final x = centerX + radius * cos(angle);
          final y = centerY + radius * sin(angle);

          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
      },
      // Heart
      () {
        final width = size.width;
        final height = size.height;
        path.moveTo(width / 2, height / 4);
        path.cubicTo(
          width / 2,
          height / 5,
          width / 3,
          0,
          width / 6,
          height / 5,
        );
        path.cubicTo(0, height / 3, 0, height / 2, width / 6, height * 2 / 3);
        path.cubicTo(
          width / 3,
          height * 5 / 6,
          width / 2,
          height,
          width / 2,
          height,
        );
        path.cubicTo(
          width / 2,
          height,
          width * 2 / 3,
          height * 5 / 6,
          width * 5 / 6,
          height * 2 / 3,
        );
        path.cubicTo(
          width,
          height / 2,
          width,
          height / 3,
          width * 5 / 6,
          height / 5,
        );
        path.cubicTo(
          width * 2 / 3,
          0,
          width / 2,
          height / 5,
          width / 2,
          height / 4,
        );
        path.close();
      },
    ];

    shapes[random.nextInt(shapes.length)]();
    return path;
  }

  _CelebrationConfig _getConfig() {
    switch (widget.type) {
      case CelebrationType.levelUp:
        return _CelebrationConfig(
          icon: Icons.military_tech,
          defaultMessage: 'Level Up!',
          primaryColor: widget.customColor ?? VibrantColors.xpGold,
          secondaryColor: VibrantColors.xpBronze,
          colors: [
            VibrantColors.xpGold,
            VibrantColors.xpSilver,
            VibrantColors.xpBronze,
            VibrantColors.warning,
          ],
        );
      case CelebrationType.streakMilestone:
        return _CelebrationConfig(
          icon: Icons.local_fire_department,
          defaultMessage: 'Streak Milestone!',
          primaryColor: widget.customColor ?? VibrantColors.streakFire,
          secondaryColor: VibrantColors.streakFlame,
          colors: [
            VibrantColors.streakFire,
            VibrantColors.streakFlame,
            VibrantColors.streakHot,
            VibrantColors.warning,
          ],
        );
      case CelebrationType.achievement:
        return _CelebrationConfig(
          icon: Icons.emoji_events,
          defaultMessage: 'Achievement Unlocked!',
          primaryColor: widget.customColor ?? VibrantColors.achievement,
          secondaryColor: VibrantColors.warning,
          colors: [
            VibrantColors.achievement,
            VibrantColors.warning,
            VibrantColors.secondary,
            VibrantColors.xpGold,
          ],
        );
      case CelebrationType.lessonComplete:
        return _CelebrationConfig(
          icon: Icons.check_circle,
          defaultMessage: 'Lesson Complete!',
          primaryColor: widget.customColor ?? VibrantColors.success,
          secondaryColor: VibrantColors.successLight,
          colors: [
            VibrantColors.success,
            VibrantColors.successLight,
            VibrantColors.primary,
            VibrantColors.secondary,
          ],
        );
      case CelebrationType.perfectScore:
        return _CelebrationConfig(
          icon: Icons.stars,
          defaultMessage: 'Perfect Score!',
          primaryColor: widget.customColor ?? VibrantColors.xpGold,
          secondaryColor: VibrantColors.warning,
          colors: [
            VibrantColors.xpGold,
            VibrantColors.warning,
            VibrantColors.achievement,
            VibrantColors.xpSilver,
          ],
        );
    }
  }
}

enum CelebrationType {
  levelUp,
  streakMilestone,
  achievement,
  lessonComplete,
  perfectScore,
}

class _CelebrationConfig {
  final IconData icon;
  final String defaultMessage;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> colors;

  _CelebrationConfig({
    required this.icon,
    required this.defaultMessage,
    required this.primaryColor,
    required this.secondaryColor,
    required this.colors,
  });
}

/// Quick celebration for smaller achievements
class QuickCelebration extends StatelessWidget {
  const QuickCelebration({
    super.key,
    required this.icon,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color ?? VibrantColors.primary,
                (color ?? VibrantColors.primary).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: VibrantColors.glowShadow(color ?? VibrantColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 600),
        )
        .shimmer(
          duration: const Duration(milliseconds: 1000),
          color: Colors.white.withValues(alpha: 0.3),
        );
  }
}
