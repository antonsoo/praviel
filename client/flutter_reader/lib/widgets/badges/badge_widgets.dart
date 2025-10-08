import 'package:flutter/material.dart' hide Badge;
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../models/badge.dart';

/// Badge display widget
class BadgeWidget extends StatelessWidget {
  const BadgeWidget({
    required this.badge,
    this.size = 80,
    this.isEarned = false,
    this.showLabel = true,
    this.onTap,
    super.key,
  });

  final Badge badge;
  final double size;
  final bool isEarned;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScaleButton(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: isEarned
                  ? LinearGradient(
                      colors: [
                        badge.rarity.color,
                        badge.rarity.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEarned ? null : Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isEarned
                    ? badge.rarity.color
                    : Colors.grey.withValues(alpha: 0.5),
                width: 3,
              ),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: badge.rarity.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              badge.icon,
              size: size * 0.5,
              color: isEarned ? Colors.white : Colors.grey,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: VibrantSpacing.xs),
            Text(
              badge.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isEarned ? null : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Badge unlock animation
class BadgeUnlockModal extends StatefulWidget {
  const BadgeUnlockModal({
    required this.badge,
    this.onClose,
    super.key,
  });

  final Badge badge;
  final VoidCallback? onClose;

  static Future<void> show({
    required BuildContext context,
    required Badge badge,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BadgeUnlockModal(badge: badge, onClose: onClose),
    );
  }

  @override
  State<BadgeUnlockModal> createState() => _BadgeUnlockModalState();
}

class _BadgeUnlockModalState extends State<BadgeUnlockModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.xxl),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(VibrantRadius.xl),
          boxShadow: VibrantShadow.xl(colorScheme),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Badge Unlocked!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: VibrantSpacing.xl),

            // Animated badge
            ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotateAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.badge.rarity.color,
                        widget.badge.rarity.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.badge.rarity.color.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.badge.icon,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Rarity label
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.md,
                vertical: VibrantSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: widget.badge.rarity.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Text(
                widget.badge.rarity.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: widget.badge.rarity.color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.md),

            // Badge name
            Text(
              widget.badge.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            Text(
              widget.badge.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.lg),

            // Rewards
            if (widget.badge.xpReward > 0 || widget.badge.coinReward > 0)
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.badge.xpReward > 0) ...[
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: VibrantSpacing.xs),
                      Text(
                        '+${widget.badge.xpReward} XP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (widget.badge.xpReward > 0 && widget.badge.coinReward > 0)
                      const SizedBox(width: VibrantSpacing.lg),
                    if (widget.badge.coinReward > 0) ...[
                      Icon(
                        Icons.monetization_on_rounded,
                        color: const Color(0xFFFFD700),
                        size: 20,
                      ),
                      const SizedBox(width: VibrantSpacing.xs),
                      Text(
                        '+${widget.badge.coinReward} Coins',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: VibrantSpacing.xl),

            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onClose?.call();
              },
              child: const Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge collection grid
class BadgeCollectionGrid extends StatelessWidget {
  const BadgeCollectionGrid({
    required this.badges,
    required this.earnedBadgeIds,
    this.onBadgeTap,
    super.key,
  });

  final List<Badge> badges;
  final Set<String> earnedBadgeIds;
  final Function(Badge)? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: VibrantSpacing.sm,
        mainAxisSpacing: VibrantSpacing.sm,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isEarned = earnedBadgeIds.contains(badge.id);

        return BadgeWidget(
          badge: badge,
          isEarned: isEarned,
          onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
        );
      },
    );
  }
}

/// Badge details modal
class BadgeDetailsModal extends StatelessWidget {
  const BadgeDetailsModal({
    required this.badge,
    required this.isEarned,
    this.earnedAt,
    super.key,
  });

  final Badge badge;
  final bool isEarned;
  final DateTime? earnedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BadgeWidget(
            badge: badge,
            size: 120,
            isEarned: isEarned,
            showLabel: false,
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Rarity
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.md,
              vertical: VibrantSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: badge.rarity.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(VibrantRadius.md),
            ),
            child: Text(
              badge.rarity.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: badge.rarity.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: VibrantSpacing.md),

          Text(
            badge.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),

          Text(
            badge.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Requirement
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(VibrantRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requirement',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        badge.requirement,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Earned date
          if (isEarned && earnedAt != null) ...[
            const SizedBox(height: VibrantSpacing.md),
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earned on',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        Text(
                          _formatDate(earnedAt!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Badge progress indicator
class BadgeProgressCard extends StatelessWidget {
  const BadgeProgressCard({
    required this.completedCount,
    required this.totalCount,
    super.key,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = completedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Badge Collection',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completedCount / $totalCount',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(VibrantRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            '${(progress * 100).round()}% Complete',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
