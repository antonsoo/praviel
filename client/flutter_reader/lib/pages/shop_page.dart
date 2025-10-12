import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../theme/vibrant_theme.dart';

/// Shop page for purchasing power-ups and items with coins
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  bool _loading = false;
  String? _error;
  int _userCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadUserCoins();
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
      _showError('Not enough coins! You need ${item.cost} but have $_userCoins.');
      return;
    }

    final confirmed = await _showConfirmDialog(item);
    if (!confirmed) return;

    setState(() => _loading = true);

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
        default:
          throw Exception('Unknown item: ${item.id}');
      }

      if (mounted) {
        setState(() {
          _userCoins = result['coins_remaining'] as int? ?? _userCoins - item.cost;
          _loading = false;
        });
        _showSuccess(result['message'] as String? ?? '${item.name} purchased successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Shop',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  '$_userCoins',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading && _userCoins == 0
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
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
                  child: ListView(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    children: [
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
      decoration: BoxDecoration(
        gradient: canAfford
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.5),
                  colorScheme.surfaceContainerHighest,
                ],
              )
            : null,
        color: canAfford ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        border: Border.all(
          color: canAfford
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAfford && !_loading ? () => _purchaseItem(item) : null,
          borderRadius: BorderRadius.circular(VibrantRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canAfford
                        ? RadialGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primaryContainer,
                            ],
                          )
                        : null,
                    color: canAfford ? null : colorScheme.surfaceContainerHigh,
                  ),
                  child: Icon(
                    item.icon,
                    color: canAfford ? Colors.white : colorScheme.onSurfaceVariant,
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
                          color: canAfford ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
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

                // Price
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.cost}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: canAfford ? colorScheme.primary : colorScheme.error,
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
