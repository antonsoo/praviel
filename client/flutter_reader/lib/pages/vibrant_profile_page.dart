import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../models/achievement.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/gamification/achievement_widgets.dart';
import '../widgets/avatar/character_avatar.dart';
import '../widgets/micro_interactions.dart';
import 'progress_stats_page.dart';

/// Vibrant profile page with stats dashboard and achievements
class VibrantProfilePage extends ConsumerWidget {
  const VibrantProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressServiceAsync = ref.watch(progressServiceProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: progressServiceAsync.when(
        data: (progressService) {
          return ListenableBuilder(
            listenable: progressService,
            builder: (context, _) {
              final xp = progressService.xpTotal;
              final streak = progressService.streakDays;
              final level = progressService.currentLevel;
              final progressToNext = progressService.progressToNextLevel;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App bar
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    elevation: 0,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    title: Text(
                      'Profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // User header
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 100),
                          child: _buildUserHeader(theme, colorScheme, level),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Stats cards
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 200),
                          child: _buildStatsGrid(
                            theme,
                            colorScheme,
                            xp,
                            streak,
                            level,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Progress Statistics navigation card
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 250),
                          child: _buildProgressStatsCard(context, theme, colorScheme),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Level progress
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 300),
                          child: _buildLevelProgress(
                            theme,
                            colorScheme,
                            level,
                            progressToNext,
                            progressService.xpToNextLevel,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Achievements section
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 400),
                          child: _buildAchievements(theme, colorScheme),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Activity heatmap placeholder
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 500),
                          child: _buildActivitySection(theme, colorScheme),
                        ),

                        const SizedBox(height: VibrantSpacing.xxxl),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Unable to load profile')),
      ),
    );
  }

  Widget _buildUserHeader(ThemeData theme, ColorScheme colorScheme, int level) {
    return PulseCard(
      gradient: VibrantTheme.heroGradient,
      child: Row(
        children: [
          // Avatar with level badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const ClipOval(
                  child: CharacterAvatar(
                    emotion: AvatarEmotion.happy,
                    size: 74,
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: VibrantTheme.xpGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    level.toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: VibrantSpacing.lg),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scholar',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xxs),
                Text(
                  'Level $level',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    ThemeData theme,
    ColorScheme colorScheme,
    int xp,
    int streak,
    int level,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.stars_rounded,
                label: 'Total XP',
                value: xp.toString(),
                gradient: VibrantTheme.xpGradient,
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Day Streak',
                value: streak.toString(),
                gradient: VibrantTheme.streakGradient,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.book_rounded,
                label: 'Words Learned',
                value: '47', // Would come from tracking
                gradient: VibrantTheme.successGradient,
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                label: 'Achievements',
                value: '3/15',
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressStatsCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return MicroTap(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProgressStatsPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Icon(
                Icons.timeline_rounded,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: VibrantSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Statistics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xxs),
                  Text(
                    'View detailed performance metrics',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(
    ThemeData theme,
    ColorScheme colorScheme,
    int level,
    double progress,
    int xpToNext,
  ) {
    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$xpToNext XP to Level ${level + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: VibrantTheme.xpGradient,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(ThemeData theme, ColorScheme colorScheme) {
    // Mock achievements
    final achievements = [
      Achievements.firstWord.copyWith(isUnlocked: true),
      Achievements.homersStudent.copyWith(progress: 2),
      Achievements.marathonRunner.copyWith(progress: 12),
      Achievements.vocabularyTitan.copyWith(progress: 47),
      Achievements.speedDemon,
      Achievements.perfectScholar.copyWith(progress: 1),
      Achievements.earlyBird,
      Achievements.nightOwl,
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
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: VibrantSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: VibrantSpacing.md,
            crossAxisSpacing: VibrantSpacing.md,
            childAspectRatio: 1.0,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return AchievementBadge(
              achievement: achievements[index],
              size: AchievementBadgeSize.medium,
              showProgress: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivitySection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        PulseCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 7 days',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '5 lessons completed',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.lg),
              // Simple week visualization
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final hasActivity = i >= 2; // Mock data
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasActivity
                          ? colorScheme.tertiary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: hasActivity
                        ? Icon(
                            Icons.check_rounded,
                            color: colorScheme.onTertiary,
                            size: 20,
                          )
                        : null,
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
