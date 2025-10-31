import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_providers.dart';
import '../models/achievement.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../theme/advanced_micro_interactions.dart';
import '../widgets/gamification/achievement_widgets.dart';
import '../widgets/micro_interactions.dart';
import '../widgets/language_selector_v2.dart';
import '../widgets/notifications/toast_notifications.dart';
import '../widgets/common/premium_cards.dart';
import '../widgets/profile/vibrant_profile_header.dart';
import '../widgets/progress/animated_progress.dart';
import 'progress_stats_page.dart';
import 'power_up_shop_page.dart';
import 'onboarding/auth_choice_screen.dart';

/// Handle language selection and persist to local storage + backend
Future<void> _handleLanguageSelection(
  BuildContext context,
  String languageCode,
  WidgetRef ref,
) async {
  // Save language preference to local storage
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);

    debugPrint(
      '[ProfilePage] Language preference saved locally: $languageCode',
    );

    // Sync to backend if user is authenticated
    final authService = ref.read(authServiceProvider);
    if (authService.isAuthenticated) {
      try {
        final userPrefsApi = ref.read(userPreferencesApiProvider);
        await userPrefsApi.updatePreferences(studyLanguage: languageCode);
        debugPrint(
          '[ProfilePage] Language preference synced to backend: $languageCode',
        );
      } catch (e) {
        debugPrint(
          '[ProfilePage] Failed to sync language preference to backend: $e',
        );
        // Still show success - local preference was saved
      }
    }
  } catch (e) {
    debugPrint('[ProfilePage] Failed to save language preference: $e');
  }

  // Show success confirmation for selected language
  if (!context.mounted) return;
  ToastNotification.show(
    context: context,
    message: '${_getLanguageName(languageCode)} is now your active language',
    title: 'Language Updated',
    type: ToastType.success,
  );
}

String _getLanguageName(String code) {
  switch (code) {
    case 'grc':
      return 'Classical Greek';
    case 'lat':
      return 'Classical Latin';
    case 'egy-old':
      return 'Old Egyptian';
    case 'san-vedic':
      return 'Vedic Sanskrit';
    case 'grc-koine':
      return 'Koine Greek';
    case 'sux':
      return 'Ancient Sumerian';
    case 'hbo-proto':
      return 'Proto-Hebrew';
    case 'chu':
      return 'Old Church Slavonic';
    case 'akk':
      return 'Akkadian';
    case 'hit':
      return 'Hittite';
    case 'ave':
      return 'Avestan';
    case 'arc':
      return 'Ancient Aramaic';
    case 'peo':
      return 'Old Persian';
    case 'nci':
      return 'Classical Nahuatl';
    case 'qwc':
      return 'Classical Quechua';
    case 'myn':
      return 'Classical Mayan';
    case 'hbo':
      return 'Biblical Hebrew';
    case 'egy':
      return 'Classical Egyptian';
    case 'san':
      return 'Classical Sanskrit';
    default:
      return 'this language';
  }
}

