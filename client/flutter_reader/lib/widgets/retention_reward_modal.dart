import 'package:flutter/material.dart';
import '../services/retention_loop_service.dart';
import '../theme/premium_gradients.dart';
import '../theme/design_tokens.dart';
import '../widgets/premium_card.dart';
import '../services/sound_service.dart';
import '../services/haptic_service.dart';

/// Modal to display retention loop rewards with celebration
class RetentionRewardModal extends StatelessWidget {
  const RetentionRewardModal({super.key, required this.rewards});

  final List<RetentionReward> rewards;

  static Future<void> show(
    BuildContext context,
    List<RetentionReward> rewards,
  ) async {
    if (rewards.isEmpty) return;

    // Play celebration sound
    SoundService.instance.achievement();
    HapticService.heavy();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RetentionRewardModal(rewards: rewards),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBonusXP = rewards.fold<int>(0, (sum, r) => sum + r.xpBonus);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.space20),
              decoration: BoxDecoration(
                gradient: PremiumGradients.successButton,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: AppSpacing.space24),

            // Title
            Text(
              'Achievement Unlocked!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.space16),

            // Reward messages
            ...rewards.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space12),
                child: Row(
                  children: [
                    Icon(
                      _getIconForRewardType(reward.type),
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (reward.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              reward.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space24),

            // Bonus XP
            if (totalBonusXP > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space20,
                  vertical: AppSpacing.space12,
                ),
                decoration: BoxDecoration(
                  gradient: PremiumGradients.premiumButton,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 24),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      '+$totalBonusXP Bonus XP',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.space24),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  HapticService.light();
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForRewardType(RewardType type) {
    switch (type) {
      case RewardType.streakStart:
      case RewardType.streakMilestone:
      case RewardType.streakBroken:
        return Icons.local_fire_department;
      case RewardType.weeklyGoal:
        return Icons.flag;
      case RewardType.rankImprovement:
      case RewardType.topPercentile:
        return Icons.leaderboard;
      case RewardType.masteryLevel:
        return Icons.military_tech;
    }
  }
}
