import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import 'dart:math' as math;

/// Beautiful reading progress tracker with streaks, analytics, and milestones
class ReadingProgressTracker extends StatelessWidget {
  const ReadingProgressTracker({
    super.key,
    required this.wordsRead,
    required this.totalWords,
    required this.currentStreak,
    required this.longestStreak,
    required this.pagesRead,
    required this.timeSpentMinutes,
  });

  final int wordsRead;
  final int totalWords;
  final int currentStreak;
  final int longestStreak;
  final int pagesRead;
  final int timeSpentMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = totalWords > 0 ? wordsRead / totalWords : 0.0;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.sm),
                decoration: BoxDecoration(
                  gradient: VibrantTheme.heroGradient,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Beautiful progress bar
          _ProgressBar(progress: progress),

          const SizedBox(height: VibrantSpacing.lg),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Current Streak',
                  value: '$currentStreak',
                  unit: 'days',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Best Streak',
                  value: '$longestStreak',
                  unit: 'days',
                  color: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.md),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Pages Read',
                  value: '$pagesRead',
                  unit: 'total',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.schedule_rounded,
                  label: 'Time Spent',
                  value: '$timeSpentMinutes',
                  unit: 'minutes',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom progress bar with gradient and animation
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Words Read',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.sm),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            child: Stack(
              children: [
                // Background shimmer effect
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                // Progress fill
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.tertiary,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: VibrantSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: VibrantSpacing.xs),
              Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Weekly reading heatmap
class WeeklyReadingHeatmap extends StatelessWidget {
  const WeeklyReadingHeatmap({
    super.key,
    required this.dailyMinutes,
  });

  final List<int> dailyMinutes; // Last 7 days

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxMinutes = dailyMinutes.fold<int>(0, math.max);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final minutes = index < dailyMinutes.length ? dailyMinutes[index] : 0;
              final intensity = maxMinutes > 0 ? minutes / maxMinutes : 0.0;
              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 32,
                          height: 80 * intensity.clamp(0.1, 1.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                colorScheme.primary,
                                colorScheme.tertiary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(VibrantRadius.sm),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    days[index],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${minutes}m',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
