import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Animated flame icon for streak display
class StreakFlame extends StatefulWidget {
  const StreakFlame({
    super.key,
    required this.streakDays,
    this.size = StreakFlameSize.medium,
    this.animate = true,
  });

  final int streakDays;
  final StreakFlameSize size;
  final bool animate;

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flicker;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _flicker = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(StreakFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size == StreakFlameSize.large
        ? 48.0
        : widget.size == StreakFlameSize.medium
            ? 32.0
            : 24.0;

    if (!widget.animate) {
      return Icon(
        Icons.local_fire_department_rounded,
        size: iconSize,
        color: const Color(0xFFFF6B35),
      );
    }

    return AnimatedBuilder(
      animation: _flicker,
      builder: (context, child) {
        return Transform.scale(
          scale: _flicker.value,
          child: ShaderMask(
            shaderCallback: (bounds) => VibrantTheme.streakGradient.createShader(bounds),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

enum StreakFlameSize { small, medium, large }

/// Streak counter with animated flame
class StreakCounter extends StatelessWidget {
  const StreakCounter({
    super.key,
    required this.streakDays,
    this.size = StreakCounterSize.medium,
    this.showLabel = true,
  });

  final int streakDays;
  final StreakCounterSize size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = size == StreakCounterSize.large ? 32.0 : size == StreakCounterSize.medium ? 24.0 : 18.0;
    final flameSize = size == StreakCounterSize.large
        ? StreakFlameSize.large
        : size == StreakCounterSize.medium
            ? StreakFlameSize.medium
            : StreakFlameSize.small;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == StreakCounterSize.large ? 20 : size == StreakCounterSize.medium ? 16 : 12,
        vertical: size == StreakCounterSize.large ? 12 : size == StreakCounterSize.medium ? 10 : 8,
      ),
      decoration: BoxDecoration(
        gradient: VibrantTheme.streakGradient,
        borderRadius: BorderRadius.circular(size == StreakCounterSize.large ? 16 : size == StreakCounterSize.medium ? 14 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreakFlame(streakDays: streakDays, size: flameSize),
          SizedBox(width: size == StreakCounterSize.small ? 6 : 8),
          Text(
            streakDays.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: size == StreakCounterSize.small ? 4 : 6),
            Text(
              'DAY${streakDays == 1 ? '' : 'S'}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: size == StreakCounterSize.large ? 16 : size == StreakCounterSize.medium ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum StreakCounterSize { small, medium, large }

/// Streak progress card showing daily progress
class StreakProgressCard extends StatelessWidget {
  const StreakProgressCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.goal = 30,
  });

  final int currentStreak;
  final int longestStreak;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (currentStreak / goal).clamp(0.0, 1.0);
    final remaining = math.max(0, goal - currentStreak);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: VibrantShadow.md(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StreakFlame(streakDays: currentStreak, size: StreakFlameSize.large),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentStreak Day Streak!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xxs),
                    Text(
                      remaining > 0
                          ? '$remaining more days to reach your goal!'
                          : 'Goal achieved! Keep going!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.lg),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: VibrantTheme.streakGradient,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentStreak / $goal days',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Best: $longestStreak days',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple streak indicator for app bar
class StreakIndicator extends StatelessWidget {
  const StreakIndicator({
    super.key,
    required this.streakDays,
  });

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (streakDays == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: VibrantTheme.streakGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            streakDays.toString(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Streak freeze icon - for when user has protection
class StreakFreezeIcon extends StatelessWidget {
  const StreakFreezeIcon({
    super.key,
    this.count = 1,
    this.size = 24.0,
  });

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF60A5FA),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.ac_unit_rounded,
            size: size,
            color: Colors.white,
          ),
          if (count > 1)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
