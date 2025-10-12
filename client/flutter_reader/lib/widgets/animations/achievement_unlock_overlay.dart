import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Fullscreen overlay that celebrates achievement unlocks
/// Shows animated badge and rewards
void showAchievementUnlock(
  BuildContext context, {
  required String achievementId,
  required String title,
  required String description,
  required String icon,
  required int tier, // 1=bronze, 2=silver, 3=gold, 4=platinum
  required int xpReward,
  required int coinReward,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (context) => AchievementUnlockOverlay(
      achievementId: achievementId,
      title: title,
      description: description,
      icon: icon,
      tier: tier,
      xpReward: xpReward,
      coinReward: coinReward,
    ),
  );
}

class AchievementUnlockOverlay extends StatefulWidget {
  const AchievementUnlockOverlay({
    super.key,
    required this.achievementId,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.xpReward,
    required this.coinReward,
  });

  final String achievementId;
  final String title;
  final String description;
  final String icon;
  final int tier;
  final int xpReward;
  final int coinReward;

  @override
  State<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Start animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _tierColor {
    switch (widget.tier) {
      case 1:
        return Colors.brown.shade400;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return const Color(0xFFFFD700);
      case 4:
        return const Color(0xFFE5E4E2);
      default:
        return Colors.blue;
    }
  }

  String get _tierName {
    switch (widget.tier) {
      case 1:
        return 'Bronze';
      case 2:
        return 'Silver';
      case 3:
        return 'Gold';
      case 4:
        return 'Platinum';
      default:
        return 'Common';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Achievement Unlocked!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.xxl),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _tierColor,
                          _tierColor.withValues(alpha: 0.8),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 6),
                      boxShadow: [
                        BoxShadow(
                          color: _tierColor.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.icon,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xxl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.md,
                    vertical: VibrantSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _tierColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    border: Border.all(color: _tierColor, width: 2),
                  ),
                  child: Text(
                    _tierName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _tierColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  widget.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  widget.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.xpReward > 0 || widget.coinReward > 0) ...[
                  const SizedBox(height: VibrantSpacing.xxl),
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(VibrantRadius.xl),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Rewards',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: VibrantSpacing.md),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.xpReward > 0) ...[
                              _RewardChip(
                                icon: Icons.flash_on_rounded,
                                label: '+${widget.xpReward} XP',
                                color: Colors.amber,
                              ),
                              if (widget.coinReward > 0)
                                const SizedBox(width: VibrantSpacing.md),
                            ],
                            if (widget.coinReward > 0)
                              _RewardChip(
                                icon: Icons.monetization_on_rounded,
                                label: '+${widget.coinReward} coins',
                                color: Colors.yellow.shade700,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: VibrantSpacing.xxl),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.xxl,
                      vertical: VibrantSpacing.lg,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
