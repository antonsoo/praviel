import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

/// Premium animated button with scale and haptic feedback
/// Makes every tap feel satisfying and responsive
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.borderRadius = 16,
    this.elevation = 0,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      HapticService.light();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color ?? colorScheme.primary,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.elevation > 0
                ? [
                    BoxShadow(
                      color: (widget.color ?? colorScheme.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: widget.elevation,
                      offset: Offset(0, widget.elevation / 2),
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.labelLarge!.copyWith(
              color: widget.color != null
                  ? _getContrastingColor(widget.color!)
                  : colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Color _getContrastingColor(Color bgColor) {
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// Outlined premium button with subtle hover effects
class PremiumOutlinedButton extends StatefulWidget {
  const PremiumOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.borderRadius = 16,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? borderColor;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  State<PremiumOutlinedButton> createState() => _PremiumOutlinedButtonState();
}

class _PremiumOutlinedButtonState extends State<PremiumOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          _controller.forward();
          HapticService.light();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.borderColor ?? colorScheme.outline,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.labelLarge!.copyWith(
              color: widget.borderColor ?? colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Icon button with premium animations
class PremiumIconButton extends StatefulWidget {
  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  State<PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<PremiumIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          _controller.forward();
          HapticService.light();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.icon,
          color: widget.color ?? theme.colorScheme.onSurface,
          size: widget.size,
        ),
      ),
    );
  }
}
