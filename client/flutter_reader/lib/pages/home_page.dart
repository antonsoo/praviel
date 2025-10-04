import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../services/lesson_history_store.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/surface.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    required this.onStartLearning,
    required this.onViewHistory,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onViewHistory;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final LessonHistoryStore _historyStore = LessonHistoryStore();
  List<LessonHistoryEntry>? _recentLessons;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadRecentHistory();
  }

  Future<void> _loadRecentHistory() async {
    final entries = await _historyStore.load();
    if (mounted) {
      setState(() {
        _recentLessons = entries.take(3).toList();
        _loadingHistory = false;
      });
    }
  }

  Future<void> _refresh() async {
    final service = await ref.read(progressServiceProvider.future);
    await service.load();
    await _loadRecentHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final progressServiceAsync = ref.watch(progressServiceProvider);

    return progressServiceAsync.when(
      data: (progressService) {
        return ListenableBuilder(
          listenable: progressService,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacing.md),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero section
                    _buildHeroSection(theme, spacing, progressService),
                    SizedBox(height: AppSpacing.space24),

                    // Progress card
                    _buildProgressCard(theme, spacing, progressService),
                    SizedBox(height: AppSpacing.space24),

                    // CTA button
                    _buildCTAButton(theme, spacing, progressService),
                    SizedBox(height: AppSpacing.space24),

                    // Recent lessons
                    if (!_loadingHistory && _recentLessons != null)
                      _buildRecentLessons(theme, spacing),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading progress: $error'),
      ),
    );
  }

  Widget _buildHeroSection(
    ThemeData theme,
    ReaderSpacing spacing,
    ProgressService progressService,
  ) {
    final hasProgress = progressService.hasProgress;
    final greeting = hasProgress ? 'Welcome back!' : 'Start Your Ancient Greek Journey';
    final subtitle = hasProgress
        ? 'Keep up the great work'
        : 'Master ancient languages through interactive lessons';

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    ThemeData theme,
    ReaderSpacing spacing,
    ProgressService progressService,
  ) {
    if (!progressService.hasProgress) {
      return Surface(
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            SizedBox(height: spacing.md),
            Text(
              'Complete your first lesson to start tracking progress',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final streak = progressService.streakDays;
    final xp = progressService.xpTotal;
    final level = progressService.currentLevel;
    final progress = progressService.progressToNextLevel;
    final xpToNext = progressService.xpToNextLevel;

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  spacing,
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  label: 'Streak',
                  value: '$streak',
                  suffix: streak == 1 ? 'day' : 'days',
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: _buildStatItem(
                  theme,
                  spacing,
                  icon: Icons.stars,
                  iconColor: theme.colorScheme.secondary,
                  label: 'Total XP',
                  value: '$xp',
                  suffix: 'XP',
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: _buildStatItem(
                  theme,
                  spacing,
                  icon: Icons.military_tech,
                  iconColor: theme.colorScheme.tertiary,
                  label: 'Level',
                  value: '$level',
                  suffix: '',
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),

          // Level progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$xpToNext XP to Level ${level + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    ReaderSpacing spacing, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String suffix,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(spacing.sm),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        SizedBox(height: spacing.xs),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (suffix.isNotEmpty)
          Text(
            suffix,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        SizedBox(height: spacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButton(
    ThemeData theme,
    ReaderSpacing spacing,
    ProgressService progressService,
  ) {
    final hasProgress = progressService.hasProgress;
    final buttonText = hasProgress ? 'Continue Learning' : 'Start Daily Practice';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.onStartLearning,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: spacing.md,
            horizontal: spacing.lg,
          ),
        ),
        icon: Icon(
          hasProgress ? Icons.play_arrow : Icons.school,
          size: 28,
        ),
        label: Text(
          buttonText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLessons(ThemeData theme, ReaderSpacing spacing) {
    final lessons = _recentLessons ?? [];

    if (lessons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Lessons',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: widget.onViewHistory,
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        ...lessons.map((entry) => _buildLessonPreview(entry, theme, spacing)),
      ],
    );
  }

  Widget _buildLessonPreview(
    LessonHistoryEntry entry,
    ThemeData theme,
    ReaderSpacing spacing,
  ) {
    final scorePercent = (entry.score * 100).toInt();
    Color scoreColor;
    if (scorePercent >= 90) {
      scoreColor = theme.colorScheme.tertiary;
    } else if (scorePercent >= 70) {
      scoreColor = theme.colorScheme.secondary;
    } else {
      scoreColor = theme.colorScheme.error;
    }

    return Surface(
      margin: EdgeInsets.only(bottom: spacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: widget.onViewHistory,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                Icons.check_circle,
                color: scoreColor,
                size: 24,
              ),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.textSnippet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '${entry.correctCount}/${entry.totalTasks} correct',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$scorePercent%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
