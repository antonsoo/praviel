import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../services/lesson_history_store.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/home/animated_streak_flame.dart';
import '../widgets/home/xp_ring_progress.dart';
import '../widgets/home/achievement_carousel.dart';
import '../widgets/avatar/character_avatar.dart';
import '../widgets/gamification/achievement_widgets.dart';
import '../widgets/gamification/daily_goal_widget.dart';
import '../widgets/gamification/xp_counter.dart';
import '../models/achievement.dart';

/// VIBRANT home page - engaging, fun, addictive!
/// Shows progress, streaks, XP, goals, and quick actions
class VibrantHomePage extends ConsumerStatefulWidget {
  const VibrantHomePage({
    super.key,
    required this.onStartLearning,
    required this.onViewHistory,
    required this.onViewAchievements,
    required this.onViewSkillTree,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onViewHistory;
  final VoidCallback onViewAchievements;
  final VoidCallback onViewSkillTree;

  @override
  ConsumerState<VibrantHomePage> createState() => _VibrantHomePageState();
}

class _VibrantHomePageState extends ConsumerState<VibrantHomePage> {
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
            final xpForCurrentLevel = progressService.xpForCurrentLevel;
            final xpForNextLevel = progressService.xpForNextLevel;
            final progressToNext = progressService.progressToNextLevel;

            return Scaffold(
              backgroundColor: colorScheme.surfaceContainerLowest,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Custom app bar
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    elevation: 0,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    expandedHeight: 0,
                    collapsedHeight: kToolbarHeight,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        boxShadow: VibrantShadow.sm(colorScheme),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.lg,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ancient Greek',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (streak > 0)
                                StreakIndicator(streakDays: streak),
                              const SizedBox(width: VibrantSpacing.sm),
                              XPCounter(
                                xp: xp,
                                size: XPCounterSize.small,
                                showLabel: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  SliverPadding(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero greeting section
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 100),
                          child: _buildHeroSection(
                            theme,
                            colorScheme,
                            hasProgress,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Animated Streak Flame (new!)
                        if (streak > 0)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 200),
                            child: Column(
                              children: [
                                PulseCard(
                                  child: Row(
                                    children: [
                                      AnimatedStreakFlame(
                                        streakDays: streak,
                                        size: 72,
                                      ),
                                      const SizedBox(width: VibrantSpacing.lg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$streak Day Streak!',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: VibrantSpacing.xs),
                                            Text(
                                              streak >= 7
                                                  ? 'You\'re on fire! Keep it going!'
                                                  : 'Keep learning every day',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: VibrantSpacing.lg),
                              ],
                            ),
                          ),

                        // Daily goal widget
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 300),
                          child: _buildDailyGoalWidget(
                            theme,
                            colorScheme,
                            xp,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Quick action cards
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 400),
                          child: _buildQuickActions(theme, colorScheme),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // XP Ring Progress (new!)
                        if (hasProgress)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 500),
                            child: Center(
                              child: XPRingProgress(
                                currentLevel: level,
                                progressToNextLevel: progressToNext,
                                xpInCurrentLevel: xp - xpForCurrentLevel,
                                xpNeededForNextLevel:
                                    xpForNextLevel - xpForCurrentLevel,
                                size: 160,
                              ),
                            ),
                          ),

                        if (hasProgress) const SizedBox(height: VibrantSpacing.xl),

                        // Achievement carousel (new!)
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 600),
                          child: AchievementCarousel(
                            achievements: [
                              Achievements.firstWord.copyWith(isUnlocked: true),
                              Achievements.homersStudent.copyWith(isUnlocked: true),
                              Achievements.weekendWarrior.copyWith(isUnlocked: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Recent activity
                        if (!_loadingHistory && _recentLessons != null)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 700),
                            child: _buildRecentActivity(theme, colorScheme),
                          ),

                        const SizedBox(height: VibrantSpacing.xxxl),
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
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Unable to load progress'),
      ),
    );
  }

  Widget _buildHeroSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasProgress,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    // Pick avatar emotion based on time/progress
    final emotion = hour < 12
        ? AvatarEmotion.happy
        : (hasProgress ? AvatarEmotion.excited : AvatarEmotion.neutral);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated avatar
        BounceIn(
          child: CharacterAvatar(
            emotion: emotion,
            size: 80,
          ),
        ),
        const SizedBox(width: VibrantSpacing.lg),
        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting! 👋',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                hasProgress
                    ? 'Ready to continue your journey?'
                    : 'Ready to start learning Ancient Greek?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalWidget(
    ThemeData theme,
    ColorScheme colorScheme,
    int currentXP,
  ) {
    final dailyGoalServiceAsync = ref.watch(dailyGoalServiceProvider);

    return dailyGoalServiceAsync.when(
      data: (dailyGoalService) {
        return ListenableBuilder(
          listenable: dailyGoalService,
          builder: (context, _) {
            return DailyGoalCard(
              currentXP: dailyGoalService.currentProgress,
              goalXP: dailyGoalService.dailyGoalXP,
              streak: dailyGoalService.goalStreak,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => DailyGoalSettingModal(
                    currentGoal: dailyGoalService.dailyGoalXP,
                    onGoalChanged: (xp) => dailyGoalService.setDailyGoal(xp),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.school_rounded,
                title: 'New Lesson',
                subtitle: '+25 XP',
                gradient: VibrantTheme.heroGradient,
                onTap: widget.onStartLearning,
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.replay_rounded,
                title: 'Practice',
                subtitle: '+15 XP',
                gradient: VibrantTheme.successGradient,
                onTap: widget.onStartLearning,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.account_tree_rounded,
                title: 'Skill Tree',
                subtitle: 'View Progress',
                gradient: VibrantTheme.xpGradient,
                onTap: widget.onViewSkillTree,
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.emoji_events_rounded,
                title: 'Achievements',
                subtitle: 'View All',
                gradient: LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                onTap: widget.onViewAchievements,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Removed _buildLevelProgressCard - replaced with XPRingProgress widget

  Widget _buildAchievementsPreview(ThemeData theme, ColorScheme colorScheme) {
    // Mock achievements for preview - would load from storage
    final recentAchievements = [
      Achievements.firstWord.copyWith(isUnlocked: true),
      Achievements.homersStudent,
      Achievements.vocabularyTitan,
      Achievements.speedDemon,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAchievements,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: recentAchievements
              .map((achievement) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.xs,
                      ),
                      child: AchievementBadge(
                        achievement: achievement,
                        size: AchievementBadgeSize.medium,
                        showProgress: true,
                      ),
                    ),
                  ))
              .toList(),
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
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: widget.onViewHistory,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.md),
        ...lessons.map((entry) => _buildActivityItem(theme, colorScheme, entry)),
      ],
    );
  }

  Widget _buildActivityItem(
    ThemeData theme,
    ColorScheme colorScheme,
    LessonHistoryEntry entry,
  ) {
    final scorePercent = (entry.score * 100).toInt();
    final isPerfect = scorePercent >= 90;

    return Container(
      margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
      child: PulseCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isPerfect
                    ? VibrantTheme.successGradient
                    : LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerHigh,
                          colorScheme.surfaceContainerHighest,
                        ],
                      ),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Icon(
                isPerfect ? Icons.emoji_events_rounded : Icons.check_rounded,
                color: isPerfect ? Colors.white : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.textSnippet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: VibrantSpacing.xxs),
                  Text(
                    '${entry.correctCount}/${entry.totalTasks} correct • ${_formatDate(entry.timestamp)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Text(
              '$scorePercent%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isPerfect ? colorScheme.tertiary : colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(VibrantRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xxs),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
