import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/premium_cards.dart';
import '../services/lesson_history_store.dart';
import 'dart:math' as math;

/// Comprehensive progress statistics page showing all-time performance
class ProgressStatsPage extends ConsumerStatefulWidget {
  const ProgressStatsPage({super.key});

  @override
  ConsumerState<ProgressStatsPage> createState() => _ProgressStatsPageState();
}

class _ProgressStatsPageState extends ConsumerState<ProgressStatsPage> {
  final LessonHistoryStore _historyStore = LessonHistoryStore();
  List<LessonHistoryEntry>? _history;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final entries = await _historyStore.load();
      if (mounted) {
        setState(() {
          _history = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressAsync = ref.watch(progressServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Statistics'),
        elevation: 0,
      ),
      body: progressAsync.when(
        data: (progressService) {
          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall stats cards
                  _buildOverallStats(theme, colorScheme, progressService),
                  const SizedBox(height: VibrantSpacing.xl),

                  // Performance breakdown
                  _buildPerformanceSection(theme, colorScheme),
                  const SizedBox(height: VibrantSpacing.xl),

                  // Level progress
                  _buildLevelProgress(theme, colorScheme, progressService),
                  const SizedBox(height: VibrantSpacing.xl),

                  // Recent lessons timeline
                  if (!_loading && _history != null && _history!.isNotEmpty)
                    _buildRecentLessonsTimeline(theme, colorScheme),

                  const SizedBox(height: VibrantSpacing.xxxl),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Unable to load progress data'),
        ),
      ),
    );
  }

  Widget _buildOverallStats(
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic progressService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Journey',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total XP',
                value: '${progressService.xpTotal}',
                icon: Icons.stars_rounded,
                gradient: VibrantTheme.xpGradient,
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: StatCard(
                title: 'Current Level',
                value: '${progressService.currentLevel}',
                icon: Icons.arrow_upward_rounded,
                gradient: VibrantTheme.heroGradient,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Streak',
                value: '${progressService.streakDays}',
                icon: Icons.local_fire_department_rounded,
                gradient: VibrantTheme.streakGradient,
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: StatCard(
                title: 'Lessons',
                value: '${progressService.totalLessons}',
                icon: Icons.school_rounded,
                gradient: VibrantTheme.successGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(ThemeData theme, ColorScheme colorScheme) {
    if (_loading || _history == null || _history!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate accuracy
    int totalCorrect = 0;
    int totalQuestions = 0;
    for (final entry in _history!) {
      totalCorrect += entry.correctCount;
      totalQuestions += entry.totalTasks;
    }

    final accuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions * 100).round()
        : 0;

    // Calculate average score
    final avgScore = _history!.isEmpty
        ? 0.0
        : _history!.map((e) => e.score).reduce((a, b) => a + b) / _history!.length;

    // Find best streak
    int currentStreak = 0;
    int bestStreak = 0;

    for (final entry in _history!.reversed) {
      if (entry.correctCount == entry.totalTasks) {
        currentStreak++;
        bestStreak = math.max(bestStreak, currentStreak);
      } else {
        if (currentStreak > bestStreak) bestStreak = currentStreak;
        currentStreak = 0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        ElevatedCard(
          elevation: 2,
          child: Column(
            children: [
              _buildPerformanceRow(
                theme,
                colorScheme,
                'Overall Accuracy',
                '$accuracy%',
                accuracy / 100,
                colorScheme.tertiary,
              ),
              const Divider(height: VibrantSpacing.lg),
              _buildPerformanceRow(
                theme,
                colorScheme,
                'Average Score',
                '${(avgScore * 100).round()}%',
                avgScore,
                colorScheme.primary,
              ),
              const Divider(height: VibrantSpacing.lg),
              _buildStatRow(
                theme,
                colorScheme,
                'Best Perfect Streak',
                '$bestStreak lessons',
                Icons.whatshot_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: VibrantSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgress(
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic progressService,
  ) {
    final currentLevel = progressService.currentLevel;
    final progress = progressService.progressToNextLevel;
    final xpTotal = progressService.xpTotal;
    final xpForCurrent = progressService.xpForCurrentLevel;
    final xpForNext = progressService.xpForNextLevel;
    final xpNeeded = xpForNext - xpTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level Progress',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        GlowCard(
          gradient: VibrantTheme.heroGradient,
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $currentLevel',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$xpNeeded XP to Level ${currentLevel + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(VibrantRadius.sm),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: VibrantSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${xpTotal - xpForCurrent} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${xpForNext - xpForCurrent} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLessonsTimeline(ThemeData theme, ColorScheme colorScheme) {
    final recentLessons = _history!.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Lessons',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        ...recentLessons.asMap().entries.map((entry) {
          final lesson = entry.value;
          final score = lesson.score;
          final isPerfect = lesson.correctCount == lesson.totalTasks;

          return SlideInFromBottom(
            delay: Duration(milliseconds: entry.key * 50),
            child: Container(
              margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
              child: ElevatedCard(
                elevation: 1,
                child: Row(
                  children: [
                    // Score indicator
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isPerfect
                            ? colorScheme.tertiary
                            : score >= 0.75
                                ? colorScheme.primary
                                : colorScheme.error,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(VibrantRadius.lg),
                        ),
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPerfect)
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 20,
                                ),
                              if (isPerfect)
                                const SizedBox(width: VibrantSpacing.xs),
                              Text(
                                '${lesson.correctCount}/${lesson.totalTasks} correct',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Score: ${(score * 100).round()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.sm,
                        vertical: VibrantSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: isPerfect
                            ? VibrantTheme.successGradient
                            : score >= 0.75
                                ? VibrantTheme.xpGradient
                                : LinearGradient(
                                    colors: [
                                      colorScheme.error,
                                      colorScheme.error.withValues(alpha: 0.8),
                                    ],
                                  ),
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPerfect)
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 14,
                            ),
                          if (isPerfect)
                            const SizedBox(width: 4),
                          Text(
                            '${(score * 100).round()}%',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
