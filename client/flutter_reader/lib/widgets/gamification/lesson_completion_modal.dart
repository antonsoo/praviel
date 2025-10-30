import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../effects/confetti_overlay.dart';
import 'xp_counter.dart';

/// Celebration modal shown when lesson is completed
class LessonCompletionModal extends StatefulWidget {
  const LessonCompletionModal({
    super.key,
    required this.xpGained,
    required this.correctCount,
    required this.totalQuestions,
    required this.currentLevel,
    required this.progressToNextLevel,
    required this.xpToNextLevel,
    this.duration,
    this.isNewLevel = false,
    this.achievementsUnlocked = const [],
    this.onContinue,
    this.onReview,
  });

  final int xpGained;
  final int correctCount;
  final int totalQuestions;
  final int currentLevel;
  final double progressToNextLevel;
  final int xpToNextLevel;
  final Duration? duration;
  final bool isNewLevel;
  final List<Achievement> achievementsUnlocked;
  final VoidCallback? onContinue;
  final VoidCallback? onReview;

  static Future<void> show({
    required BuildContext context,
    required int xpGained,
    required int correctCount,
    required int totalQuestions,
    required int currentLevel,
    required double progressToNextLevel,
    required int xpToNextLevel,
    Duration? duration,
    bool isNewLevel = false,
    List<Achievement> achievementsUnlocked = const [],
    VoidCallback? onContinue,
    VoidCallback? onReview,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LessonCompletionModal(
        xpGained: xpGained,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        currentLevel: currentLevel,
        progressToNextLevel: progressToNextLevel,
        xpToNextLevel: xpToNextLevel,
        duration: duration,
        isNewLevel: isNewLevel,
        achievementsUnlocked: achievementsUnlocked,
        onContinue: onContinue,
        onReview: onReview,
      ),
    );
  }

  @override
  State<LessonCompletionModal> createState() => _LessonCompletionModalState();
}

class _LessonCompletionModalState extends State<LessonCompletionModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.15),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.15, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _scaleController,
            curve: VibrantCurve.playful,
          ),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _scaleController.forward();

    // Trigger confetti after modal appears
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showConfetti = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accuracy = (widget.correctCount / widget.totalQuestions * 100)
        .round();
    final isPerfect = accuracy == 100;

    return ConfettiOverlay(
      isActive: _showConfetti,
      particleCount: isPerfect ? 80 : 50,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(VibrantSpacing.xxl),
              decoration: BoxDecoration(
                gradient: widget.isNewLevel
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.surface,
                        ],
                      )
                    : null,
                color: widget.isNewLevel ? null : colorScheme.surface,
                borderRadius: BorderRadius.circular(VibrantRadius.xxl),
                boxShadow: VibrantShadow.xl(colorScheme),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star/Trophy icon
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: isPerfect
                          ? VibrantTheme.successGradient
                          : VibrantTheme.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isPerfect
                                      ? const Color(0xFF10B981)
                                      : colorScheme.primary)
                                  .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPerfect
                          ? Icons.emoji_events_rounded
                          : widget.isNewLevel
                          ? Icons.auto_awesome_rounded
                          : Icons.star_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: VibrantSpacing.lg),

                  // Title
                  Text(
                    widget.isNewLevel
                        ? 'Level Up!'
                        : isPerfect
                        ? 'Perfect!'
                        : 'Lesson Complete!',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: VibrantSpacing.xs),

                  if (widget.isNewLevel)
                    Text(
                      'You reached Level ${widget.currentLevel}!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: VibrantSpacing.xl),

                  // XP Gained
                  XPGainBadge(xpGained: widget.xpGained),

                  const SizedBox(height: VibrantSpacing.xl),

                  // Stats container
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                              icon: Icons.check_circle_rounded,
                              label: 'Accuracy',
                              value: '$accuracy%',
                              color: accuracy >= 80
                                  ? colorScheme.tertiary
                                  : colorScheme.onSurface,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: colorScheme.outline,
                            ),
                            _StatItem(
                              icon: Icons.quiz_rounded,
                              label: 'Correct',
                              value:
                                  '${widget.correctCount}/${widget.totalQuestions}',
                            ),
                            if (widget.duration != null) ...[
                              Container(
                                width: 1,
                                height: 40,
                                color: colorScheme.outline,
                              ),
                              _StatItem(
                                icon: Icons.timer_rounded,
                                label: 'Time',
                                value: _formatDuration(widget.duration!),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: VibrantSpacing.lg),

                  // Progress to next level
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level ${widget.currentLevel}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${widget.xpToNextLevel} XP to Level ${widget.currentLevel + 1}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VibrantSpacing.sm),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: widget.progressToNextLevel.clamp(
                                0.0,
                                1.0,
                              ),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: VibrantTheme.xpGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Achievements unlocked
                  if (widget.achievementsUnlocked.isNotEmpty) ...[
                    const SizedBox(height: VibrantSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: VibrantSpacing.sm),
                          Expanded(
                            child: Text(
                              '${widget.achievementsUnlocked.length} new achievement${widget.achievementsUnlocked.length == 1 ? '' : 's'} unlocked!',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: VibrantSpacing.xl),

                  // Action buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onContinue?.call();
                        },
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: const Text('Continue Learning'),
                      ),
                      if (widget.onReview != null) ...[
                        const SizedBox(height: VibrantSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onReview?.call();
                          },
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Review'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayColor = color ?? colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: displayColor),
        const SizedBox(height: VibrantSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: displayColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Level up celebration - separate, more dramatic
class LevelUpModal extends StatefulWidget {
  const LevelUpModal({super.key, required this.newLevel, this.onContinue});

  final int newLevel;
  final VoidCallback? onContinue;

  static Future<void> show({
    required BuildContext context,
    required int newLevel,
    VoidCallback? onContinue,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          LevelUpModal(newLevel: newLevel, onContinue: onContinue),
    );
  }

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.epic,
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.95), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: VibrantCurve.playful),
        );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // Trigger confetti immediately for level ups
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showConfetti = true;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConfettiOverlay(
      isActive: _showConfetti,
      particleCount: 100,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(VibrantSpacing.xxl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(VibrantRadius.xxl),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated level badge
              ScaleTransition(
                scale: _scaleAnimation,
                child: RotationTransition(
                  turns: _rotateAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.newLevel.toString(),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              Text(
                'LEVEL UP!',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 48,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: VibrantSpacing.md),

              Text(
                'You\'ve reached Level ${widget.newLevel}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: VibrantSpacing.xxl),

              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onContinue?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                ),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
