import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../features/gamification/presentation/providers/gamification_providers.dart';
import '../features/gamification/domain/models/user_progress.dart';
import '../widgets/achievements/achievement_showcase.dart' as achievement_widget;
import '../widgets/reader/reading_progress_tracker.dart';
import 'package:fl_chart/fl_chart.dart';

/// Professional profile page with achievements, stats, and analytics
/// Inspired by gaming profiles and fitness app UX patterns
class EnhancedProfilePage extends ConsumerStatefulWidget {
  const EnhancedProfilePage({super.key});

  @override
  ConsumerState<EnhancedProfilePage> createState() => _EnhancedProfilePageState();
}

class _EnhancedProfilePageState extends ConsumerState<EnhancedProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userProgressAsync = ref.watch(userProgressProvider);
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Profile header
          SliverAppBar.large(
            floating: false,
            pinned: true,
            expandedHeight: 280,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: VibrantTheme.heroGradient,
                ),
                child: SafeArea(
                  child: userProgressAsync.when(
                    data: (progress) => _ProfileHeader(progress: progress)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.1, end: 0),
                    loading: () => _LoadingProfileHeader(),
                    error: (err, stack) => _ErrorProfileHeader(),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Achievements'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview tab
                _OverviewTab(
                  userProgressAsync: userProgressAsync,
                ),

                // Achievements tab
                _AchievementsTab(
                  achievementsAsync: achievementsAsync,
                ),

                // Analytics tab
                _AnalyticsTab(
                  userProgressAsync: userProgressAsync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile header with avatar, level, and stats
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with level badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/200?u=${progress.userId}',
                  ),
                  onBackgroundImageError: (_, _) {},
                ),
              ),
              Positioned(
                bottom: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(VibrantRadius.full),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    'Lv ${progress.level}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Username
          Text(
            'Scholar',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: VibrantSpacing.xs),

          // Rank
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(VibrantRadius.full),
            ),
            child: Text(
              progress.rank,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBadge(
                icon: Icons.local_fire_department_rounded,
                value: progress.currentStreak.toString(),
                label: 'Day Streak',
              ),
              _StatBadge(
                icon: Icons.emoji_events_rounded,
                value: progress.unlockedAchievements.length.toString(),
                label: 'Achievements',
              ),
              _StatBadge(
                icon: Icons.stars_rounded,
                value: progress.totalXp.toString(),
                label: 'Total XP',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Overview tab with progress and quick stats
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.userProgressAsync});

  final AsyncValue<UserProgress> userProgressAsync;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: userProgressAsync.when(
        data: (progress) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reading progress tracker
            ReadingProgressTracker(
              wordsRead: progress.wordsLearned,
              totalWords: progress.wordsLearned + 500, // Estimate
              currentStreak: progress.currentStreak,
              longestStreak: progress.longestStreak,
              pagesRead: progress.lessonsCompleted,
              timeSpentMinutes: progress.minutesStudied,
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: VibrantSpacing.xl),

            // Language progress
            _SectionHeader(
              icon: Icons.language_rounded,
              title: 'Language Progress',
            ),

            const SizedBox(height: VibrantSpacing.md),

            ...progress.languageXp.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                child: _LanguageProgressCard(
                  languageCode: entry.key,
                  xp: entry.value,
                  totalXp: progress.totalXp,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms)
                    .slideX(begin: 0.1, end: 0),
              );
            }),

            const SizedBox(height: VibrantSpacing.xl),

            // Recent activity
            _SectionHeader(
              icon: Icons.history_rounded,
              title: 'Recent Activity',
            ),

            const SizedBox(height: VibrantSpacing.md),

            ...progress.weeklyActivity.reversed.take(5).map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
                child: _ActivityItem(activity: activity),
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorState(error: err.toString()),
      ),
    );
  }
}

