import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import 'dart:math' as math;

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

enum AchievementCategory {
  lessons,
  reading,
  vocabulary,
  streaks,
  social,
  special,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementRarity rarity;
  final AchievementCategory category;
  final int totalSteps;
  final int currentSteps;
  final DateTime? unlockedAt;
  final int xpReward;
  final String? specialReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.category,
    required this.totalSteps,
    this.currentSteps = 0,
    this.unlockedAt,
    required this.xpReward,
    this.specialReward,
  });

  bool get isUnlocked => unlockedAt != null;
  double get progress => totalSteps > 0 ? currentSteps / totalSteps : 0.0;
}

/// Premium achievement showcase with particles and animations
class AchievementShowcase extends StatefulWidget {
  const AchievementShowcase({
    super.key,
    required this.achievement,
    required this.onTap,
  });

  final Achievement achievement;
  final VoidCallback onTap;

  @override
  State<AchievementShowcase> createState() => _AchievementShowcaseState();
}

class _AchievementShowcaseState extends State<AchievementShowcase> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rarityColor = _getRarityColor(widget.achievement.rarity);

    return GestureDetector(
      onTap: () {
        HapticService.medium();
        SoundService.instance.success();
        widget.onTap();
      },
      child: Container(
        margin: const EdgeInsets.all(VibrantSpacing.sm),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.achievement.isUnlocked
                ? [
                    rarityColor.withValues(alpha: 0.3),
                    rarityColor.withValues(alpha: 0.1),
                  ]
                : [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    colorScheme.surfaceContainer.withValues(alpha: 0.3),
                  ],
          ),
          borderRadius: BorderRadius.circular(VibrantRadius.xl),
          border: Border.all(
            color: widget.achievement.isUnlocked
                ? rarityColor
                : colorScheme.outlineVariant,
            width: widget.achievement.isUnlocked ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Animated particles for unlocked achievements
            if (widget.achievement.isUnlocked)
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      animation: _particleController,
                      color: rarityColor,
                    ),
                    size: const Size(double.infinity, double.infinity),
                  );
                },
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with glow effect
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(VibrantSpacing.md),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: widget.achievement.isUnlocked
                              ? RadialGradient(
                                  colors: [
                                    rarityColor.withValues(alpha: 0.6 * _glowAnimation.value),
                                    rarityColor.withValues(alpha: 0.2 * _glowAnimation.value),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                )
                              : null,
                        ),
                        child: Icon(
                          widget.achievement.icon,
                          size: 40,
                          color: widget.achievement.isUnlocked
                              ? rarityColor
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: VibrantSpacing.sm),

                  // Rarity badge
                  _RarityBadge(rarity: widget.achievement.rarity),

                  const SizedBox(height: VibrantSpacing.xs),

                  // Title
                  Text(
                    widget.achievement.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.achievement.isUnlocked
                          ? rarityColor
                          : colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: VibrantSpacing.xs),

                  // Description
                  Text(
                    widget.achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: VibrantSpacing.md),

                  // Progress or unlock date
                  if (widget.achievement.isUnlocked) ...[
                    _UnlockInfo(
                      unlockedAt: widget.achievement.unlockedAt!,
                      xpReward: widget.achievement.xpReward,
                    ),
                  ] else ...[
                    _ProgressBar(
                      progress: widget.achievement.progress,
                      current: widget.achievement.currentSteps,
                      total: widget.achievement.totalSteps,
                      color: rarityColor,
                    ),
                  ],
                ],
              ),
            ),

            // Locked overlay
            if (!widget.achievement.isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(VibrantRadius.xl),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_outline, size: 32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
      case AchievementRarity.mythic:
        return const Color(0xFFFF1493); // Deep pink
    }
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final AchievementRarity rarity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = rarity.name[0].toUpperCase() + rarity.name.substring(1);
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
      case AchievementRarity.mythic:
        return const Color(0xFFFF1493);
    }
  }

  IconData _getIcon() {
    switch (rarity) {
      case AchievementRarity.common:
        return Icons.circle;
      case AchievementRarity.uncommon:
        return Icons.circle;
      case AchievementRarity.rare:
        return Icons.diamond_outlined;
      case AchievementRarity.epic:
        return Icons.diamond;
      case AchievementRarity.legendary:
        return Icons.stars_rounded;
      case AchievementRarity.mythic:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _UnlockInfo extends StatelessWidget {
  const _UnlockInfo({
    required this.unlockedAt,
    required this.xpReward,
  });

  final DateTime unlockedAt;
  final int xpReward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars_rounded,
              size: 14,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              '+$xpReward XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Text(
          _formatDate(unlockedAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Unlocked today';
    } else if (diff.inDays == 1) {
      return 'Unlocked yesterday';
    } else if (diff.inDays < 7) {
      return 'Unlocked ${diff.inDays} days ago';
    } else {
      return 'Unlocked ${date.month}/${date.day}/${date.year}';
    }
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.current,
    required this.total,
    required this.color,
  });

  final double progress;
  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          '$current / $total',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: VibrantSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Particle painter for celebration effect
class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _ParticlePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.3);

    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final distance = animation.value * 60;
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance;
      final radius = 3 * (1 - animation.value);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
