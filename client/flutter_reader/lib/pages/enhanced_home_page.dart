import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../features/gamification/presentation/providers/gamification_providers.dart';
import '../features/gamification/domain/models/user_progress.dart';
import '../widgets/challenges/daily_challenge_card.dart' as challenge_widget;

/// Professional home page following Material Design 3 and top-tier app UX patterns
/// Researched from Duolingo, Babbel, and Material 3 Expressive guidelines
class EnhancedHomePage extends ConsumerStatefulWidget {
  const EnhancedHomePage({super.key});

  @override
  ConsumerState<EnhancedHomePage> createState() => _EnhancedHomePageState();
}

class _EnhancedHomePageState extends ConsumerState<EnhancedHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _greetingController;

  @override
  void initState() {
    super.initState();

    // Set mock user ID for development
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentUserIdProvider.notifier).setUserId('demo_user_123');
    });

    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // <300ms as per research
    );

    _greetingController.forward();
  }

  @override
  void dispose() {
    _greetingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userProgressAsync = ref.watch(userProgressProvider);
    final dailyChallengesAsync = ref.watch(dailyChallengesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProgressProvider);
          ref.invalidate(dailyChallengesProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // App bar with greeting and streak
            SliverAppBar.large(
              floating: true,
              snap: true,
              backgroundColor: colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                        colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.only(
                  left: VibrantSpacing.lg,
                  right: VibrantSpacing.lg,
                  bottom: VibrantSpacing.lg,
                ),
                title: userProgressAsync.when(
                  data: (progress) => _GreetingSection(progress: progress)
                      .animate(controller: _greetingController)
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                  loading: () => _LoadingGreeting(),
                  error: (err, stack) => _ErrorGreeting(),
                ),
              ),
            ),

            // Main content
            SliverPadding(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // User progress summary
                  userProgressAsync.when(
                    data: (progress) => _ProgressSummaryCard(progress: progress)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 250.ms)
                        .slideY(begin: 0.1, end: 0),
                    loading: () => _LoadingCard(),
                    error: (err, stack) => _ErrorCard(error: err.toString()),
                  ),

                  const SizedBox(height: VibrantSpacing.lg),

                  // Section header: Daily Challenges
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: VibrantSpacing.sm),
                      Text(
                        'Daily Challenges',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 250.ms)
                      .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: VibrantSpacing.md),

                  // Daily challenges
                  dailyChallengesAsync.when(
                    data: (challenges) => Column(
                      children: challenges.asMap().entries.map((entry) {
                        final index = entry.key;
                        final challenge = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                          child: _ChallengeCard(challenge: challenge)
                              .animate()
                              .fadeIn(
                                delay: (300 + index * 100).ms,
                                duration: 250.ms,
                              )
                              .slideX(begin: 0.1, end: 0),
                        );
                      }).toList(),
                    ),
                    loading: () => Column(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                          child: _LoadingCard(),
                        ),
                      ),
                    ),
                    error: (err, stack) => _ErrorCard(error: err.toString()),
                  ),

                  const SizedBox(height: VibrantSpacing.lg),

                  // Quick actions
                  Row(
                    children: [
                      Icon(
                        Icons.flash_on_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: VibrantSpacing.sm),
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 250.ms)
                      .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: VibrantSpacing.md),

                  _QuickActionsGrid()
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 250.ms)
                      .scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: VibrantSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Greeting section with user name and streak
class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: progress.isStreakActive
                    ? LinearGradient(
                        colors: [Colors.orange.shade400, Colors.red.shade400],
                      )
                    : null,
                color: progress.isStreakActive ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: progress.isStreakActive ? Colors.white : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${progress.currentStreak} day streak',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: progress.isStreakActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Level ${progress.level}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    if (hour < 22) return 'Good evening!';
    return 'Still studying?';
  }
}

/// Progress summary card with XP and stats
class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          SoundService.instance.tap();
          // TODO: Navigate to profile/stats page
        },
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        child: Container(
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
          child: Column(
            children: [
              // XP Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${progress.level}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${progress.totalXp} XP',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: VibrantSpacing.md),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${progress.level + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '${(progress.progressToNextLevel * 100).toInt()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VibrantRadius.full),
                    child: LinearProgressIndicator(
                      value: progress.progressToNextLevel,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: VibrantSpacing.lg),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.menu_book_rounded,
                    value: progress.lessonsCompleted.toString(),
                    label: 'Lessons',
                  ),
                  _StatItem(
                    icon: Icons.translate_rounded,
                    value: progress.wordsLearned.toString(),
                    label: 'Words',
                  ),
                  _StatItem(
                    icon: Icons.access_time_rounded,
                    value: _formatMinutes(progress.minutesStudied),
                    label: 'Time',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Challenge card wrapper
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return challenge_widget.DailyChallengeCard(
      challenge: challenge_widget.Challenge(
        id: challenge.id,
        title: challenge.title,
        description: challenge.description,
        difficulty: _mapDifficulty(challenge.difficulty),
        type: _mapType(challenge.type),
        xpReward: challenge.xpReward,
        coinReward: challenge.coinsReward,
        expiresAt: challenge.expiresAt,
        isCompleted: challenge.isCompleted,
        currentProgress: challenge.progress.current,
        targetProgress: challenge.progress.target,
      ),
      onTap: () {
        HapticService.medium();
        SoundService.instance.tap();
        // TODO: Navigate to challenge details
      },
    );
  }

  challenge_widget.ChallengeDifficulty _mapDifficulty(ChallengeDifficulty diff) {
    return challenge_widget.ChallengeDifficulty.values.firstWhere(
      (e) => e.name == diff.name,
    );
  }

  challenge_widget.ChallengeType _mapType(ChallengeType type) {
    return challenge_widget.ChallengeType.values.firstWhere(
      (e) => e.name == type.name,
    );
  }
}

/// Quick actions grid
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: VibrantSpacing.md,
      crossAxisSpacing: VibrantSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _QuickActionButton(
          icon: Icons.auto_stories_rounded,
          label: 'Start Reading',
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          onTap: () {
            HapticService.medium();
            SoundService.instance.tap();
            // TODO: Navigate to reader
          },
        ),
        _QuickActionButton(
          icon: Icons.school_rounded,
          label: 'New Lesson',
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
          ),
          onTap: () {
            HapticService.medium();
            SoundService.instance.tap();
            // TODO: Navigate to lesson
          },
        ),
        _QuickActionButton(
          icon: Icons.psychology_rounded,
          label: 'Practice',
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
          onTap: () {
            HapticService.medium();
            SoundService.instance.tap();
            // TODO: Navigate to practice
          },
        ),
        _QuickActionButton(
          icon: Icons.leaderboard_rounded,
          label: 'Leaderboard',
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          onTap: () {
            HapticService.medium();
            SoundService.instance.tap();
            // TODO: Navigate to leaderboard
          },
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Loading and error states
class _LoadingGreeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _ErrorGreeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('Welcome back!');
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Text(
              'Failed to load data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