/// Achievements tab
class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.achievementsAsync});

  final AsyncValue<List<Achievement>> achievementsAsync;

  @override
  Widget build(BuildContext context) {
    return achievementsAsync.when(
      data: (achievements) => SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress summary
            _AchievementProgressSummary(achievements: achievements)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: VibrantSpacing.xl),

            // Achievement grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: VibrantSpacing.md,
                mainAxisSpacing: VibrantSpacing.md,
                childAspectRatio: 1.0,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return achievement_widget.AchievementShowcase(
                  achievement: _mapToWidgetAchievement(achievement),
                  onTap: () {
                    HapticService.medium();
                    SoundService.instance.tap();
                    // Show achievement details
                  },
                )
                    .animate()
                    .fadeIn(delay: (100 + index * 50).ms, duration: 300.ms)
                    .scale(begin: const Offset(0.9, 0.9));
              },
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorState(error: err.toString()),
    );
  }

  achievement_widget.Achievement _mapToWidgetAchievement(Achievement achievement) {
    return achievement_widget.Achievement(
      id: achievement.id,
      title: achievement.title,
      description: achievement.description,
      icon: _getIconFromName(achievement.iconName),
      rarity: achievement_widget.AchievementRarity.values.firstWhere(
        (r) => r.name == achievement.rarity.name,
      ),
      category: achievement_widget.AchievementCategory.lessons,
      xpReward: achievement.xpReward,
      totalSteps: 1,
      currentSteps: achievement.isUnlocked ? 1 : 0,
      unlockedAt: achievement.unlockedAt,
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'library_books':
        return Icons.library_books_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'stars':
        return Icons.stars_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

/// Analytics tab with charts and insights
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.userProgressAsync});

  final AsyncValue<UserProgress> userProgressAsync;

  @override
  Widget build(BuildContext context) {
    return userProgressAsync.when(
      data: (progress) => SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly activity chart
            _SectionHeader(
              icon: Icons.bar_chart_rounded,
              title: 'Weekly Activity',
            ),

            const SizedBox(height: VibrantSpacing.lg),

            _WeeklyActivityChart(weeklyActivity: progress.weeklyActivity)
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: VibrantSpacing.xl),

            // Learning insights
            _SectionHeader(
              icon: Icons.insights_rounded,
              title: 'Learning Insights',
            ),

            const SizedBox(height: VibrantSpacing.md),

            _InsightsGrid(progress: progress)
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorState(error: err.toString()),
    );
  }
}

/// Section header
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: VibrantSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Language progress card
class _LanguageProgressCard extends StatelessWidget {
  const _LanguageProgressCard({
    required this.languageCode,
    required this.xp,
    required this.totalXp,
  });

  final String languageCode;
  final int xp;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = (xp / totalXp * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.tertiaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getLanguageName(languageCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$xp XP',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(VibrantRadius.full),
            child: LinearProgressIndicator(
              value: xp / totalXp,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage% of total XP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'lat':
        return 'Classical Latin';
      case 'grc-cls':
        return 'Classical Greek';
      case 'grc-koi':
        return 'Koine Greek';
      case 'hbo':
        return 'Biblical Hebrew';
      default:
        return code.toUpperCase();
    }
  }
}

/// Activity item
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});

  final DailyActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(activity.date),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${activity.lessonsCompleted} lessons • ${activity.xpEarned} XP • ${activity.minutesStudied}min',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) return 'Today';
    if (activityDate == yesterday) return 'Yesterday';
    return '${date.month}/${date.day}';
  }
}

/// Achievement progress summary
class _AchievementProgressSummary extends StatelessWidget {
  const _AchievementProgressSummary({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final percentage = (unlockedCount / achievements.length * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: VibrantTheme.heroGradient,
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$percentage% Complete',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  '$unlockedCount of ${achievements.length} achievements',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 48,
          ),
        ],
      ),
    );
  }
}

/// Weekly activity chart
class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({required this.weeklyActivity});

  final List<DailyActivity> weeklyActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (weeklyActivity.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No activity data yet')),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: weeklyActivity.map((a) => a.xpEarned.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= weeklyActivity.length) return const Text('');
                  final date = weeklyActivity[value.toInt()].date;
                  return Text(
                    ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7],
                    style: theme.textTheme.labelSmall,
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: weeklyActivity.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.xpEarned.toDouble(),
                  gradient: VibrantTheme.heroGradient,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Insights grid
class _InsightsGrid extends StatelessWidget {
  const _InsightsGrid({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final avgMinutesPerDay = progress.weeklyActivity.isEmpty
        ? 0
        : progress.minutesStudied ~/ progress.weeklyActivity.length;
    final avgLessonsPerDay = progress.weeklyActivity.isEmpty
        ? 0.0
        : progress.lessonsCompleted / progress.weeklyActivity.length;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: VibrantSpacing.md,
      crossAxisSpacing: VibrantSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _InsightCard(
          icon: Icons.access_time_rounded,
          value: '${avgMinutesPerDay}min',
          label: 'Avg. Daily Study',
          color: Colors.blue,
        ),
        _InsightCard(
          icon: Icons.school_rounded,
          value: avgLessonsPerDay.toStringAsFixed(1),
          label: 'Lessons/Day',
          color: Colors.purple,
        ),
        _InsightCard(
          icon: Icons.trending_up_rounded,
          value: progress.rank,
          label: 'Current Rank',
          color: Colors.green,
        ),
        _InsightCard(
          icon: Icons.emoji_events_rounded,
          value: '${progress.longestStreak}',
          label: 'Best Streak',
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Loading and error states
class _LoadingProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Failed to load profile',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: VibrantSpacing.lg),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
