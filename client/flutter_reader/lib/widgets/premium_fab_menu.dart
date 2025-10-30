import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';

/// Premium expandable floating action button menu
/// 2025 trend: Radial menus with smooth animations

/// Expandable FAB with radial menu
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.children,
    this.distance = 100.0,
    this.gradient,
    this.icon = Icons.add,
    this.closeIcon = Icons.close,
  });

  final List<FabMenuItem> children;
  final double distance;
  final Gradient? gradient;
  final IconData icon;
  final IconData closeIcon;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi / 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });

    HapticService.medium();

    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradient ?? VibrantTheme.premiumGradient;

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Backdrop
          if (_isOpen)
            GestureDetector(
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black
                        .withValues(alpha: 0.3 * _expandAnimation.value),
                  );
                },
              ),
            ),

          // Menu items
          ...List.generate(widget.children.length, (index) {
            return _buildMenuItem(index, widget.children[index]);
          }),

          // Main FAB
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FloatingActionButton(
                  onPressed: _toggle,
                  elevation: 8,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: effectiveGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Icon(
                        _isOpen ? widget.closeIcon : widget.icon,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, FabMenuItem item) {
    final angle = (math.pi / 2) * (index / (widget.children.length - 1));
    final offset = Offset(
      -math.cos(angle) * widget.distance,
      -math.sin(angle) * widget.distance,
    );

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        final delay = index * 0.05;
        final itemProgress = (progress - delay).clamp(0.0, 1.0);

        return Positioned(
          right: 32 + (offset.dx * itemProgress),
          bottom: 32 + (offset.dy * itemProgress),
          child: Opacity(
            opacity: itemProgress,
            child: Transform.scale(
              scale: itemProgress,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.label != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.md,
                vertical: VibrantSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                boxShadow: VibrantShadow.sm(Theme.of(context).colorScheme),
              ),
              child: Text(
                item.label!,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (item.label != null) const SizedBox(height: VibrantSpacing.xs),
          FloatingActionButton.small(
            onPressed: () {
              HapticService.light();
              item.onPressed?.call();
              _toggle();
            },
            heroTag: null,
            backgroundColor: item.backgroundColor,
            child: Icon(item.icon, color: item.iconColor ?? Colors.white),
          ),
        ],
      ),
    );
  }
}

class FabMenuItem {
  const FabMenuItem({
    required this.icon,
    this.label,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
}

/// Speed dial FAB - vertical expansion
class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    super.key,
    required this.children,
    this.gradient,
    this.icon = Icons.menu,
    this.closeIcon = Icons.close,
  });

  final List<SpeedDialAction> children;
  final Gradient? gradient;
  final IconData icon;
  final IconData closeIcon;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi / 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });

    HapticService.medium();

    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveGradient = widget.gradient ?? VibrantTheme.premiumGradient;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu items
        ...List.generate(widget.children.length, (index) {
          final item = widget.children[widget.children.length - 1 - index];
          return _buildSpeedDialItem(index, item, theme);
        }),

        // Main FAB
        Padding(
          padding: const EdgeInsets.only(top: VibrantSpacing.md),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FloatingActionButton(
                onPressed: _toggle,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: effectiveGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Icon(
                      _isOpen ? widget.closeIcon : widget.icon,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem(
    int index,
    SpeedDialAction item,
    ThemeData theme,
  ) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final delay = index * 0.05;
        final progress = (_scaleAnimation.value - delay).clamp(0.0, 1.0);

        return Transform.scale(
          scale: progress,
          alignment: Alignment.bottomRight,
          child: Opacity(
            opacity: progress,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.label != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  boxShadow: VibrantShadow.sm(theme.colorScheme),
                ),
                child: Text(
                  item.label!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (item.label != null) const SizedBox(width: VibrantSpacing.md),
            FloatingActionButton.small(
              onPressed: () {
                HapticService.light();
                item.onPressed?.call();
                _toggle();
              },
              heroTag: null,
              backgroundColor: item.backgroundColor ?? theme.colorScheme.primary,
              child: Icon(item.icon, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeedDialAction {
  const SpeedDialAction({
    required this.icon,
    this.label,
    this.onPressed,
    this.backgroundColor,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
}
