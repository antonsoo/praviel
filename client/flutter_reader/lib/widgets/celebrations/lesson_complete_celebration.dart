/// Stunning lesson completion celebration with 2025 design
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';

/// Epic lesson completion celebration modal
class LessonCompleteCelebration extends StatefulWidget {
  const LessonCompleteCelebration({
    super.key,
    required this.xpEarned,
    required this.accuracy,
    required this.wordsLearned,
    required this.languageName,
    this.levelUp = false,
    this.newLevel,
    this.achievementsUnlocked = const [],
    required this.onContinue,
  });

  final int xpEarned;
  final double accuracy;
  final int wordsLearned;
  final String languageName;
  final bool levelUp;
  final int? newLevel;
  final List<String> achievementsUnlocked;
  final VoidCallback onContinue;

  @override
  State<LessonCompleteCelebration> createState() =>
      _LessonCompleteCelebrationState();

  /// Show the celebration modal
  static Future<void> show({
    required BuildContext context,
    required int xpEarned,
    required double accuracy,
    required int wordsLearned,
    required String languageName,
    bool levelUp = false,
    int? newLevel,
    List<String> achievementsUnlocked = const [],
  }) {
    HapticService.heavy();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => LessonCompleteCelebration(
        xpEarned: xpEarned,
        accuracy: accuracy,
        wordsLearned: wordsLearned,
        languageName: languageName,
        levelUp: levelUp,
        newLevel: newLevel,
        achievementsUnlocked: achievementsUnlocked,
        onContinue: () => Navigator.pop(context),
      ),
    );
  }
}

class _LessonCompleteCelebrationState extends State<LessonCompleteCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late ConfettiController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _scaleController.forward();
    _slideController.forward();
    _rotateController.repeat();
    _confettiController.play();

    // Haptic feedback
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) HapticService.heavy();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.15,
            shouldLoop: false,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary,
              Colors.amber,
              Colors.green,
            ],
          ),
        ),

        // Content
        Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: math.min(size.width * 0.9, 500),
                  maxHeight: size.height * 0.85,
                ),
                margin: const EdgeInsets.all(VibrantSpacing.xl),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(VibrantRadius.xxl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 60,
                      spreadRadius: 10,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(VibrantSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy icon
                      RotationTransition(
                        turns: Tween<double>(
                          begin: -0.05,
                          end: 0.05,
                        ).animate(_rotateAnimation),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: VibrantSpacing.xl),

                      // Title
                      Text(
                        widget.levelUp ? 'Level Up!' : 'Lesson Complete!',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: VibrantSpacing.sm),

                      if (widget.levelUp && widget.newLevel != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.lg,
                            vertical: VibrantSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(VibrantRadius.lg),
                          ),
                          child: Text(
                            'Level ${widget.newLevel}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: VibrantSpacing.lg),
                      ],

                      Text(
                        'Great work on ${widget.languageName}!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: VibrantSpacing.xxl),

                      // Stats grid
                      Container(
                        padding: const EdgeInsets.all(VibrantSpacing.xl),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primaryContainer.withValues(alpha: 0.4),
                              colorScheme.secondaryContainer.withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(VibrantRadius.xl),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              context,
                              Icons.stars_rounded,
                              'XP Earned',
                              '+${widget.xpEarned}',
                              colorScheme.primary,
                            ),
                            const SizedBox(height: VibrantSpacing.lg),
                            _buildStatRow(
                              context,
                              Icons.percent_rounded,
                              'Accuracy',
                              '${(widget.accuracy * 100).round()}%',
                              widget.accuracy >= 0.9
                                  ? Colors.green
                                  : widget.accuracy >= 0.7
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                            const SizedBox(height: VibrantSpacing.lg),
                            _buildStatRow(
                              context,
                              Icons.book_rounded,
                              'Words Learned',
                              '${widget.wordsLearned}',
                              colorScheme.tertiary,
                            ),
                          ],
                        ),
                      ),

                      if (widget.achievementsUnlocked.isNotEmpty) ...[
                        const SizedBox(height: VibrantSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(VibrantSpacing.lg),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(VibrantRadius.lg),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    color: colorScheme.tertiary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: VibrantSpacing.sm),
                                  Text(
                                    'New Achievements!',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: VibrantSpacing.sm),
                              ...widget.achievementsUnlocked.map(
                                (achievement) => Padding(
                                  padding: const EdgeInsets.only(
                                    top: VibrantSpacing.xs,
                                  ),
                                  child: Text(
                                    achievement,
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: VibrantSpacing.xxl),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            HapticService.medium();
                            widget.onContinue();
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Continue'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: VibrantSpacing.lg,
                            ),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(VibrantRadius.md),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: VibrantSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
