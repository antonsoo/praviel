import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/combo_service.dart';

/// Floating combo counter shown during lessons
class ComboCounter extends StatefulWidget {
  const ComboCounter({
    required this.combo,
    required this.tier,
    this.visible = true,
    super.key,
  });

  final int combo;
  final ComboTier tier;
  final bool visible;

  @override
  State<ComboCounter> createState() => _ComboCounterState();
}

class _ComboCounterState extends State<ComboCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getTierColor() {
    switch (widget.tier) {
      case ComboTier.bronze:
        return const Color(0xFFCD7F32);
      case ComboTier.silver:
        return const Color(0xFFC0C0C0);
      case ComboTier.gold:
        return const Color(0xFFFFD700);
      case ComboTier.legendary:
        return const Color(0xFFFF1493);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.combo < 3) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tierColor = _getTierColor();

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.md,
          vertical: VibrantSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tierColor,
              tierColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(VibrantRadius.xl),
          boxShadow: [
            BoxShadow(
              color: tierColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: VibrantSpacing.xs),
            GrowNumber(
              value: widget.combo,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'x',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combo popup animation when reaching milestones
class ComboMilestonePopup extends StatefulWidget {
  const ComboMilestonePopup({
    required this.combo,
    required this.message,
    required this.emoji,
    super.key,
  });

  final int combo;
  final String message;
  final String emoji;

  @override
  State<ComboMilestonePopup> createState() => _ComboMilestonePopupState();
}

class _ComboMilestonePopupState extends State<ComboMilestonePopup>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.5), end: Offset.zero),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -0.5)),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                '${widget.combo}x COMBO!',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD700),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              Text(
                widget.message,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Combo progress bar showing progress to next milestone
class ComboProgressBar extends StatelessWidget {
  const ComboProgressBar({
    required this.currentCombo,
    super.key,
  });

  final int currentCombo;

  int _getNextMilestone() {
    if (currentCombo < 3) return 3;
    if (currentCombo < 5) return 5;
    if (currentCombo < 10) return 10;
    if (currentCombo < 20) return 20;
    if (currentCombo < 50) return 50;
    return 100;
  }

  int _getPreviousMilestone() {
    if (currentCombo < 3) return 0;
    if (currentCombo < 5) return 3;
    if (currentCombo < 10) return 5;
    if (currentCombo < 20) return 10;
    if (currentCombo < 50) return 20;
    return 50;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nextMilestone = _getNextMilestone();
    final prevMilestone = _getPreviousMilestone();
    final progress = currentCombo >= nextMilestone
        ? 1.0
        : (currentCombo - prevMilestone) / (nextMilestone - prevMilestone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Combo Progress',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$currentCombo / $nextMilestone',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(VibrantRadius.sm),
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700),
                        const Color(0xFFFFA500),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Combo stats card for profile/results
class ComboStatsCard extends StatelessWidget {
  const ComboStatsCard({
    required this.currentCombo,
    required this.maxCombo,
    required this.totalCombos,
    super.key,
  });

  final int currentCombo;
  final int maxCombo;
  final int totalCombos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.2),
            const Color(0xFFFFA500).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: const Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                'Combo Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                label: 'Current',
                value: currentCombo.toString(),
                color: const Color(0xFFFFD700),
              ),
              Container(width: 1, height: 40, color: colorScheme.outline),
              _StatColumn(
                label: 'Best',
                value: maxCombo.toString(),
                color: const Color(0xFFFFA500),
              ),
              Container(width: 1, height: 40, color: colorScheme.outline),
              _StatColumn(
                label: 'Milestones',
                value: totalCombos.toString(),
                color: const Color(0xFFFF6B35),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
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

/// Animated combo multiplier indicator
class ComboMultiplierBadge extends StatefulWidget {
  const ComboMultiplierBadge({
    required this.multiplier,
    super.key,
  });

  final double multiplier;

  @override
  State<ComboMultiplierBadge> createState() => _ComboMultiplierBadgeState();
}

class _ComboMultiplierBadgeState extends State<ComboMultiplierBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.multiplier <= 1.0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(VibrantSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFA500),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -_rotationAnimation.value,
              child: Text(
                '${widget.multiplier.toStringAsFixed(1)}x',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
