import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../theme/advanced_micro_interactions.dart';
import '../services/haptic_service.dart';
import '../widgets/effects/confetti_overlay.dart';
import '../widgets/notifications/toast_notifications.dart';
import '../widgets/common/aurora_background.dart';
import '../widgets/common/premium_cards.dart';
import '../widgets/glassmorphism_card.dart';

/// Shop page for purchasing power-ups and items with coins
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage>
    with TickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  int _userCoins = 0;
  bool _showConfetti = false;
  late final AnimationController _heroController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _loadUserCoins();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCoins() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final progressApi = ref.read(progressApiProvider);
      final progress = await progressApi.getUserProgress();
      if (mounted) {
        setState(() {
          _userCoins = progress.coins;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchaseItem(ShopItem item) async {
    if (_userCoins < item.cost) {
      HapticFeedback.lightImpact();
      _showError(
        'Not enough coins! You need ${item.cost} but have $_userCoins.',
      );
      return;
    }

    final confirmed = await _showConfirmDialog(item);
    if (!confirmed) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      final progressApi = ref.read(progressApiProvider);
      Map<String, dynamic> result;

      // Call appropriate purchase endpoint based on item ID
      switch (item.id) {
        case 'xp_boost_2x':
          result = await progressApi.purchaseXpBoost();
          break;
        case 'hint_reveal':
          result = await progressApi.purchaseHintReveal();
          break;
        case 'skip_question':
          result = await progressApi.purchaseTimeWarp();
          break;
        case 'streak_freeze':
          result = await progressApi.purchaseStreakFreeze();
          break;
        case 'streak_repair':
          result = await progressApi.purchaseStreakRepair();
          break;
        case 'avatar_gold':
          result = await progressApi.purchaseAvatarBorder();
          break;
        case 'theme_dark_premium':
          result = await progressApi.purchasePremiumTheme();
          break;
        default:
          // Handle unknown items gracefully - show error instead of crashing
          if (mounted) {
            setState(() => _loading = false);
            HapticService.error();
            _showError('This item is not available yet. Check back later!');
          }
          return;
      }

      if (mounted) {
        setState(() {
          _userCoins =
              result['coins_remaining'] as int? ?? _userCoins - item.cost;
          _loading = false;
          _showConfetti = true;
        });
        // Success haptic
        HapticService.celebrate();
        _showSuccess(
          result['message'] as String? ??
              '${item.name} purchased successfully!',
        );
        // Hide confetti after animation
        Future.delayed(const Duration(milliseconds: 4000), () {
          if (mounted) {
            setState(() => _showConfetti = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        HapticFeedback.heavyImpact();
        _showError('Purchase failed: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog(ShopItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text(
          'Purchase ${item.name} for ${item.cost} coins?\\n\\n${item.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String message) {
    ToastNotification.show(
      context: context,
      message: message,
      title: 'Error',
      type: ToastType.error,
      position: ToastPosition.top,
    );
  }

  void _showSuccess(String message) {
    ToastNotification.show(
      context: context,
      message: message,
      title: 'Success',
      type: ToastType.success,
      position: ToastPosition.top,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConfettiOverlay(
      isActive: _showConfetti,
      particleCount: 150,
      duration: const Duration(milliseconds: 4000),
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _loading && _userCoins == 0
            ? const Center(child: CircularProgressIndicator())
            : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load shop',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadUserCoins,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserCoins,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(VibrantSpacing.lg),
                      child: _buildHeroSection(theme, colorScheme),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: VibrantSpacing.lg),
                        _buildSection(
                          'Power-Ups',
                          'Boost your learning with special abilities',
                          _powerUpItems,
                        ),
                        const SizedBox(height: VibrantSpacing.xl),
                        _buildSection(
                          'Streak Protection',
                          'Keep your streak alive',
                          _streakItems,
                        ),
                        const SizedBox(height: VibrantSpacing.xl),
                        _buildSection(
                          'Customization',
                          'Personalize your experience',
                          _customizationItems,
                        ),
                        const SizedBox(height: VibrantSpacing.xxxl),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: const BoxDecoration(gradient: VibrantTheme.auroraGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: AuroraBackground(controller: _heroController),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coin Shop',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.xs),
                          Text(
                            'Enhance your learning journey with power-ups and customization.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.lg),
                GlassmorphismCard(
                  blur: 24,
                  borderRadius: 26,
                  opacity: 0.2,
                  borderOpacity: 0.35,
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your balance',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              '$_userCoins coins',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.wallet_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<ShopItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        ...items.map((item) => _buildShopItem(item)),
      ],
    );
  }

  Widget _buildShopItem(ShopItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAfford = _userCoins >= item.cost;

    return ScaleIn(
      delay: const Duration(milliseconds: 50),
      child: Padding(
        padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
        child: GestureDetector(
          onTap: canAfford && !_loading ? () {
            AdvancedHaptics.medium();
            _purchaseItem(item);
          } : null,
          child: GlassCard(
            blur: 20,
            borderRadius: VibrantRadius.xl,
            opacity: canAfford ? 0.15 : 0.08,
            child: Container(
              decoration: BoxDecoration(
                gradient: canAfford
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.2),
                          colorScheme.tertiary.withValues(alpha: 0.15),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(VibrantRadius.xl),
              ),
              padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Row(
              children: [
                // Icon with breathing animation for affordable items
                canAfford
                    ? BreathingWidget(
                        duration: const Duration(seconds: 2),
                        minScale: 0.95,
                        maxScale: 1.05,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primaryContainer,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surfaceContainerHigh,
                        ),
                        child: Icon(
                          item.icon,
                          color: colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                      ),
                const SizedBox(width: VibrantSpacing.md),

                // Name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: canAfford
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: VibrantSpacing.xxs),
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price with glow effect for affordable items
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    canAfford
                        ? GlowingWidget(
                            glowColor: Colors.amber,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.cost}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.cost}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                    if (!canAfford)
                      Text(
                        'Need ${item.cost - _userCoins} more',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  // Shop items data
  static final List<ShopItem> _powerUpItems = [
    ShopItem(
      id: 'xp_boost_2x',
      name: '2x XP Boost',
      description: 'Double XP for 30 minutes',
      cost: 150,
      icon: Icons.flash_on,
    ),
    ShopItem(
      id: 'hint_reveal',
      name: 'Hint Reveal',
      description: 'Get a hint for any tricky exercise',
      cost: 50,
      icon: Icons.lightbulb,
    ),
    ShopItem(
      id: 'skip_question',
      name: 'Skip Question',
      description: 'Skip a difficult question and mark it correct',
      cost: 100,
      icon: Icons.skip_next,
    ),
  ];

  static final List<ShopItem> _streakItems = [
    ShopItem(
      id: 'streak_freeze',
      name: 'Streak Freeze',
      description: 'Protect your streak if you miss a day',
      cost: 100,
      icon: Icons.ac_unit,
    ),
    ShopItem(
      id: 'streak_repair',
      name: 'Streak Repair',
      description: 'Restore a broken streak (within 48 hours)',
      cost: 200,
      icon: Icons.build,
    ),
  ];

  static final List<ShopItem> _customizationItems = [
    ShopItem(
      id: 'avatar_gold',
      name: 'Gold Avatar Border',
      description: 'Show off your achievements with style',
      cost: 500,
      icon: Icons.account_circle,
    ),
    ShopItem(
      id: 'theme_dark_premium',
      name: 'Premium Dark Theme',
      description: 'Unlock exclusive dark theme colors',
      cost: 300,
      icon: Icons.palette,
    ),
  ];
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final IconData icon;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
  });
}
