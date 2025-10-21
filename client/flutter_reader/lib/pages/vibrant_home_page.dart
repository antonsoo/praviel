import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../services/lesson_history_store.dart';
import '../services/language_preferences.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/home/animated_streak_flame.dart';
import '../widgets/home/xp_ring_progress.dart';
import '../widgets/home/achievement_carousel.dart';
import '../widgets/avatar/character_avatar.dart';
import '../widgets/gamification/achievement_widgets.dart';
import '../widgets/gamification/daily_goal_widget.dart';
import '../widgets/gamification/daily_challenges_widget.dart';
import '../widgets/gamification/weekly_challenges_widget.dart';
import '../widgets/gamification/xp_counter.dart';
import '../widgets/gamification/power_up_shop.dart';
import '../widgets/gamification/streak_shield_widget.dart';
import '../widgets/gamification/commitment_challenge_card.dart';
import '../widgets/gamification/double_or_nothing_modal.dart';
import '../widgets/premium_snackbars.dart';
import '../widgets/premium_celebrations.dart';
import '../models/achievement.dart';
import '../models/language.dart';
import '../widgets/language_selector_v2.dart';
import '../widgets/ancient_label.dart';
import 'progress_stats_page.dart';
import 'leaderboard_page.dart';
import 'vocabulary_practice_page.dart';

