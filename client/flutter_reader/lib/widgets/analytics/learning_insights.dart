import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/vibrant_theme.dart';

/// Learning insights dashboard
class LearningInsightsDashboard extends StatelessWidget {
  const LearningInsightsDashboard({
    required this.weeklyXP,
    required this.accuracyByCategory,
    required this.studyTimeByDay,
    required this.strengthsWeaknesses,
    super.key,
  });

  final List<int> weeklyXP; // Last 7 days
  final Map<String, double> accuracyByCategory;
  final Map<String, int> studyTimeByDay; // Minutes per day
  final LearningAnalysis strengthsWeaknesses;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      children: [
        // Weekly XP chart
        _WeeklyXPChart(weeklyXP: weeklyXP),
        const SizedBox(height: VibrantSpacing.xl),

        // Accuracy by category
        _AccuracyBreakdown(accuracyByCategory: accuracyByCategory),
        const SizedBox(height: VibrantSpacing.xl),

        // Study time chart
        _StudyTimeChart(studyTimeByDay: studyTimeByDay),
        const SizedBox(height: VibrantSpacing.xl),

        // Strengths & Weaknesses
        _StrengthsWeaknessesCard(analysis: strengthsWeaknesses),
      ],
    );
  }
}

/// Weekly XP bar chart
class _WeeklyXPChart extends StatelessWidget {
  const _WeeklyXPChart({required this.weeklyXP});

  final List<int> weeklyXP;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly XP Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: weeklyXP.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt()],
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyXP.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        gradient: VibrantTheme.xpGradient,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(VibrantRadius.sm),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accuracy breakdown by category
class _AccuracyBreakdown extends StatelessWidget {
  const _AccuracyBreakdown({required this.accuracyByCategory});

  final Map<String, double> accuracyByCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accuracy by Exercise Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          ...accuracyByCategory.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${(entry.value * 100).round()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _getAccuracyColor(entry.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        _getAccuracyColor(entry.value),
                      ),
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

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.9) return const Color(0xFF10B981); // Green
    if (accuracy >= 0.7) return const Color(0xFFFFA500); // Orange
    return const Color(0xFFEF4444); // Red
  }
}

/// Study time pie chart
class _StudyTimeChart extends StatelessWidget {
  const _StudyTimeChart({required this.studyTimeByDay});

  final Map<String, int> studyTimeByDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = studyTimeByDay.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Time Distribution',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          Row(
            children: [
              // Pie chart
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: _buildPieSections(studyTimeByDay, total),
                  ),
                ),
              ),
              const SizedBox(width: VibrantSpacing.lg),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: studyTimeByDay.entries.map((entry) {
                    final percentage = (entry.value / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: VibrantSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getDayColor(entry.key),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: VibrantSpacing.xs),
                          Text(
                            '${entry.key}: $percentage%',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Total: ${_formatMinutes(total)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, int> data,
    int total,
  ) {
    return data.entries.map((entry) {
      final percentage = entry.value / total;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${(percentage * 100).round()}%',
        color: _getDayColor(entry.key),
        radius: 40,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  Color _getDayColor(String day) {
    final colors = {
      'Mon': const Color(0xFF7C3AED),
      'Tue': const Color(0xFF3B82F6),
      'Wed': const Color(0xFF10B981),
      'Thu': const Color(0xFFF59E0B),
      'Fri': const Color(0xFFEF4444),
      'Sat': const Color(0xFFEC4899),
      'Sun': const Color(0xFF8B5CF6),
    };
    return colors[day] ?? const Color(0xFF64748B);
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

/// Strengths and weaknesses analysis
class _StrengthsWeaknessesCard extends StatelessWidget {
  const _StrengthsWeaknessesCard({required this.analysis});

  final LearningAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Analysis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.lg),

          // Strengths
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: const Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strengths',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    ...analysis.strengths.map((strength) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VibrantSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: VibrantSpacing.xs),
                            Expanded(
                              child: Text(
                                strength,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Weaknesses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: const Color(0xFFFFA500),
                size: 24,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Areas to Improve',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFFFA500),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    ...analysis.weaknesses.map((weakness) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VibrantSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: const Color(0xFFFFA500),
                            ),
                            const SizedBox(width: VibrantSpacing.xs),
                            Expanded(
                              child: Text(
                                weakness,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Recommendations
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(VibrantRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Expanded(
                  child: Text(
                    analysis.recommendation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Learning analysis data model
class LearningAnalysis {
  const LearningAnalysis({
    required this.strengths,
    required this.weaknesses,
    required this.recommendation,
  });

  final List<String> strengths;
  final List<String> weaknesses;
  final String recommendation;
}
