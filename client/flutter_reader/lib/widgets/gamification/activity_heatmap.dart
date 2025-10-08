import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/vibrant_theme.dart';

/// GitHub-style activity heatmap showing learning consistency
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    required this.activityData,
    this.weeks = 12,
    super.key,
  });

  /// Map of date (YYYY-MM-DD) to XP earned that day
  final Map<String, int> activityData;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity', style: theme.textTheme.titleMedium),
        const SizedBox(height: VibrantSpacing.md),
        _buildHeatmap(colorScheme),
        const SizedBox(height: VibrantSpacing.sm),
        _buildLegend(colorScheme),
      ],
    );
  }

  Widget _buildHeatmap(ColorScheme colorScheme) {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: weeks * 7));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(weeks, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Column(
              children: List.generate(7, (dayIndex) {
                final date = startDate.add(
                  Duration(days: weekIndex * 7 + dayIndex),
                );
                if (date.isAfter(today)) {
                  return const SizedBox(width: 12, height: 12);
                }
                return _buildCell(date, colorScheme);
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCell(DateTime date, ColorScheme colorScheme) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final xp = activityData[dateKey] ?? 0;
    final intensity = _getIntensity(xp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(
        message: '${DateFormat('MMM d').format(date)}: $xp XP',
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getColor(intensity, colorScheme),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  int _getIntensity(int xp) {
    if (xp == 0) return 0;
    if (xp < 50) return 1;
    if (xp < 100) return 2;
    if (xp < 200) return 3;
    return 4;
  }

  Color _getColor(int intensity, ColorScheme colorScheme) {
    const baseColor = Color(0xFF7C3AED); // Purple
    switch (intensity) {
      case 0:
        return colorScheme.surfaceContainerHighest;
      case 1:
        return baseColor.withValues(alpha: 0.2);
      case 2:
        return baseColor.withValues(alpha: 0.4);
      case 3:
        return baseColor.withValues(alpha: 0.6);
      case 4:
        return baseColor;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          'Less',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: VibrantSpacing.xs),
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getColor(index, colorScheme),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: VibrantSpacing.xs),
        Text(
          'More',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Compact version for dashboard
class CompactActivityHeatmap extends StatelessWidget {
  const CompactActivityHeatmap({required this.activityData, super.key});

  final Map<String, int> activityData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return Row(
      children: List.generate(30, (index) {
        final date = today.subtract(Duration(days: 29 - index));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final xp = activityData[dateKey] ?? 0;
        final intensity = _getIntensity(xp);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: _getColor(intensity, colorScheme),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }

  int _getIntensity(int xp) {
    if (xp == 0) return 0;
    if (xp < 50) return 1;
    if (xp < 100) return 2;
    if (xp < 200) return 3;
    return 4;
  }

  Color _getColor(int intensity, ColorScheme colorScheme) {
    const baseColor = Color(0xFF7C3AED);
    switch (intensity) {
      case 0:
        return colorScheme.surfaceContainerHighest;
      case 1:
        return baseColor.withValues(alpha: 0.2);
      case 2:
        return baseColor.withValues(alpha: 0.4);
      case 3:
        return baseColor.withValues(alpha: 0.6);
      case 4:
        return baseColor;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }
}
