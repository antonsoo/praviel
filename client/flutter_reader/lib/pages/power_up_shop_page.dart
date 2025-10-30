import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../models/power_up.dart';
import '../widgets/glass_morphism.dart';
import '../widgets/enhanced_buttons.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/premium_snackbars.dart';
import '../services/social_api.dart';
import '../services/auth_service.dart';
import '../app_providers.dart';
import 'auth/login_page.dart';

/// Power-Up Shop page with beautiful animations and purchasing
class PowerUpShopPage extends ConsumerStatefulWidget {
  const PowerUpShopPage({super.key});

  @override
  ConsumerState<PowerUpShopPage> createState() => _PowerUpShopPageState();
}

class _PowerUpShopPageState extends ConsumerState<PowerUpShopPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<PowerUpInventoryResponse> _inventory = [];
  int _userCoins = 0;

  late AnimationController _pageController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Page entrance animation
    _pageController = AnimationController(
      vsync: this,
      duration: VibrantDuration.slow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: VibrantCurve.smooth),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _pageController,
            curve: VibrantCurve.bounceIn,
          ),
        );

    // Shimmer animation for featured items
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadInventory();
    _pageController.forward();

    ref.listen<AuthService>(authServiceProvider, (previous, next) {
      if (previous?.isAuthenticated == next.isAuthenticated) {
        return;
      }
      _loadInventory();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;

    final isAuthenticated = ref.read(authServiceProvider).isAuthenticated;
    if (!isAuthenticated) {
      setState(() {
        _isLoading = false;
        _error = null;
        _inventory = [];
        _userCoins = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(socialApiProvider);
      final inventory = await api.getPowerUps();

      if (!mounted) return;

      setState(() {
        _inventory = inventory;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadInventory();
  }

  Future<void> _purchasePowerUp(PowerUp powerUp) async {
    if (!ref.read(authServiceProvider).isAuthenticated) {
      _promptLogin();
      return;
    }

    if (_userCoins < powerUp.cost) {
      _showSnackBar(
        'Not enough coins! Need ${powerUp.cost - _userCoins} more.',
        isError: true,
      );
      return;
    }

    // Store original state for rollback
    final originalCoins = _userCoins;
    final originalInventory = List<PowerUpInventoryResponse>.from(_inventory);

    // Optimistic update: deduct coins and update inventory immediately
    setState(() {
      _userCoins -= powerUp.cost;

      // Update inventory count
      final existingIndex = _inventory.indexWhere(
        (inv) => inv.powerUpType == powerUp.type.name,
      );

      if (existingIndex >= 0) {
        final existing = _inventory[existingIndex];
        _inventory[existingIndex] = PowerUpInventoryResponse(
          powerUpType: existing.powerUpType,
          quantity: existing.quantity + 1,
          activeCount: existing.activeCount,
        );
      } else {
        _inventory.add(
          PowerUpInventoryResponse(
            powerUpType: powerUp.type.name,
            quantity: 1,
            activeCount: 0,
          ),
        );
      }
    });

    try {
      final api = ref.read(socialApiProvider);
      await api.purchasePowerUp(powerUpType: powerUp.type.name);

      _showSnackBar('${powerUp.name} purchased!');
      _showPurchaseAnimation(powerUp);
      // Reload to sync with server
      await _loadInventory();
    } catch (e) {
      // Rollback optimistic update on error
      setState(() {
        _userCoins = originalCoins;
        _inventory = originalInventory;
      });
      _showSnackBar('Failed to purchase: ${e.toString()}', isError: true);
    }
  }

  void _showPurchaseAnimation(PowerUp powerUp) {
    // Show confetti or success animation
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _PurchaseSuccessDialog(powerUp: powerUp),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      PremiumSnackBar.error(context, message: message, title: 'Error');
    } else {
      PremiumSnackBar.success(context, message: message, title: 'Success');
    }
  }

  void _promptLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget _buildGuestSliver(ThemeData theme, ColorScheme colorScheme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.xxxl),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(VibrantRadius.xl),
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_outlined, color: colorScheme.primary, size: 48),
              const SizedBox(height: VibrantSpacing.lg),
              Text(
                'Sign in to unlock the Power-Up shop',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'Log in to spend coins, activate boosts, and supercharge your practice streak.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VibrantSpacing.xl),
              FilledButton.icon(
                onPressed: _promptLogin,
                icon: const Icon(Icons.login),
                label: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getInventoryCount(PowerUpType type) {
    final item = _inventory.firstWhere(
      (inv) => inv.powerUpType == type.name,
      orElse: () => PowerUpInventoryResponse(
        powerUpType: type.name,
        quantity: 0,
        activeCount: 0,
      ),
    );
    return item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAuthenticated = ref.watch(authServiceProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomRefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // App Bar with Coins
            _buildAppBar(theme, colorScheme),

            // Content
            SliverPadding(
              padding: const EdgeInsets.only(
                top: VibrantSpacing.lg,
                bottom: VibrantSpacing.xxxl,
              ),
              sliver: !isAuthenticated
                  ? _buildGuestSliver(theme, colorScheme)
                  : _isLoading
                  ? _buildLoadingSliver()
                  : _error != null
                  ? _buildErrorSliver(theme, colorScheme)
                  : _buildContentSliver(theme, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: VibrantSpacing.lg,
          bottom: VibrantSpacing.md,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.xs),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.sm),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              'Power-Up Shop',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Coin counter
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(right: VibrantSpacing.lg),
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.md,
              vertical: VibrantSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(VibrantRadius.full),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA500).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: VibrantSpacing.xs),
                Text(
                  '$_userCoins',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: VibrantSpacing.md,
          mainAxisSpacing: VibrantSpacing.md,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const SkeletonCard(height: 200, showImage: false),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildErrorSliver(ThemeData theme, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Container(
        margin: const EdgeInsets.all(VibrantSpacing.xxxl),
        padding: const EdgeInsets.all(VibrantSpacing.xxxl),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(VibrantRadius.xxl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'Failed to load shop',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.lg),
            FilledButton(onPressed: _loadInventory, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver(ThemeData theme, ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Featured Power-Up
          _buildFeaturedPowerUp(theme, colorScheme),
          const SizedBox(height: VibrantSpacing.xl),

          // Categories
          Text(
            'Available Power-Ups',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),

          // Power-Up Grid
          _buildPowerUpGrid(theme, colorScheme),
        ]),
      ),
    );
  }

  Widget _buildFeaturedPowerUp(ThemeData theme, ColorScheme colorScheme) {
    final featured = PowerUp.autoComplete; // Featured legendary item

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: () => _showPowerUpDetails(featured),
          child: Stack(
            children: [
              // Shimmer background
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          featured.color.withValues(alpha: 0.3),
                          featured.color.withValues(alpha: 0.1),
                        ],
                        stops: [
                          _shimmerController.value - 0.3,
                          _shimmerController.value + 0.3,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(VibrantRadius.xl),
                    ),
                  );
                },
              ),

              // Glass overlay with content
              GlassCard(
                blur: 15,
                opacity: 0.15,
                padding: const EdgeInsets.all(VibrantSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(VibrantSpacing.md),
                          decoration: BoxDecoration(
                            gradient: featured.gradient,
                            borderRadius: BorderRadius.circular(
                              VibrantRadius.md,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: featured.color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            featured.icon,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: VibrantSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    featured.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: VibrantSpacing.xs),
                                  _buildRarityBadge(featured.rarity),
                                ],
                              ),
                              const SizedBox(height: VibrantSpacing.xxs),
                              Text(
                                featured.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    GradientButton(
                      gradient: featured.gradient,
                      onPressed: () => _purchasePowerUp(featured),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: VibrantSpacing.sm),
                          Text(
                            'Buy for ${featured.cost} coins',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUpGrid(ThemeData theme, ColorScheme colorScheme) {
    final powerUps = PowerUp.all
        .where((p) => p.type != PowerUpType.autoComplete)
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: VibrantSpacing.md,
        mainAxisSpacing: VibrantSpacing.md,
      ),
      itemCount: powerUps.length,
      itemBuilder: (context, index) {
        return _buildPowerUpCard(powerUps[index], theme, colorScheme);
      },
    );
  }

  Widget _buildPowerUpCard(
    PowerUp powerUp,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final count = _getInventoryCount(powerUp.type);
    final canAfford = _userCoins >= powerUp.cost;

    return SlideInFromBottom(
      delay: Duration(milliseconds: 100 * PowerUp.all.indexOf(powerUp)),
      child: GestureDetector(
        onTap: () => _showPowerUpDetails(powerUp),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            border: Border.all(
              color: powerUp.color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: powerUp.color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: powerUp.gradient,
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      ),
                      child: Icon(powerUp.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),

                    // Name and rarity
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            powerUp.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildRarityBadge(powerUp.rarity),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.xxs),

                    // Description
                    Text(
                      powerUp.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Buy button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canAfford
                            ? () => _purchasePowerUp(powerUp)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: powerUp.color,
                          padding: const EdgeInsets.symmetric(
                            vertical: VibrantSpacing.sm,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, size: 16),
                            const SizedBox(width: VibrantSpacing.xxs),
                            Text(
                              '${powerUp.cost}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Owned count badge
              if (count > 0)
                Positioned(
                  top: VibrantSpacing.xs,
                  right: VibrantSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.sm,
                      vertical: VibrantSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      gradient: powerUp.gradient,
                      borderRadius: BorderRadius.circular(VibrantRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: powerUp.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'x$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
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

  Widget _buildRarityBadge(PowerUpRarity rarity) {
    final theme = Theme.of(context);
    final color = _getRarityColor(rarity);
    final label = rarity.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }

  Color _getRarityColor(PowerUpRarity rarity) {
    switch (rarity) {
      case PowerUpRarity.common:
        return const Color(0xFF94A3B8);
      case PowerUpRarity.rare:
        return const Color(0xFF3B82F6);
      case PowerUpRarity.epic:
        return const Color(0xFF9333EA);
      case PowerUpRarity.legendary:
        return const Color(0xFFFFD700);
    }
  }

  void _showPowerUpDetails(PowerUp powerUp) {
    GlassBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                decoration: BoxDecoration(
                  gradient: powerUp.gradient,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Icon(powerUp.icon, color: Colors.white, size: 40),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          powerUp.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: VibrantSpacing.xs),
                        _buildRarityBadge(powerUp.rarity),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.xxs),
                    Text(
                      powerUp.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.lg),
          if (powerUp.duration != null)
            Row(
              children: [
                Icon(Icons.schedule, size: 16),
                const SizedBox(width: VibrantSpacing.xs),
                Text(
                  'Duration: ${powerUp.duration!.inMinutes} minutes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          const SizedBox(height: VibrantSpacing.lg),
          GradientButton(
            gradient: powerUp.gradient,
            onPressed: () {
              Navigator.pop(context);
              _purchasePowerUp(powerUp);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: VibrantSpacing.sm),
                Text(
                  'Purchase for ${powerUp.cost} coins',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Purchase success animation dialog
class _PurchaseSuccessDialog extends StatefulWidget {
  const _PurchaseSuccessDialog({required this.powerUp});

  final PowerUp powerUp;

  @override
  State<_PurchaseSuccessDialog> createState() => _PurchaseSuccessDialogState();
}

class _PurchaseSuccessDialogState extends State<_PurchaseSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotateAnimation,
          child: Container(
            margin: const EdgeInsets.all(VibrantSpacing.xxxl),
            padding: const EdgeInsets.all(VibrantSpacing.xxxl),
            decoration: BoxDecoration(
              gradient: widget.powerUp.gradient,
              borderRadius: BorderRadius.circular(VibrantRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: widget.powerUp.color.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.powerUp.icon, color: Colors.white, size: 80),
                const SizedBox(height: VibrantSpacing.lg),
                Text(
                  'Purchase Successful!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  widget.powerUp.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
