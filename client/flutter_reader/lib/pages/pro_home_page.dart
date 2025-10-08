import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../services/lesson_history_store.dart';
import '../theme/professional_theme.dart';
import '../widgets/pro_lesson_card.dart';

/// PROFESSIONAL home page - looks like Linear/Stripe/Notion
/// No childish animations - just sophisticated, purposeful motion
class ProHomePage extends ConsumerStatefulWidget {
  const ProHomePage({
    super.key,
    required this.onStartLearning,
    required this.onViewHistory,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onViewHistory;

  @override
  ConsumerState<ProHomePage> createState() => _ProHomePageState();
}

class _ProHomePageState extends ConsumerState<ProHomePage> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressServiceAsync = ref.watch(progressServiceProvider);

    return progressServiceAsync.when(
      data: (progressService) {
        return ListenableBuilder(
          listenable: progressService,
          builder: (context, _) {
            final hasProgress = progressService.hasProgress;
            final streak = progressService.streakDays;
            final xp = progressService.xpTotal;
            final level = progressService.currentLevel;

            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App bar with refined design
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    elevation: 0,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    title: Text(
                      'Ancient Greek',
                      style: theme.textTheme.titleLarge,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 20),
                        onPressed: () {
                          // Settings
                        },
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1),
                      child: Container(height: 1, color: colorScheme.outline),
                    ),
                  ),

                  // Main content
                  SliverPadding(
                    padding: const EdgeInsets.all(ProSpacing.xl),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero section
                        _buildHeroSection(
                          theme,
                          colorScheme,
                          hasProgress,
                          progressService,
                        ),

                        const SizedBox(height: ProSpacing.xxxl),

                        // Stats grid
                        if (hasProgress) ...[
                          _buildStatsGrid(
                            theme,
                            colorScheme,
                            streak,
                            xp,
                            level,
                          ),
                          const SizedBox(height: ProSpacing.xxxl),
                        ],

                        // Primary action
                        ProLessonCard(
                          title: hasProgress
                              ? 'Continue Your Journey'
                              : 'Start Learning',
                          description: hasProgress
                              ? 'Pick up where you left off and maintain your streak'
                              : 'Begin mastering Ancient Greek with interactive lessons',
                          icon: Icons.play_arrow,
                          badge: hasProgress ? 'Day $streak' : null,
                          onTap: widget.onStartLearning,
                        ),

                        const SizedBox(height: ProSpacing.xxl),

                        // Recent activity
                        if (!_loadingHistory && _recentLessons != null)
                          _buildRecentActivity(theme, colorScheme),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Unable to load progress',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasProgress,
    dynamic progressService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large greeting
        Text(
          hasProgress ? 'Welcome back' : 'Welcome',
          style: theme.textTheme.displaySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: ProSpacing.md),
        Text(
          hasProgress
              ? 'Continue building your mastery of Ancient Greek'
              : 'Master the language of Homer, Plato, and Aristotle',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        // Progress indicator if exists
        if (hasProgress) ...[
          const SizedBox(height: ProSpacing.xxl),
          _buildProgressSection(theme, colorScheme, progressService),
        ],
      ],
    );
  }

  Widget _buildProgressSection(
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic progressService,
  ) {
    final progress = progressService.progressToNextLevel;
    final xpToNext = progressService.xpToNextLevel;
    final level = progressService.currentLevel;

    return Container(
      padding: const EdgeInsets.all(ProSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ProRadius.lg),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level', style: theme.textTheme.titleMedium),
              Text(
                '$xpToNext XP to next',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: ProSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(ProRadius.sm),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(color: colorScheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    ThemeData theme,
    ColorScheme colorScheme,
    int streak,
    int xp,
    int level,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Stats', style: theme.textTheme.titleLarge),
        const SizedBox(height: ProSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ProStatCard(
                label: 'Day Streak',
                value: '$streak',
                icon: Icons.local_fire_department_outlined,
                trend: '+2 this week',
                trendDirection: TrendDirection.up,
              ),
            ),
            const SizedBox(width: ProSpacing.lg),
            Expanded(
              child: ProStatCard(
                label: 'Total XP',
                value: '$xp',
                icon: Icons.stars_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(ThemeData theme, ColorScheme colorScheme) {
    final lessons = _recentLessons ?? [];
    if (lessons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: theme.textTheme.titleLarge),
            TextButton(
              onPressed: widget.onViewHistory,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: ProSpacing.lg),
        ...lessons.map(
          (entry) => _buildActivityItem(theme, colorScheme, entry),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    ThemeData theme,
    ColorScheme colorScheme,
    LessonHistoryEntry entry,
  ) {
    final scorePercent = (entry.score * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: ProSpacing.md),
      padding: const EdgeInsets.all(ProSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ProRadius.lg),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scorePercent >= 90
                  ? colorScheme.tertiaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ProRadius.sm),
            ),
            child: Icon(
              Icons.check,
              size: 20,
              color: scorePercent >= 90
                  ? colorScheme.tertiary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: ProSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.textSnippet,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: ProSpacing.xs),
                Text(
                  '${entry.correctCount}/${entry.totalTasks} correct · ${_formatDate(entry.timestamp)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ProSpacing.md),
          Text(
            '$scorePercent%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scorePercent >= 90
                  ? colorScheme.tertiary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today at $hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
