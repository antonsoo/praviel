import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../theme/professional_theme.dart';
import '../theme/vibrant_animations.dart';

/// Achievements display page
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final achievements = Achievements.all;
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final completion = unlockedCount / achievements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ProSpacing.xl,
                ProSpacing.xl,
                ProSpacing.xl,
                ProSpacing.lg,
              ),
              child: PulseCard(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.secondary,
                  ],
                ),
                padding: const EdgeInsets.all(ProSpacing.xl),
                borderRadius: BorderRadius.circular(ProRadius.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: ProSpacing.md),
                    Text(
                      'Achievements',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: ProSpacing.sm),
                    Text(
                      '$unlockedCount / ${achievements.length} unlocked',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: ProSpacing.md),
                    SizedBox(
                      height: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(ProRadius.lg),
                        child: LinearProgressIndicator(
                          value: completion.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ProSpacing.xl),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: ProSpacing.md,
                mainAxisSpacing: ProSpacing.md,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final achievement = achievements[index];
                return _AchievementCard(achievement: achievement);
              }, childCount: achievements.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: ProSpacing.xxxl)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLocked = !achievement.isUnlocked;

    return PulseCard(
      color: isLocked
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surface,
      gradient: isLocked
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.12),
                colorScheme.primary.withValues(alpha: 0.04),
              ],
            ),
      borderRadius: BorderRadius.circular(ProRadius.xl),
      padding: const EdgeInsets.all(ProSpacing.lg),
      elevation: isLocked ? 0 : 2,
      onTap: () => _showAchievementDetails(context, achievement),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLocked
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              achievement.icon,
              size: 32,
              color: isLocked
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.primary,
            ),
          ),
          const SizedBox(height: ProSpacing.md),
          Text(
            achievement.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isLocked ? colorScheme.onSurface : colorScheme.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ProSpacing.xs),
          Text(
            achievement.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLocked
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                  : colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isLocked) ...[
            const SizedBox(height: ProSpacing.sm),
            Icon(
              Icons.lock_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(ProSpacing.lg),
        title: Row(
          children: [
            Icon(achievement.icon, size: 32, color: colorScheme.primary),
            const SizedBox(width: ProSpacing.md),
            Expanded(
              child: Text(
                achievement.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: ProSpacing.lg),
            if (achievement.isUnlocked)
              PulseCard(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(ProRadius.lg),
                padding: const EdgeInsets.all(ProSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: colorScheme.primary),
                    const SizedBox(width: ProSpacing.sm),
                    Text(
                      'Unlocked!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              PulseCard(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(ProRadius.lg),
                padding: const EdgeInsets.all(ProSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: ProSpacing.sm),
                    Expanded(
                      child: Text(
                        'Keep learning to unlock this achievement!'
                        ' Lessons, streaks, and XP milestones count.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