/// Vibrant profile page with stats dashboard and achievements
class VibrantProfilePage extends ConsumerWidget {
  const VibrantProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressServiceAsync = ref.watch(progressServiceProvider);
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: progressServiceAsync.when(
        data: (progressService) {
          return ListenableBuilder(
            listenable: progressService,
            builder: (context, _) {
              final xp = progressService.xpTotal;
              final streak = progressService.streakDays;
              final level = progressService.currentLevel;
              final progressToNext = progressService.progressToNextLevel;
              final pendingSyncCount = progressService.pendingSyncCount;
              final hasPendingSync = progressService.hasPendingSync;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: VibrantProfileHeader(
                      level: level,
                      xp: xp,
                      streak: streak,
                      progressToNext: progressToNext,
                      pendingSyncCount: hasPendingSync ? pendingSyncCount : 0,
                      onOpenSettings: () {
                        HapticService.light();
                        ToastNotification.show(
                          context: context,
                          message: 'Settings coming soon',
                          title: 'Settings',
                          type: ToastType.info,
                        );
                      },
                      onOpenStats: () {
                        HapticService.light();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProgressStatsPage(),
                          ),
                        );
                      },
                      onOpenShop: () {
                        HapticService.light();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PowerUpShopPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (!authService.isAuthenticated) ...[
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 120),
                            child: _buildGuestUpsellCard(
                              context,
                              ref,
                              theme,
                              colorScheme,
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.xl),
                        ],

                        if (hasPendingSync) ...[
                          SlideInFromBottom(
                            delay: const Duration(milliseconds: 160),
                            child: OfflineSyncBanner(
                              pendingCount: pendingSyncCount,
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.xl),
                        ],

                        // Stats cards
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 200),
                          child: _buildStatsGrid(
                            theme,
                            colorScheme,
                            xp,
                            streak,
                            level,
                            progressService,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Progress Statistics navigation card
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 250),
                          child: _buildProgressStatsCard(
                            context,
                            theme,
                            colorScheme,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.md),

                        // Power-Up Shop navigation card
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 275),
                          child: _buildPowerUpShopCard(
                            context,
                            theme,
                            colorScheme,
                          ),
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
                          child: _buildAchievements(
                            context,
                            theme,
                            colorScheme,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Activity heatmap placeholder
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 500),
                          child: _buildActivitySection(theme, colorScheme),
                        ),

                        const SizedBox(height: VibrantSpacing.xl),

                        // Language selector
                        SlideInFromBottom(
                          delay: const Duration(milliseconds: 600),
                          child: LanguageSelectorV2(
                            currentLanguage: 'grc',
                            onLanguageSelected: (languageCode) {
                              _handleLanguageSelection(
                                context,
                                languageCode,
                                ref,
                              );
                            },
                          ),
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
        loading: () => _buildLoadingFallback(theme, colorScheme),
        error: (error, stack) =>
            _buildOfflineProfileFallback(ref, theme, colorScheme, error),
      ),
    );
  }

  Widget _buildLoadingFallback(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: GlassCard(
            blur: 18,
            opacity: 0.2,
            borderRadius: VibrantRadius.xl,
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: VibrantSpacing.lg),
                Text(
                  'Loading your profile…',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  'Achievements and stats will appear in a moment.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineProfileFallback(
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    Object error,
  ) {
    debugPrint(
      '[VibrantProfilePage] Profile fell back to offline view: $error',
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            blur: 18,
            opacity: 0.2,
            borderRadius: VibrantRadius.xl,
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.offline_bolt_outlined,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: VibrantSpacing.lg),
                Text(
                  'Profile unavailable',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'We couldn\'t load your stats right now. Retry sync or sign in to restore your progress.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.xl),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(progressServiceProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry sync'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestUpsellCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GlassCard(
      blur: 18,
      opacity: 0.18,
      borderRadius: VibrantRadius.xl,
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rocket_launch, size: 56, color: colorScheme.primary),
          const SizedBox(height: VibrantSpacing.lg),
          Text(
            'Create a free account',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Sign in to save your progress, sync streaks, and unlock personalized achievements.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VibrantSpacing.xl),
          FilledButton.icon(
            icon: const Icon(Icons.login_rounded),
            label: const Text('Sign in or sign up'),
            onPressed: () async {
              HapticService.light();
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const AuthChoiceScreenWithOnboarding(),
                  fullscreenDialog: true,
                ),
              );
              if (result == true && context.mounted) {
                ref.invalidate(progressServiceProvider);
              }
            },
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
    dynamic progressService,
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
              child: InteractiveCard(
                onTap: () => AdvancedHaptics.light(),
                child: _StatCard(
                  icon: Icons.stars_rounded,
                  label: 'Total XP',
                  value: xp.toString(),
                  gradient: VibrantTheme.xpGradient,
                ),
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: InteractiveCard(
                onTap: () => AdvancedHaptics.light(),
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Day Streak',
                  value: streak.toString(),
                  gradient: VibrantTheme.streakGradient,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: InteractiveCard(
                onTap: () => AdvancedHaptics.light(),
                child: _StatCard(
                  icon: Icons.school_rounded,
                  label: 'Lessons',
                  value: progressService.totalLessons.toString(),
                  gradient: VibrantTheme.successGradient,
                ),
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: InteractiveCard(
                onTap: () => AdvancedHaptics.light(),
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Perfect',
                  value: progressService.perfectLessons.toString(),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
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
        HapticService.light();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProgressStatsPage()),
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
                      color: colorScheme.onSecondaryContainer.withValues(
                        alpha: 0.8,
                      ),
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

  Widget _buildPowerUpShopCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return MicroTap(
      onTap: () {
        HapticService.light();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PowerUpShopPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.3),
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: VibrantSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Power-Up Shop',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xxs),
                  Text(
                    'Boost your learning with power-ups',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
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
          AnimatedLinearProgress(
            progress: progress,
            height: 12,
            gradient: VibrantTheme.xpGradient,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
            TextButton(
              onPressed: () {
                HapticService.light();
                ToastNotification.show(
                  context: context,
                  message: 'Full achievements page coming soon',
                  title: 'Achievements',
                  type: ToastType.info,
                );
              },
              child: const Text('View all'),
            ),
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

class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key, required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headline = pendingCount == 1
        ? '1 lesson waiting to sync'
        : '$pendingCount lessons waiting to sync';

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  'We\'ll sync these automatically when you\'re back online. '
                  'You can also retry now if you have a connection.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync now'),
                    onPressed: () async {
                      try {
                        final service = await ref.read(
                          progressServiceProvider.future,
                        );
                        await service.processPendingQueue(force: true);
                        if (!context.mounted) {
                          return;
                        }
                        final remaining = service.pendingSyncCount;
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              remaining == 0
                                  ? 'All queued lessons synced!'
                                  : '$remaining lesson${remaining == 1 ? "" : "s"} still pending.',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sync failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
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
