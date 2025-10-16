import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../services/haptic_service.dart';
import '../services/lesson_history_store.dart';
import '../services/backend_progress_service.dart';
import '../theme/animations.dart';
import '../theme/premium_gradients.dart';
import '../theme/design_tokens.dart';
import '../widgets/animated_background.dart';
import '../widgets/premium_card.dart';
import '../widgets/stunning_buttons.dart';

/// COMPLETELY REDESIGNED home page with premium visuals
/// This is what a $50/month SaaS product looks like
class StunningHomePage extends ConsumerStatefulWidget {
  const StunningHomePage({
    super.key,
    required this.onStartLearning,
    required this.onViewHistory,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onViewHistory;

  @override
  ConsumerState<StunningHomePage> createState() => _StunningHomePageState();
}

class _StunningHomePageState extends ConsumerState<StunningHomePage> {
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
    final progressServiceAsync = ref.watch(progressServiceProvider);

    return progressServiceAsync.when(
      data: (progressService) {
        return ListenableBuilder(
          listenable: progressService,
          builder: (context, _) {
            return MeshGradientBackground(
              primaryColor: const Color(0xFF667EEA),
              secondaryColor: const Color(0xFF764BA2),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.space24),

                      // STUNNING Hero Section
                      _buildPremiumHero(theme, progressService),
                      const SizedBox(height: AppSpacing.space32),

                      // GORGEOUS Stats Cards
                      _buildStatsGrid(theme, progressService),
                      const SizedBox(height: AppSpacing.space32),

                      // BEAUTIFUL CTA
                      _buildPremiumCTA(theme, progressService),
                      const SizedBox(height: AppSpacing.space32),

                      // Recent Lessons (if any)
                      if (!_loadingHistory && _recentLessons != null)
                        _buildRecentSection(theme),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  /// Premium hero section with glass morphism
  Widget _buildPremiumHero(
    ThemeData theme,
    BackendProgressService progressService,
  ) {
    final hasProgress = progressService.hasProgress;
    final greeting = hasProgress
        ? 'Welcome Back, Scholar! 🎓'
        : 'Begin Your Ancient Greek Journey';
    final subtitle = hasProgress
        ? 'Continue your path to mastery'
        : 'Master the language of Homer, Plato, and Aristotle';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          if (hasProgress) ...[
            const SizedBox(height: AppSpacing.space24),
            // Progress bar with glow
            _buildGlowingProgressBar(theme, progressService),
          ],
        ],
      ),
    );
  }

  /// Glowing progress bar
  Widget _buildGlowingProgressBar(
    ThemeData theme,
    BackendProgressService progressService,
  ) {
    final progress = progressService.progressToNextLevel;
    final xpToNext = progressService.xpToNextLevel;
    final level = progressService.currentLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$xpToNext XP to next level',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),
        Stack(
          children: [
            // Glow effect
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Stunning stats grid
  Widget _buildStatsGrid(
    ThemeData theme,
    BackendProgressService progressService,
  ) {
    if (!progressService.hasProgress) {
      return GlassCard(
        child: Column(
          children: [
            Icon(
              Icons.rocket_launch,
              size: 80,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Start Your First Lesson',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Track your progress and build streaks',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
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

    // Get adaptive difficulty info
    final adaptiveDifficultyAsync = ref.watch(
      adaptiveDifficultyServiceProvider,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGlassStatCard(
                theme,
                value: '$streak',
                label: 'Day Streak',
                icon: Icons.local_fire_department,
                gradient: PremiumGradients.streakButton,
              ),
            ),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: _buildGlassStatCard(
                theme,
                value: '$xp',
                label: 'Total XP',
                icon: Icons.stars,
                gradient: PremiumGradients.premiumButton,
              ),
            ),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: _buildGlassStatCard(
                theme,
                value: '$level',
                label: 'Level',
                icon: Icons.military_tech,
                gradient: PremiumGradients.primaryButton,
              ),
            ),
          ],
        ),

        // Adaptive difficulty indicator
        adaptiveDifficultyAsync.when(
          data: (adaptiveDifficulty) {
            final insights = adaptiveDifficulty.getInsights();
            if (insights.totalExercises < 5) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space16),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Text(
                          'Difficulty: ${adaptiveDifficulty.difficultyLabel}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(insights.overallAccuracy * 100).toInt()}% accuracy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildGlassStatCard(
    ThemeData theme, {
    required String value,
    required String label,
    required IconData icon,
    required Gradient gradient,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: PremiumShadows.glow(gradient.colors.first),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.space12),
          AnimatedCounter(
            value: int.tryParse(value) ?? 0,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Premium CTA button
  Widget _buildPremiumCTA(
    ThemeData theme,
    BackendProgressService progressService,
  ) {
    final hasProgress = progressService.hasProgress;
    final buttonText = hasProgress ? 'Continue Learning' : 'Start Your Journey';
    final icon = hasProgress ? Icons.play_arrow : Icons.school;

    return PremiumGradientButton(
      label: buttonText,
      icon: icon,
      gradient: PremiumGradients.successButton,
      onPressed: () {
        HapticService.heavy();
        widget.onStartLearning();
      },
      width: double.infinity,
    );
  }

  /// Recent lessons section
  Widget _buildRecentSection(ThemeData theme) {
    final lessons = _recentLessons ?? [];
    if (lessons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Lessons',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Button3D(
              label: 'View All',
              color: Colors.white.withValues(alpha: 0.2),
              onPressed: widget.onViewHistory,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space16),
        ...lessons.map((entry) => _buildLessonCard(theme, entry)),
      ],
    );
  }

  Widget _buildLessonCard(ThemeData theme, LessonHistoryEntry entry) {
    final scorePercent = (entry.score * 100).toInt();
    final gradient = scorePercent >= 90
        ? PremiumGradients.successButton
        : scorePercent >= 70
        ? PremiumGradients.premiumButton
        : PremiumGradients.streakButton;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.textSnippet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '${entry.correctCount}/${entry.totalTasks} correct',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$scorePercent%',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
