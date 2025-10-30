import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';

/// Weekly progress chart showing lessons completed over the last 7 days
/// Simple bar chart without external dependencies
class WeeklyProgressChart extends StatefulWidget {
  const WeeklyProgressChart({
    super.key,
    required this.dailyLessonCounts,
    this.maxBarHeight = 120,
  });

  /// List of lesson counts for each day (last 7 days, Monday-Sunday)
  final List<int> dailyLessonCounts;
  final double maxBarHeight;

  @override
  State<WeeklyProgressChart> createState() => _WeeklyProgressChartState();
}

class _WeeklyProgressChartState extends State<WeeklyProgressChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate max value for scaling
    final maxValue = widget.dailyLessonCounts.isEmpty
        ? 1
        : widget.dailyLessonCounts.reduce((a, b) => a > b ? a : b).toDouble();

    // Day labels
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                'This Week',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Total lessons count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(VibrantRadius.sm),
                ),
                child: Text(
                  '${widget.dailyLessonCounts.fold<int>(0, (sum, count) => sum + count)} total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Chart area
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final count = index < widget.dailyLessonCounts.length
                  ? widget.dailyLessonCounts[index]
                  : 0;
              final heightFactor = maxValue > 0 ? count / maxValue : 0.0;
              final isSelected = _selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.light();
                    setState(() {
                      _selectedIndex = isSelected ? null : index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Count label (shown on tap)
                        AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            height: 20,
                            alignment: Alignment.center,
                            child: Text(
                              count.toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Bar
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: widget.maxBarHeight * heightFactor * _animation.value,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? VibrantTheme.heroGradient
                                    : LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.primary.withValues(alpha: 0.7),
                                        ],
                                      ),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(VibrantRadius.sm),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              // Minimum height for visibility even when 0
                              constraints: const BoxConstraints(minHeight: 4),
                            );
                          },
                        ),

                        const SizedBox(height: VibrantSpacing.sm),

                        // Day label
                        Text(
                          dayLabels[index],
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Monthly progress chart showing lessons per week over 4 weeks
class MonthlyProgressChart extends StatelessWidget {
  const MonthlyProgressChart({
    super.key,
    required this.weeklyLessonCounts,
  });

  final List<int> weeklyLessonCounts; // 4 weeks

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final maxValue = weeklyLessonCounts.isEmpty
        ? 1
        : weeklyLessonCounts.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                'This Month',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(VibrantRadius.sm),
                ),
                child: Text(
                  '${weeklyLessonCounts.fold<int>(0, (sum, count) => sum + count)} total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Simple week bars
          ...List.generate(4, (index) {
            final count = index < weeklyLessonCounts.length
                ? weeklyLessonCounts[index]
                : 0;
            final widthFactor = maxValue > 0 ? count / maxValue : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Week ${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(VibrantRadius.sm),
                          ),
                        ),
                        // Progress bar
                        FractionallySizedBox(
                          widthFactor: widthFactor,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.secondary,
                                  colorScheme.secondary.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(VibrantRadius.sm),
                            ),
                          ),
                        ),
                        // Count label
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.md,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$count ${count == 1 ? 'lesson' : 'lessons'}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widthFactor > 0.3
                                  ? Colors.white
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
