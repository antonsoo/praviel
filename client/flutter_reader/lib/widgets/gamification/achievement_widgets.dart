import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// Achievement badge widget
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = AchievementBadgeSize.medium,
    this.showProgress = true,
  });

  final Achievement achievement;
  final AchievementBadgeSize size;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconSize = size == AchievementBadgeSize.large
        ? 48.0
        : size == AchievementBadgeSize.medium
        ? 36.0
        : 28.0;
    final containerSize = size == AchievementBadgeSize.large
        ? 80.0
        : size == AchievementBadgeSize.medium
        ? 64.0
        : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            gradient: achievement.isUnlocked
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: achievement.isUnlocked
                ? null
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            boxShadow: achievement.isUnlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            achievement.icon,
            size: iconSize,
            color: achievement.isUnlocked
                ? Colors.white
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        if (showProgress && !achievement.isUnlocked) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: containerSize,
            height: 4,
            child: LinearProgressIndicator(
              value: achievement.progressPercentage,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ],
    );
  }
}

enum AchievementBadgeSize { small, medium, large }

/// Achievement card with details
class AchievementCard extends StatelessWidget {
  const AchievementCard({super.key, required this.achievement, this.onTap});

  final Achievement achievement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PulseCard(
      onTap: onTap,
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Row(
        children: [
          AchievementBadge(
            achievement: achievement,
            size: AchievementBadgeSize.medium,
            showProgress: false,
          ),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: achievement.isUnlocked
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xxs),
                Text(
                  achievement.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                if (!achievement.isUnlocked) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            value: achievement.progressPercentage,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.sm),
                      Text(
                        '${achievement.progress}/${achievement.maxProgress}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: VibrantSpacing.xxs),
                      Text(
                        'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Achievement unlock modal
class AchievementUnlockModal extends StatefulWidget {
  const AchievementUnlockModal({super.key, required this.achievement});

  final Achievement achievement;

  static Future<void> show({
    required BuildContext context,
    required Achievement achievement,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AchievementUnlockModal(achievement: achievement),
    );
  }

  @override
  State<AchievementUnlockModal> createState() => _AchievementUnlockModalState();
}

class _AchievementUnlockModalState extends State<AchievementUnlockModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.2),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.2, end: 1.0),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: VibrantCurve.playful),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(VibrantRadius.xxl),
              boxShadow: VibrantShadow.xl(colorScheme),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sparkle icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 32,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 32,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ],
                ),

                const SizedBox(height: VibrantSpacing.lg),

                Text(
                  'Achievement Unlocked!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: VibrantSpacing.xl),

                // Achievement badge
                AchievementBadge(
                  achievement: widget.achievement,
                  size: AchievementBadgeSize.large,
                  showProgress: false,
                ),

                const SizedBox(height: VibrantSpacing.lg),

                Text(
                  widget.achievement.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: VibrantSpacing.sm),

                Text(
                  widget.achievement.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: VibrantSpacing.xl),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Achievement grid for profile page
class AchievementGrid extends StatelessWidget {
  const AchievementGrid({super.key, required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
        final achievement = achievements[index];
        return GestureDetector(
          onTap: () => _showAchievementDetails(context, achievement),
          child: AchievementBadge(
            achievement: achievement,
            size: AchievementBadgeSize.small,
            showProgress: false,
          ),
        );
      },
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AchievementBadge(
                achievement: achievement,
                size: AchievementBadgeSize.large,
                showProgress: true,
              ),
              const SizedBox(height: VibrantSpacing.lg),
              Text(
                achievement.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                achievement.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VibrantSpacing.md),
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: VibrantSpacing.xs),
                    Text(
                      achievement.requirement,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
