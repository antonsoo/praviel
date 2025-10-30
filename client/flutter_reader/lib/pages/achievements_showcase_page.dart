import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../models/achievement.dart';

/// Achievement showcase page displaying all unlocked and locked achievements
/// Celebrates user progress and motivates continued learning
class AchievementsShowcasePage extends ConsumerWidget {
  const AchievementsShowcasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final achievementService = ref.watch(achievementServiceProvider);

    final allAchievements = achievementService.achievements;
    final unlockedCount = achievementService.unlockedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: Column(
        children: [
          // Progress header
          _buildProgressHeader(
            context,
            theme,
            colorScheme,
            unlockedCount,
            allAchievements.length,
          ),

          // Achievement grid
          Expanded(
            child: allAchievements.isEmpty
                ? _buildEmptyState(theme, colorScheme)
                : GridView.builder(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: VibrantSpacing.md,
                      mainAxisSpacing: VibrantSpacing.md,
                    ),
                    itemCount: allAchievements.length,
                    itemBuilder: (context, index) {
                      final achievement = allAchievements[index];
                      return _buildAchievementCard(
                        context,
                        theme,
                        colorScheme,
                        achievement,
                        index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int unlocked,
    int total,
  ) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: VibrantTheme.heroGradient,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Trophy icon
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: VibrantSpacing.lg),

              // Progress info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      '$unlocked / $total unlocked',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Percentage
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(VibrantRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Achievement achievement,
    int index,
  ) {
    final isUnlocked = achievement.isUnlocked;

    return SlideInFromBottom(
      delay: Duration(milliseconds: index * 50),
      child: AnimatedScaleButton(
        onTap: () {
          HapticService.light();
          _showAchievementDetail(context, achievement);
        },
        child: Container(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          decoration: BoxDecoration(
            color: isUnlocked
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            border: Border.all(
              color: isUnlocked
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? VibrantTheme.heroGradient
                      : LinearGradient(
                          colors: [
                            colorScheme.surfaceContainerHigh,
                            colorScheme.surfaceContainerHigh,
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  achievement.icon,
                  size: 32,
                  color: isUnlocked
                      ? Colors.white
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),

              const SizedBox(height: VibrantSpacing.md),

              // Title
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUnlocked
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: VibrantSpacing.xs),

              // Description
              Text(
                achievement.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isUnlocked
                      ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (!isUnlocked && achievement.maxProgress > 1) ...[
                const SizedBox(height: VibrantSpacing.sm),
                // Progress indicator
                Text(
                  '${achievement.progress}/${achievement.maxProgress}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (!isUnlocked) ...[
                const SizedBox(height: VibrantSpacing.sm),
                Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'No achievements yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: VibrantSpacing.md),
            Text(
              'Start learning to unlock achievements!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    HapticService.medium();
    if (achievement.isUnlocked) {
      SoundService.instance.success();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AchievementDetailSheet(achievement: achievement),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Icon with glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: achievement.isUnlocked
                  ? VibrantTheme.heroGradient
                  : null,
              color: achievement.isUnlocked ? null : colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              achievement.icon,
              size: 48,
              color: achievement.isUnlocked
                  ? Colors.white
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Title
          Text(
            achievement.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: VibrantSpacing.md),

          // Description
          Text(
            achievement.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: VibrantSpacing.sm),

          // Requirement
          Text(
            achievement.requirement,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          if (achievement.isUnlocked) ...[
            const SizedBox(height: VibrantSpacing.xl),
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Text(
                    'Unlocked on ${achievement.unlockedAt?.toString().split(' ')[0] ?? 'Unknown'}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: VibrantSpacing.xl),
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Text(
                    'Progress: ${achievement.progress}/${achievement.maxProgress}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: VibrantSpacing.xl),

          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