/// VIBRANT home page - engaging, fun, addictive!
/// Shows progress, streaks, XP, goals, and quick actions
class VibrantHomePage extends ConsumerStatefulWidget {
  const VibrantHomePage({
    super.key,
    required this.onStartLearning,
    required this.onViewHistory,
    required this.onViewAchievements,
    required this.onViewSkillTree,
    this.onViewSrsFlashcards,
    this.onViewQuests,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onViewHistory;
  final VoidCallback onViewAchievements;
  final VoidCallback onViewSkillTree;
  final VoidCallback? onViewSrsFlashcards;
  final VoidCallback? onViewQuests;

  @override
  ConsumerState<VibrantHomePage> createState() => _VibrantHomePageState();
}

class _VibrantHomePageState extends ConsumerState<VibrantHomePage> {
  final LessonHistoryStore _historyStore = LessonHistoryStore();
  List<LessonHistoryEntry>? _recentLessons;
  bool _loadingHistory = true;
  bool _showCelebration = false;
  bool _showAchievementBurst = false;

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

  Future<void> _refreshChallenges() async {
    final challengeService = await ref.read(
      dailyChallengeServiceProvider.future,
    );
    await challengeService.refresh();
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
            final progressToNext = xpForNextLevel > 0
                ? (xp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel)
                : 0.0;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refreshChallenges,
                    child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        VibrantSpacing.lg,
                        VibrantSpacing.xl,
                        VibrantSpacing.lg,
                        VibrantSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Hero greeting section
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 100),
                            child: _buildHeroSection(
                              theme,
                              colorScheme,
                              hasProgress,
                              streak,
                              level,
                              xp,
                              xp - xpForCurrentLevel,
                              xpForNextLevel - xpForCurrentLevel,
                              progressToNext,
                            ),
                          ),

                          const SizedBox(height: VibrantSpacing.xl),

                          // Language selector card
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 150),
                            child: _buildLanguageSelector(theme, colorScheme),
                          ),

                          const SizedBox(height: VibrantSpacing.lg),

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
                                        const SizedBox(
                                          width: VibrantSpacing.lg,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$streak Day Streak!',
                                                style: theme
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(
                                                height: VibrantSpacing.xs,
                                              ),
                                              Text(
                                                streak >= 7
                                                    ? 'You\'re on fire! Keep it going!'
                                                    : 'Keep learning every day',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
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

                          const SizedBox(height: VibrantSpacing.lg),

                          // Daily challenges widget (NEW - drives engagement!)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 350),
                            child: const DailyChallengesCard(),
                          ),

                          const SizedBox(height: VibrantSpacing.md),

                          // Weekly special challenges (LIMITED TIME - 5-10x rewards!)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 375),
                            child: _WeeklyChallengesSection(),
                          ),

                          const SizedBox(height: VibrantSpacing.md),

                          // Streak protection shop
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 390),
                            child: const StreakShieldWidget(),
                          ),

                          const SizedBox(height: VibrantSpacing.md),

                          // Streak repair prompt (only shows when relevant)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 410),
                            child: const StreakRepairWidget(),
                          ),

                          const SizedBox(height: VibrantSpacing.md),

                          // Double or Nothing challenge (sunk cost + commitment)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 440),
                            child: _DoubleOrNothingSection(),
                          ),

                          const SizedBox(height: VibrantSpacing.xl),

                          // Quick action cards
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 480),
                            child: _buildQuickActions(
                              theme,
                              colorScheme,
                              hasProgress,
                            ),
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

                          if (hasProgress)
                            const SizedBox(height: VibrantSpacing.xl),

                          // Achievement carousel (new!)
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 600),
                            child: AchievementCarousel(
                              achievements: [
                                Achievements.firstWord.copyWith(
                                  isUnlocked: true,
                                ),
                                Achievements.homersStudent.copyWith(
                                  isUnlocked: true,
                                ),
                                Achievements.weekendWarrior.copyWith(
                                  isUnlocked: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: VibrantSpacing.lg),

                          // Achievements preview grid
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 650),
                            child: _buildAchievementsPreview(
                              theme,
                              colorScheme,
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
                  ),

                  // Celebration overlay - shows confetti when triggered
                  if (_showCelebration)
                    Positioned.fill(
                      child: ConfettiBurst(
                        isActive: _showCelebration,
                        onComplete: () {
                          if (mounted) {
                            setState(() => _showCelebration = false);
                          }
                        },
                      ),
                    ),

                  // Achievement burst overlay
                  if (_showAchievementBurst)
                    Positioned.fill(
                      child: StarBurst(
                        isActive: _showAchievementBurst,
                        onComplete: () {
                          if (mounted) {
                            setState(() => _showAchievementBurst = false);
                          }
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Unable to load progress')),
    );
  }

  Widget _buildLanguageSelector(ThemeData theme, ColorScheme colorScheme) {
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final languageInfo = availableLanguages.firstWhere(
      (lang) => lang.code == selectedLanguage,
      orElse: () => availableLanguages.first,
    );

    return PulseCard(
      child: InkWell(
        onTap: _showLanguageSelector,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          child: Row(
            children: [
              // Language flag/icon
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Text(
                  languageInfo.flag,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: VibrantSpacing.lg),
              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Language',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xxs),
                    Text(
                      languageInfo.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Use AncientLabel for historically accurate rendering
                    AncientLabel(
                      language: languageInfo,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.start,
                      showTooltip: false,
                    ),
                  ],
                ),
              ),
              // Change indicator
              Icon(Icons.edit_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguageSelector() async {
    final selectedLanguage = ref.read(selectedLanguageProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: LanguageSelectorV2(
            currentLanguage: selectedLanguage,
            onLanguageSelected: (languageCode) {
              ref
                  .read(selectedLanguageProvider.notifier)
                  .setLanguage(languageCode);
              Navigator.of(context).pop();

              // Show premium snackbar with language change
              final languageInfo = availableLanguages.firstWhere(
                (lang) => lang.code == languageCode,
                orElse: () => availableLanguages.first,
              );
              PremiumSnackBar.success(
                context,
                message: 'Switched to ${languageInfo.name}',
                title: '${languageInfo.flag} Language Changed',
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasProgress,
    int streak,
    int level,
    int totalXp,
    int xpIntoLevel,
    int xpRequiredForLevel,
    double progressToNext,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    final emotion = hour < 12
        ? AvatarEmotion.happy
        : (hasProgress ? AvatarEmotion.excited : AvatarEmotion.neutral);

    final effectiveRequired = xpRequiredForLevel <= 0 ? 1 : xpRequiredForLevel;
    final effectiveInto = xpIntoLevel.clamp(0, effectiveRequired);
    final progress = progressToNext.isNaN
        ? 0.0
        : progressToNext.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        gradient: VibrantTheme.heroGradient,
        borderRadius: BorderRadius.circular(VibrantRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BounceIn(child: CharacterAvatar(emotion: emotion, size: 96)),
              const SizedBox(width: VibrantSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, scholar!',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      hasProgress
                          ? 'Pick up where you left off and keep that streak blazing.'
                          : 'Ready to unlock the classics? Your first lesson is moments away.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Column(
                children: [
                  // Shop button
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const PowerUpShopBottomSheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Shop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  XPCounter(
                    xp: totalXp,
                    size: XPCounterSize.medium,
                    showLabel: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Wrap(
            spacing: VibrantSpacing.md,
            runSpacing: VibrantSpacing.sm,
            children: [
              _HeroStatChip(
                icon: Icons.local_fire_department,
                label: 'Current streak',
                value: streak > 0 ? '$streak days' : 'No streak yet',
              ),
              _HeroStatChip(
                icon: Icons.workspace_premium_outlined,
                label: 'Level',
                value: 'Level $level',
              ),
              _HeroStatChip(
                icon: Icons.flash_on_rounded,
                label: 'Lifetime XP',
                value: '$totalXp XP',
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.lg),
          _HeroProgressBar(
            progress: progress,
            xpIntoLevel: effectiveInto,
            xpRequired: effectiveRequired,
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Wrap(
            spacing: VibrantSpacing.md,
            runSpacing: VibrantSpacing.sm,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.xl,
                    vertical: VibrantSpacing.md,
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: widget.onStartLearning,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(hasProgress ? 'Continue lesson' : 'Start learning'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.xl,
                    vertical: VibrantSpacing.md,
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: widget.onViewSkillTree,
                icon: const Icon(Icons.auto_graph_rounded),
                label: const Text('Explore skill tree'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.lg,
                    vertical: VibrantSpacing.sm,
                  ),
                ),
                onPressed: widget.onViewHistory,
                icon: const Icon(Icons.history_toggle_off),
                label: const Text('Review history'),
              ),
            ],
          ),
        ],
      ),
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
      error: (_, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasProgress,
  ) {
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
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final double spacing = VibrantSpacing.md;
            final bool isStacked = maxWidth < 640;
            final bool isTwoColumn = maxWidth < 1020;
            final double cardWidth;
            if (isStacked) {
              cardWidth = maxWidth;
            } else if (isTwoColumn) {
              cardWidth = (maxWidth - spacing) / 2;
            } else {
              cardWidth = (maxWidth - (spacing * 2)) / 3;
            }

            final cards = <Widget>[
              _QuickActionCard(
                icon: hasProgress
                    ? Icons.play_circle_rounded
                    : Icons.school_rounded,
                title: hasProgress ? 'Continue lesson' : 'Start lesson',
                subtitle: hasProgress
                    ? 'Pick up right where you stopped'
                    : '+25 XP boost today',
                gradient: VibrantTheme.heroGradient,
                onTap: widget.onStartLearning,
              ),
              _QuickActionCard(
                icon: Icons.abc_rounded,
                title: 'Vocabulary Practice',
                subtitle: 'Master new words',
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                ),
                onTap: () {
                  final vocabularyApi = ref.read(vocabularyApiProvider);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VocabularyPracticePage(
                        vocabularyApi: vocabularyApi,
                      ),
                    ),
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.refresh_rounded,
                title: 'Daily practice',
                subtitle: 'Strengthen tricky words',
                gradient: VibrantTheme.successGradient,
                onTap: widget.onStartLearning,
              ),
              _QuickActionCard(
                icon: Icons.timeline_rounded,
                title: 'Progress Stats',
                subtitle: 'Track your improvement',
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProgressStatsPage(),
                    ),
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.auto_graph_rounded,
                title: 'Skill tree',
                subtitle: 'Plan your next unlock',
                gradient: VibrantTheme.subtleGradient,
                onTap: widget.onViewSkillTree,
              ),
              _QuickActionCard(
                icon: Icons.emoji_events_rounded,
                title: 'Achievements',
                subtitle: 'Celebrate milestones',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                onTap: widget.onViewAchievements,
              ),
              if (widget.onViewSrsFlashcards != null)
                _QuickActionCard(
                  icon: Icons.style_rounded,
                  title: 'SRS Flashcards',
                  subtitle: 'Spaced repetition',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  onTap: widget.onViewSrsFlashcards!,
                ),
              if (widget.onViewQuests != null)
                _QuickActionCard(
                  icon: Icons.explore_rounded,
                  title: 'Quests',
                  subtitle: 'Long-term goals',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF059669)],
                  ),
                  onTap: widget.onViewQuests!,
                ),
              _QuickActionCard(
                icon: Icons.leaderboard_rounded,
                title: 'Leaderboard',
                subtitle: 'Compete with friends',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LeaderboardPage(),
                    ),
                  );
                },
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

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
              .map(
                (achievement) => Expanded(
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
                ),
              )
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

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: VibrantSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroProgressBar extends StatelessWidget {
  const _HeroProgressBar({
    required this.progress,
    required this.xpIntoLevel,
    required this.xpRequired,
  });

  final double progress;
  final int xpIntoLevel;
  final int xpRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRequired = xpRequired <= 0 ? 1 : xpRequired;
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final safeInto = xpIntoLevel.clamp(0, effectiveRequired).toInt();
    final remaining = (effectiveRequired - safeInto)
        .clamp(0, effectiveRequired)
        .toInt();
    final percent = (safeProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VibrantRadius.md),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 12,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$safeInto / $effectiveRequired XP',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$remaining XP to next level',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Text(
          '$percent% of the way there',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
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
        constraints: const BoxConstraints(minHeight: 140),
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
                child: Icon(icon, color: Colors.white, size: 28),
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

/// Weekly challenges section - connects to backend API
class _WeeklyChallengesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendServiceAsync = ref.watch(backendChallengeServiceProvider);

    return backendServiceAsync.when(
      data: (service) {
        final challenges = service.weeklyChallenges;
        if (challenges.isEmpty) {
          return const SizedBox.shrink();
        }

        return WeeklyChallengesCard(
          challenges: challenges,
          onRefresh: () async {
            await service.refresh();
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// Double or Nothing challenge section - sunk cost + commitment psychology
class _DoubleOrNothingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendServiceAsync = ref.watch(backendChallengeServiceProvider);

    return backendServiceAsync.when(
      data: (service) {
        final challenge = service.doubleOrNothingStatus;

        if (challenge == null) {
          return const SizedBox.shrink();
        }

        // Show active challenge or prompt to start
        if (challenge.hasActiveChallenge) {
          return CommitmentChallengeCard(
            challenge: challenge,
            onTap: () {
              // Could show detailed progress modal
            },
          );
        } else {
          return StartCommitmentChallengeCard(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const DoubleOrNothingModal(),
              );
            },
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
