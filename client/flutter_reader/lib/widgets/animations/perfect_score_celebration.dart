import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

/// Epic celebration animation for perfect scores (100%)
/// Shows golden confetti, sparkles, and achievement badge
class PerfectScoreCelebration extends StatefulWidget {
  const PerfectScoreCelebration({
    required this.onDismiss,
    this.xpBonus = 50,
    super.key,
  });

  final VoidCallback onDismiss;
  final int xpBonus;

  @override
  State<PerfectScoreCelebration> createState() =>
      _PerfectScoreCelebrationState();
}

class _PerfectScoreCelebrationState extends State<PerfectScoreCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _sparkleController;
  late ConfettiController _confettiController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    _slideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();
    _confettiController.play();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _mainController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark overlay with fade in
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withValues(
                  alpha: 0.75 * _fadeAnimation.value,
                ),
              );
            },
          ),

          // Golden confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2, // Down
              maxBlastForce: 20,
              minBlastForce: 10,
              emissionFrequency: 0.03,
              numberOfParticles: 25,
              gravity: 0.3,
              colors: [
                Colors.amber,
                Colors.yellow,
                Colors.orange,
                const Color(0xFFFFD700), // Gold color
              ],
            ),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fadeAnimation,
                _scaleAnimation,
                _slideAnimation,
              ]),
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Perfect score badge with sparkles
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating sparkle effect
                              AnimatedBuilder(
                                animation: _sparkleController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle:
                                        _sparkleController.value * 2 * math.pi,
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 120,
                                      color: Colors.amber.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Main badge
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.amber.shade300,
                                      Colors.orange.shade400,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 15,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // "PERFECT!" text with gradient
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.yellow.shade200,
                                  Colors.amber.shade400,
                                  Colors.orange.shade400,
                                  Colors.amber.shade400,
                                  Colors.yellow.shade200,
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'PERFECT!',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 100% score
                          Text(
                            '100%',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Bonus XP badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade700,
                                  Colors.blue.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${widget.xpBonus} Bonus XP!',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Tap to continue
                          Text(
                            'Tap anywhere to continue',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Tap anywhere to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.translucent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the perfect score celebration as an overlay
void showPerfectScoreCelebration(BuildContext context, {int xpBonus = 50}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => PerfectScoreCelebration(
      xpBonus: xpBonus,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}
