import 'package:flutter/material.dart';
import '../../services/challenges_api.dart';
import '../../theme/vibrant_colors.dart';

/// Widget displaying weekly special challenges with 5-10x rewards
class WeeklyChallengesCard extends StatelessWidget {
  const WeeklyChallengesCard({
    super.key,
    required this.challenges,
    this.onRefresh,
  });

  final List<WeeklyChallengeApiResponse> challenges;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED), // Purple
              Color(0xFFEC4899), // Pink
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            ...challenges.map((challenge) => _buildChallengeItem(context, challenge)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final daysRemaining = challenges.first.daysRemaining;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⏰ WEEKLY SPECIAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '5-10x Rewards!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: daysRemaining <= 1 ? Colors.red : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$daysRemaining day${daysRemaining != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(BuildContext context, WeeklyChallengeApiResponse challenge) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildMultiplierBadge(challenge.rewardMultiplier),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(challenge),
          const SizedBox(height: 8),
          _buildRewards(challenge),
        ],
      ),
    );
  }

  Widget _buildMultiplierBadge(double multiplier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${multiplier.toStringAsFixed(0)}x',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressBar(WeeklyChallengeApiResponse challenge) {
    final progress = challenge.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            Text(
              '${challenge.currentProgress}/${challenge.targetValue}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                challenge.isCompleted
                    ? Colors.greenAccent
                    : const Color(0xFFFFD700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewards(WeeklyChallengeApiResponse challenge) {
    return Row(
      children: [
        _buildRewardChip(
          Icons.monetization_on,
          '${challenge.coinReward}',
          VibrantColors.xpGold,
        ),
        const SizedBox(width: 8),
        _buildRewardChip(
          Icons.star,
          '${challenge.xpReward}',
          VibrantColors.combo,
        ),
        if (challenge.isCompleted) ...[
          const Spacer(),
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 4),
          const Text(
            'COMPLETED',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRewardChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final totalCoins = challenges.fold<int>(0, (sum, c) => sum + c.coinReward);
    final totalXp = challenges.fold<int>(0, (sum, c) => sum + c.xpReward);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Rewards',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.monetization_on, color: VibrantColors.xpGold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    totalCoins.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.star, color: VibrantColors.combo, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    totalXp.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }
}
