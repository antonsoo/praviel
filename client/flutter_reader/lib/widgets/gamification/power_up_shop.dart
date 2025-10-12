import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/vibrant_colors.dart';
import '../../app_providers.dart';

/// Power-Up Shop - Purchase streak freezes and other power-ups
class PowerUpShopBottomSheet extends ConsumerStatefulWidget {
  const PowerUpShopBottomSheet({super.key});

  @override
  ConsumerState<PowerUpShopBottomSheet> createState() => _PowerUpShopBottomSheetState();
}

class _PowerUpShopBottomSheetState extends ConsumerState<PowerUpShopBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(String itemType) async {
    final progressApi = ref.read(progressApiProvider);

    try {
      Map<String, dynamic> result;
      switch (itemType) {
        case 'streak_freeze':
          result = await progressApi.purchaseStreakFreeze();
          break;
        case 'xp_boost':
          result = await progressApi.purchaseXpBoost();
          break;
        case 'hint':
          result = await progressApi.purchaseHintReveal();
          break;
        case 'skip':
          result = await progressApi.purchaseTimeWarp();
          break;
        default:
          throw Exception('Unknown item type: $itemType');
      }

      if (mounted && result['success'] == true) {
        // Refresh progress data
        ref.invalidate(progressServiceProvider);
        ref.invalidate(backendChallengeServiceProvider);

        _showPurchaseSuccess(result['message'] as String? ?? 'Purchase successful!');
      }
    } catch (e) {
      if (mounted) {
        _showPurchaseError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressApi = ref.watch(progressApiProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VibrantColors.gradientStart,
                VibrantColors.gradientEnd,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Power-Up Shop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Coin balance display
              FutureBuilder(
                future: progressApi.getUserProgress(),
                builder: (context, snapshot) {
                  final coins = snapshot.data?.coins ?? 0;
                  return _buildCoinBalance(coins);
                },
              ),

              const SizedBox(height: 16),

              // Shop items
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: FutureBuilder(
                    future: progressApi.getUserProgress(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final progress = snapshot.data!;
                      return _buildShopContent(
                        coins: progress.coins,
                        streakFreezes: progress.streakFreezes,
                        xpBoosts: progress.xpBoost2x,
                        hints: progress.perfectProtection,
                        skips: progress.timeWarp,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinBalance(int coins) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: VibrantColors.xpGold,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'coins',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopContent({
    required int coins,
    required int streakFreezes,
    required int xpBoosts,
    required int hints,
    required int skips,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ShopItem(
          icon: Icons.ac_unit_rounded,
          title: 'Streak Freeze',
          description: 'Protects your streak for 1 day',
          cost: 200,
          owned: streakFreezes,
          coins: coins,
          color: VibrantColors.streakFlame,
          onPurchase: () => _handlePurchase('streak_freeze'),
          info: 'Automatically protects your streak if you miss a day. Research shows this reduces churn by 21%!',
        ),
        const SizedBox(height: 16),
        _ShopItem(
          icon: Icons.flash_on_rounded,
          title: 'XP Boost',
          description: '2x XP for 30 minutes',
          cost: 150,
          owned: xpBoosts,
          coins: coins,
          color: VibrantColors.powerUp,
          onPurchase: () => _handlePurchase('xp_boost'),
          info: 'Double your XP gains for 30 minutes. Perfect for intensive study sessions!',
        ),
        const SizedBox(height: 16),
        _ShopItem(
          icon: Icons.lightbulb_rounded,
          title: 'Hint Power-Up',
          description: 'Get a hint on any exercise',
          cost: 50,
          owned: hints,
          coins: coins,
          color: VibrantColors.warning,
          onPurchase: () => _handlePurchase('hint'),
          info: 'Reveals helpful hints when you\'re stuck on a difficult exercise.',
        ),
        const SizedBox(height: 16),
        _ShopItem(
          icon: Icons.skip_next_rounded,
          title: 'Skip Question',
          description: 'Skip a difficult question',
          cost: 100,
          owned: skips,
          coins: coins,
          color: VibrantColors.secondary,
          onPurchase: () => _handlePurchase('skip'),
          info: 'Skip any question you find too challenging and mark it correct.',
        ),
      ],
    );
  }

  void _showPurchaseSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: VibrantColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPurchaseError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.contains('Not enough coins')
                    ? 'Not enough coins! Complete challenges to earn more.'
                    : 'Purchase failed: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: VibrantColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Individual shop item widget
class _ShopItem extends StatelessWidget {
  const _ShopItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.cost,
    required this.owned,
    required this.coins,
    required this.color,
    required this.onPurchase,
    required this.info,
  });

  final IconData icon;
  final String title;
  final String description;
  final int cost;
  final int owned;
  final int coins;
  final Color color;
  final VoidCallback onPurchase;
  final String info;

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= cost;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: VibrantColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: VibrantColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: VibrantColors.xpGold,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$cost',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: VibrantColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owned: $owned',
                      style: TextStyle(
                        fontSize: 12,
                        color: VibrantColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info,
                      style: TextStyle(
                        fontSize: 13,
                        color: VibrantColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Purchase button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford ? onPurchase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford
                      ? color
                      : VibrantColors.textHint.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: canAfford ? 4 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canAfford ? Icons.shopping_cart_rounded : Icons.lock_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canAfford ? 'Purchase' : 'Not Enough Coins',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
