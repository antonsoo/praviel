import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';

/// Achievements display page
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    // This would typically come from a provider
    final achievements = Achievements.all;
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: CustomScrollView(
        slivers: [
          // Header with stats
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(spacing.lg),
              padding: EdgeInsets.all(spacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '🏆',
                    style: const TextStyle(fontSize: 48),
                  ),
                  SizedBox(height: spacing.md),
                  Text(
                    'Achievements',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    '$unlockedCount / ${achievements.length} Unlocked',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  LinearProgressIndicator(
                    value: unlockedCount / achievements.length,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),

          // Achievements grid
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: spacing.md,
                mainAxisSpacing: spacing.md,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final achievement = achievements[index];
                  return _AchievementCard(achievement: achievement);
                },
                childCount: achievements.length,
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: spacing.xl)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final isLocked = !achievement.isUnlocked;

    return Card(
      elevation: isLocked ? 1 : 4,
      color: isLocked
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => _showAchievementDetails(context, achievement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isLocked
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: isLocked
                          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.md),

              // Title
              Text(
                achievement.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLocked
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacing.xs),

              // Description
              Text(
                achievement.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isLocked
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                      : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Lock indicator
              if (isLocked) ...[
                SizedBox(height: spacing.sm),
                Icon(
                  Icons.lock_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 32)),
            SizedBox(width: spacing.md),
            Expanded(
              child: Text(
                achievement.name,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: theme.textTheme.bodyLarge,
            ),
            if (achievement.isUnlocked) ...[
              SizedBox(height: spacing.lg),
              Container(
                padding: EdgeInsets.all(spacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: spacing.sm),
                    Text(
                      'Unlocked!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: spacing.lg),
              Container(
                padding: EdgeInsets.all(spacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        'Keep learning to unlock this achievement!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
