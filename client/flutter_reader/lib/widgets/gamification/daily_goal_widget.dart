import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// Daily goal progress widget with visual feedback
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({
    required this.currentXP,
    required this.goalXP,
    required this.streak,
    this.onTap,
    super.key,
  });

  final int currentXP;
  final int goalXP;
  final int streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = goalXP > 0 ? (currentXP / goalXP).clamp(0.0, 1.0) : 0.0;
    final isComplete = currentXP >= goalXP;

    return AnimatedScaleButton(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          gradient: isComplete
              ? VibrantTheme.successGradient
              : LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: VibrantShadow.md(colorScheme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isComplete
                          ? Icons.check_circle_rounded
                          : Icons.flag_rounded,
                      color: isComplete ? Colors.white : colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Text(
                      'Daily Goal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isComplete
                            ? Colors.white
                            : colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.sm,
                      vertical: VibrantSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? Colors.white.withValues(alpha: 0.2)
                          : colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: isComplete
                              ? Colors.white
                              : const Color(0xFFFF6B35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streak',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isComplete
                                ? Colors.white
                                : colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VibrantSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currentXP',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: isComplete ? Colors.white : colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ $goalXP XP',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isComplete
                          ? Colors.white.withValues(alpha: 0.8)
                          : colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VibrantSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? Colors.white.withValues(alpha: 0.3)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                  ),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: isComplete
                            ? LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.9),
                                ],
                              )
                            : VibrantTheme.xpGradient,
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: isComplete
                                ? Colors.white.withValues(alpha: 0.5)
                                : colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isComplete) ...[
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                '🎉 Goal completed!',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                '${goalXP - currentXP} XP to go',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact inline daily goal progress
class InlineDailyGoal extends StatelessWidget {
  const InlineDailyGoal({
    required this.currentXP,
    required this.goalXP,
    super.key,
  });

  final int currentXP;
  final int goalXP;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = goalXP > 0 ? (currentXP / goalXP).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Goal',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$currentXP / $goalXP XP',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
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
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(gradient: VibrantTheme.xpGradient),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Daily goal setting modal
class DailyGoalSettingModal extends StatefulWidget {
  const DailyGoalSettingModal({
    required this.currentGoal,
    required this.onGoalChanged,
    super.key,
  });

  final int currentGoal;
  final Function(int) onGoalChanged;

  @override
  State<DailyGoalSettingModal> createState() => _DailyGoalSettingModalState();
}

class _DailyGoalSettingModalState extends State<DailyGoalSettingModal> {
  late int _selectedGoal;

  final List<Map<String, dynamic>> _presets = [
    {'xp': 25, 'label': 'Casual', 'desc': '1-2 exercises', 'icon': '🌱'},
    {'xp': 50, 'label': 'Regular', 'desc': '2-4 exercises', 'icon': '🎯'},
    {'xp': 100, 'label': 'Serious', 'desc': '4-8 exercises', 'icon': '🔥'},
    {'xp': 200, 'label': 'Intense', 'desc': '8+ exercises', 'icon': '⚡'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: VibrantSpacing.xl,
        right: VibrantSpacing.xl,
        top: VibrantSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + VibrantSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set Daily Goal', style: theme.textTheme.headlineSmall),
          const SizedBox(height: VibrantSpacing.xs),
          Text(
            'Choose how much you want to practice each day',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),
          ..._presets.map((preset) {
            final isSelected = _selectedGoal == preset['xp'];
            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
              child: AnimatedScaleButton(
                onTap: () {
                  setState(() {
                    _selectedGoal = preset['xp'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        preset['icon'],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: VibrantSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset['label'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${preset['xp']} XP/day • ${preset['desc']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: VibrantSpacing.md),
          FilledButton(
            onPressed: () {
              widget.onGoalChanged(_selectedGoal);
              Navigator.pop(context);
            },
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }
}
