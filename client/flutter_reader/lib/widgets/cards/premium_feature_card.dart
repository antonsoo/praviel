/// Premium feature cards with stunning 2025 design
library;

import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';

/// Stunning feature card with gradient and hover effects
class PremiumFeatureCard extends StatefulWidget {
  const PremiumFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.gradient,
    this.iconColor,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? iconColor;
  final String? badge;

  @override
  State<PremiumFeatureCard> createState() => _PremiumFeatureCardState();
}

class _PremiumFeatureCardState extends State<PremiumFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticService.light();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.primaryContainer,
        colorScheme.secondaryContainer,
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient ?? defaultGradient,
            borderRadius: BorderRadius.circular(VibrantRadius.xl),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? colorScheme.shadow.withValues(alpha: 0.15)
                    : colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: _isPressed ? 12 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
            border: Border.all(
              color: _isPressed
                  ? colorScheme.outline.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        color: (widget.iconColor ?? colorScheme.primary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(VibrantRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.iconColor ?? colorScheme.primary)
                                .withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 32,
                        color: widget.iconColor ?? colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.lg),

                    // Title
                    Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.sm),

                    // Description
                    Text(
                      widget.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: VibrantSpacing.md),

                    // Arrow indicator
                    Row(
                      children: [
                        Text(
                          'Explore',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.iconColor ?? colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: VibrantSpacing.xs),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: widget.iconColor ?? colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge
              if (widget.badge != null)
                Positioned(
                  top: VibrantSpacing.md,
                  right: VibrantSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.md,
                      vertical: VibrantSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(VibrantRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.badge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
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
}

/// Compact feature card for grid layouts
class CompactFeatureCard extends StatelessWidget {
  const CompactFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
    this.count,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            border: Border.all(
              color: cardColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.sm),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: VibrantSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (count != null) ...[
                const SizedBox(height: VibrantSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.sm,
                    vertical: VibrantSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cardColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
