import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../models/power_up.dart';

/// Power-up card for shop/inventory
class PowerUpCard extends StatelessWidget {
  const PowerUpCard({
    required this.powerUp,
    required this.count,
    required this.coins,
    this.onPurchase,
    this.onActivate,
    this.isActive = false,
    super.key,
  });

  final PowerUp powerUp;
  final int count;
  final int coins;
  final VoidCallback? onPurchase;
  final VoidCallback? onActivate;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAfford = coins >= powerUp.cost;

    return AnimatedScaleButton(
      onTap: count > 0
          ? (onActivate ?? () {})
          : canAfford
          ? (onPurchase ?? () {})
          : () {},
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.md),
        decoration: BoxDecoration(
          gradient: isActive ? powerUp.gradient : null,
          color: isActive ? null : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.3)
                : powerUp.color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: powerUp.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with rarity glow
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: powerUp.gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: powerUp.color.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(powerUp.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: VibrantSpacing.sm),

            // Name
            Text(
              powerUp.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isActive ? Colors.white : null,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            Text(
              powerUp.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.8)
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: VibrantSpacing.sm),

            // Action button
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Text(
                  'ACTIVATE (${count}x)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: canAfford
                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  border: Border.all(
                    color: canAfford
                        ? const Color(0xFFFFD700)
                        : colorScheme.outline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 16,
                      color: canAfford
                          ? const Color(0xFFFFD700)
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${powerUp.cost}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: canAfford
                            ? const Color(0xFFFFD700)
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Active power-up indicator (shows during lesson)
class ActivePowerUpIndicator extends StatelessWidget {
  const ActivePowerUpIndicator({
    required this.powerUp,
    required this.usesRemaining,
    this.timeRemaining,
    super.key,
  });

  final PowerUp powerUp;
  final int usesRemaining;
  final Duration? timeRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: powerUp.gradient,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        boxShadow: [
          BoxShadow(color: powerUp.color.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(powerUp.icon, size: 16, color: Colors.white),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            powerUp.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (timeRemaining != null) ...[
            const SizedBox(width: VibrantSpacing.xs),
            Text(
              _formatDuration(timeRemaining!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ] else if (usesRemaining > 0) ...[
            const SizedBox(width: VibrantSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${usesRemaining}x',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m';
    }
    return '${seconds}s';
  }
}

/// Power-up shop modal
class PowerUpShopModal extends StatelessWidget {
  const PowerUpShopModal({
    required this.coins,
    required this.inventory,
    required this.onPurchase,
    super.key,
  });

  final int coins;
  final Map<PowerUpType, int> inventory;
  final Function(PowerUp) onPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Power-Up Shop', style: theme.textTheme.headlineSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: VibrantSpacing.xs),
                    Text(
                      '$coins',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Enhance your learning with powerful boosters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),

          // Power-ups grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: VibrantSpacing.md,
                mainAxisSpacing: VibrantSpacing.md,
              ),
              itemCount: PowerUp.all.length,
              itemBuilder: (context, index) {
                final powerUp = PowerUp.all[index];
                final count = inventory[powerUp.type] ?? 0;

                return PowerUpCard(
                  powerUp: powerUp,
                  count: count,
                  coins: coins,
                  onPurchase: () {
                    onPurchase(powerUp);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact power-up inventory for quick access
class PowerUpQuickBar extends StatelessWidget {
  const PowerUpQuickBar({
    required this.inventory,
    required this.activePowerUps,
    required this.onActivate,
    super.key,
  });

  final Map<PowerUpType, int> inventory;
  final List<ActivePowerUp> activePowerUps;
  final Function(PowerUp) onActivate;

  @override
  Widget build(BuildContext context) {
    final availablePowerUps = PowerUp.all
        .where((p) => (inventory[p.type] ?? 0) > 0)
        .toList();

    if (availablePowerUps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availablePowerUps.map((powerUp) {
          final count = inventory[powerUp.type] ?? 0;
          final isActive = activePowerUps.any(
            (a) => a.powerUp.type == powerUp.type && a.isActive,
          );

          return Padding(
            padding: const EdgeInsets.only(right: VibrantSpacing.xs),
            child: AnimatedScaleButton(
              onTap: () => onActivate(powerUp),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isActive ? powerUp.gradient : null,
                      color: isActive
                          ? null
                          : powerUp.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: powerUp.color, width: 2),
                    ),
                    child: Icon(
                      powerUp.icon,
                      color: isActive ? Colors.white : powerUp.color,
                      size: 24,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
