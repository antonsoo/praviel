import 'package:flutter/material.dart';

import '../../theme/vibrant_animations.dart';
import '../../theme/vibrant_theme.dart';
import '../glassmorphism_card.dart';

class VibrantLessonActionBar extends StatelessWidget {
  const VibrantLessonActionBar({
    super.key,
    required this.canCheck,
    required this.isLastQuestion,
    required this.onCheck,
    required this.onSkip,
  });

  final bool canCheck;
  final bool isLastQuestion;
  final VoidCallback onCheck;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helperText = !canCheck
        ? 'Complete the task to enable Check.'
        : (isLastQuestion
              ? 'Finish strong to trigger your lesson celebration!'
              : 'Lock in your answer to keep the combo alive.');

    return Container(
      decoration: const BoxDecoration(
        gradient: VibrantTheme.midnightGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x99031247),
            blurRadius: 32,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VibrantSpacing.lg,
            VibrantSpacing.md,
            VibrantSpacing.lg,
            VibrantSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkipButton(onTap: onSkip),
                  const SizedBox(width: VibrantSpacing.md),
                  Expanded(
                    child: _PrimaryActionButton(
                      label: isLastQuestion ? 'Finish Lesson' : 'Check Answer',
                      icon: isLastQuestion
                          ? Icons.emoji_events_rounded
                          : Icons.check_rounded,
                      enabled: canCheck,
                      onTap: onCheck,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                helperText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScaleButton(
      onTap: onTap,
      child: GlassmorphismCard(
        blur: 18,
        opacity: 0.16,
        borderOpacity: 0.3,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forward_rounded,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              'Skip',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: VibrantDuration.quick,
        opacity: enabled ? 1 : 0.45,
        child: AnimatedScaleButton(
          onTap: enabled ? onTap : () {},
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.xl,
              vertical: VibrantSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x663C46FF),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: VibrantSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
