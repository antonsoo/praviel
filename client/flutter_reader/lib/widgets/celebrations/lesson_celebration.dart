import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// World-class lesson completion celebration with confetti and animations
/// Inspired by modern language learning app success animations
class LessonCelebration extends StatefulWidget {
  const LessonCelebration({
    required this.onComplete,
    this.xpEarned = 0,
    this.streakDays = 0,
    this.perfectScore = false,
    super.key,
  });

  final VoidCallback onComplete;
  final int xpEarned;
  final int streakDays;
  final bool perfectScore;

  @override
  State<LessonCelebration> createState() => _LessonCelebrationState();
}

class _LessonCelebrationState extends State<LessonCelebration>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start celebration sequence
    _startCelebration();
  }

  Future<void> _startCelebration() async {
    // Fire confetti immediately
    _confettiController.play();

    // Animate trophy
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    // Show stats
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _showStats = true);
    }

    // Auto-dismiss after 4 seconds
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Down
              emissionFrequency: 0.02,
              numberOfParticles: 30,
              maxBlastForce: 100,
              minBlastForce: 50,
              gravity: 0.3,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                Colors.yellow,
                Colors.orange,
                Colors.pink,
              ],
            ),
          ),

          // Main content
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon with scale animation
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _scaleController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.yellow.shade300,
                            Colors.orange.shade400,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.perfectScore
                            ? Icons.emoji_events
                            : Icons.check_circle,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    widget.perfectScore
                        ? 'Perfect! 🎉'
                        : 'Lesson Complete!',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  // Stats cards
                  if (_showStats) ...[
                    _buildStatCard(
                      context,
                      icon: Icons.stars,
                      label: 'XP Earned',
                      value: '+${widget.xpEarned}',
                      color: Colors.purple,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 300.ms)
                        .slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 12),
                    if (widget.streakDays > 0)
                      _buildStatCard(
                        context,
                        icon: Icons.local_fire_department,
                        label: 'Streak',
                        value: '${widget.streakDays} days',
                        color: Colors.orange,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms)
                          .slideX(begin: 0.2, end: 0),
                  ],

                  const SizedBox(height: 32),

                  // Continue button
                  FilledButton(
                    onPressed: widget.onComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 300.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick success animation for correct answers
class QuickSuccessAnimation extends StatelessWidget {
  const QuickSuccessAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withValues(alpha: 0.2),
      ),
      child: const Icon(
        Icons.check_circle,
        size: 50,
        color: Colors.green,
      ),
    )
        .animate()
        .scale(
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeOut(delay: 800.ms, duration: 200.ms);
  }
}

/// Show celebration overlay
Future<void> showLessonCelebration(
  BuildContext context, {
  int xpEarned = 0,
  int streakDays = 0,
  bool perfectScore = false,
}) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) => LessonCelebration(
        xpEarned: xpEarned,
        streakDays: streakDays,
        perfectScore: perfectScore,
        onComplete: () => Navigator.of(context).pop(),
      ),
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}
