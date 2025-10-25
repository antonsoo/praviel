import 'package:flutter/material.dart';

import '../../models/language.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/vibrant_theme.dart';
import '../common/aurora_background.dart';
import '../gamification/xp_counter.dart';
import '../glassmorphism_card.dart';

class VibrantLessonHeader extends StatefulWidget {
  const VibrantLessonHeader({
    super.key,
    required this.language,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.progress,
    required this.xpEarned,
    required this.combo,
    required this.showCombo,
    required this.elapsed,
    required this.onClose,
  });

  final LanguageInfo language;
  final int currentQuestion;
  final int totalQuestions;
  final int correctAnswers;
  final double progress;
  final int xpEarned;
  final int combo;
  final bool showCombo;
  final Duration elapsed;
  final VoidCallback onClose;

  @override
  State<VibrantLessonHeader> createState() => _VibrantLessonHeaderState();
}

class _VibrantLessonHeaderState extends State<VibrantLessonHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _auroraController;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = widget.progress.isNaN
        ? 0.0
        : widget.progress.clamp(0.0, 1.0).toDouble();
    final accuracy = widget.currentQuestion == 0
        ? null
        : (widget.correctAnswers / widget.currentQuestion).clamp(0.0, 1.0);
    final elapsedMinutes = widget.elapsed.inMinutes;
    final elapsedSeconds = widget.elapsed.inSeconds % 60;
    final elapsedLabel =
        '${elapsedMinutes.toString().padLeft(2, '0')}:${elapsedSeconds.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        gradient: VibrantTheme.midnightGradient,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            AuroraBackground(controller: _auroraController),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.lg,
                  vertical: VibrantSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _GlassIconButton(
                          icon: Icons.close_rounded,
                          onTap: widget.onClose,
                        ),
                        const SizedBox(width: VibrantSpacing.sm),
                        _LanguageChip(language: widget.language),
                        const Spacer(),
                        _TimerBadge(label: elapsedLabel),
                        if (widget.showCombo) ...[
                          const SizedBox(width: VibrantSpacing.sm),
                          _ComboGlowBadge(combo: widget.combo),
                        ],
                        const SizedBox(width: VibrantSpacing.sm),
                        XPCounter(
                          xp: widget.xpEarned,
                          size: XPCounterSize.small,
                          showLabel: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    _AnimatedProgressBar(
                      progress: safeProgress,
                      currentQuestion: widget.currentQuestion,
                      totalQuestions: widget.totalQuestions,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    Wrap(
                      spacing: VibrantSpacing.md,
                      runSpacing: VibrantSpacing.sm,
                      children: [
                        _StatPill(
                          icon: Icons.task_alt_rounded,
                          label: 'Completed',
                          value:
                              '${widget.currentQuestion}/${widget.totalQuestions}',
                        ),
                        _StatPill(
                          icon: Icons.timer_rounded,
                          label: 'Focus time',
                          value: elapsedLabel,
                        ),
                        _StatPill(
                          icon: Icons.verified_rounded,
                          label: 'Accuracy',
                          value: accuracy == null
                              ? '—'
                              : '${(accuracy * 100).round()}%',
                          valueColor: accuracy != null && accuracy >= 0.8
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.language});

  final LanguageInfo language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphismCard(
      blur: 14,
      opacity: 0.14,
      borderOpacity: 0.32,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(language.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: VibrantSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                language.code.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      blur: 18,
      opacity: 0.18,
      borderOpacity: 0.3,
      borderRadius: 16,
      padding: const EdgeInsets.all(8),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.progress,
    required this.currentQuestion,
    required this.totalQuestions,
  });

  final double progress;
  final int currentQuestion;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: VibrantDuration.moderate,
      curve: VibrantCurve.smooth,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: VibrantTheme.premiumGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VibrantSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lesson progress',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$currentQuestion / $totalQuestions',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: VibrantSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComboGlowBadge extends StatelessWidget {
  const _ComboGlowBadge({required this.combo});

  final int combo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphismCard(
      blur: 18,
      opacity: 0.18,
      borderOpacity: 0.35,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      gradient: VibrantTheme.streakGradient,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            'Combo x$combo',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphismCard(
      blur: 16,
      opacity: 0.16,
      borderOpacity: 0.25,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timelapse_rounded, color: Colors.white, size: 18),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
