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

  @override
  Widget build(BuildContext context) {
    final backendServiceAsync = ref.watch(backendChallengeServiceProvider);
    final powerUpServiceAsync = ref.watch(powerUpServiceProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
              powerUpServiceAsync.when(
                data: (powerUpService) => backendServiceAsync.when(
                  data: (backendService) => _buildCoinBalance(
                    backendService.userCoins ?? powerUpService.coins,
                  ),
                  loading: () => _buildCoinBalance(powerUpService.coins),
                  error: (error, stackTrace) => _buildCoinBalance(powerUpService.coins),
                ),
                loading: () => _buildCoinBalance(0),
                error: (error, stackTrace) => _buildCoinBalance(0),
              ),

              const SizedBox(height: 16),

              // Shop items
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: powerUpServiceAsync.when(
                    data: (powerUpService) => backendServiceAsync.when(
                      data: (backendService) => _buildShopContent(
                        coins: backendService.userCoins ?? powerUpService.coins,
                        streakFreezes: backendService.userStreakFreezes ?? 0,
                        onPurchase: () async {
                          final success = await backendService.purchaseStreakFreeze();
                          if (success && context.mounted) {
                            _showPurchaseSuccess();
                          } else if (context.mounted) {
                            _showPurchaseError();
                          }
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => _buildShopContent(
                        coins: powerUpService.coins,
                        streakFreezes: 0,
                        onPurchase: () {},
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error loading shop: $error'),
                    ),
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
    required VoidCallback onPurchase,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Streak Freeze item
        _StreakFreezeItem(
          coins: coins,
          streakFreezes: streakFreezes,
          onPurchase: onPurchase,
        ),

        const SizedBox(height: 16),

        // Coming soon items
        _ComingSoonItem(
          icon: Icons.flash_on_rounded,
          title: 'XP Boost',
          description: '2x XP for 30 minutes',
          color: VibrantColors.powerUp,
        ),

        const SizedBox(height: 16),

        _ComingSoonItem(
          icon: Icons.lightbulb_rounded,
          title: 'Hint Power-Up',
          description: 'Get a hint on any exercise',
          color: VibrantColors.warning,
        ),

        const SizedBox(height: 16),

        _ComingSoonItem(
          icon: Icons.skip_next_rounded,
          title: 'Skip Question',
          description: 'Skip a difficult question',
          color: VibrantColors.secondary,
        ),
      ],
    );
  }

  void _showPurchaseSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Streak Freeze purchased! It will protect your streak if you miss a day.',
                style: TextStyle(color: Colors.white),
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

  void _showPurchaseError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Not enough coins! Complete challenges to earn more.',
                style: TextStyle(color: Colors.white),
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

/// Streak Freeze shop item
class _StreakFreezeItem extends StatelessWidget {
  const _StreakFreezeItem({
    required this.coins,
    required this.streakFreezes,
    required this.onPurchase,
  });

  final int coins;
  final int streakFreezes;
  final VoidCallback onPurchase;

  static const int cost = 200;

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= cost;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VibrantColors.streakFlame.withValues(alpha: 0.1),
            VibrantColors.streakFire.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: VibrantColors.streakFlame.withValues(alpha: 0.3),
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
                    gradient: const LinearGradient(
                      colors: [
                        VibrantColors.streakFlame,
                        VibrantColors.streakFire,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.ac_unit_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Streak Freeze',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: VibrantColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Protects your streak for 1 day',
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
                      'Owned: $streakFreezes',
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

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VibrantColors.streakFlame.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: VibrantColors.streakFlame,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Automatically protects your streak if you miss a day. Research shows this reduces churn by 21%!',
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
                      ? VibrantColors.streakFlame
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

/// Coming soon shop item
class _ComingSoonItem extends StatelessWidget {
  const _ComingSoonItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
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
                        fontSize: 18,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SOON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: VibrantColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
