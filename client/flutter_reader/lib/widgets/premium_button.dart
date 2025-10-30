import 'package:flutter/material.dart';

/// Premium 3D button with gamified press effect
///
/// Features:
/// - 4px bottom shadow that disappears on press
/// - Button shifts down 4px when pressed
/// - Smooth 100ms animation
/// - Visual feedback feels tactile and satisfying
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.shadowColor,
    this.height = 60,
    this.width,
    this.borderRadius = 16,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? shadowColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool enabled;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(
      begin: 0,
      end: 4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.enabled && widget.onPressed != null;
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final fgColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    final shadowClr = widget.shadowColor ?? bgColor.withValues(alpha: 0.4);

    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        final press = _pressAnimation.value;
        final shadowHeight = 4 - press;

        return SizedBox(
          width: widget.width,
          height: widget.height + 4, // Include shadow height
          child: Stack(
            children: [
              // Shadow layer (bottom)
              Positioned(
                left: 0,
                right: 0,
                top: press,
                child: Container(
                  height: widget.height + shadowHeight,
                  decoration: BoxDecoration(
                    color: shadowClr,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),
              // Main button layer
              Positioned(
                left: 0,
                right: 0,
                top: press,
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? bgColor
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: isEnabled
                            ? bgColor.withValues(alpha: 0.2)
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: DefaultTextStyle(
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isEnabled
                              ? fgColor
                              : theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                        child: child!,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Secondary button variant with outline style
class PremiumOutlineButton extends StatefulWidget {
  const PremiumOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 60,
    this.width,
    this.borderRadius = 16,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool enabled;

  @override
  State<PremiumOutlineButton> createState() => _PremiumOutlineButtonState();
}

class _PremiumOutlineButtonState extends State<PremiumOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(
      begin: 0,
      end: 3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.enabled && widget.onPressed != null;
    final borderClr = widget.borderColor ?? theme.colorScheme.secondary;
    final bgColor =
        widget.backgroundColor ??
        theme.colorScheme.secondaryContainer.withValues(alpha: 0.3);
    final fgColor = widget.foregroundColor ?? theme.colorScheme.secondary;

    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        final press = _pressAnimation.value;

        return SizedBox(
          width: widget.width,
          height: widget.height + 3,
          child: Stack(
            children: [
              // Shadow layer
              Positioned(
                left: 0,
                right: 0,
                top: press,
                child: Container(
                  height: widget.height + (3 - press),
                  decoration: BoxDecoration(
                    color: borderClr.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),
              // Main button
              Positioned(
                left: 0,
                right: 0,
                top: press,
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? bgColor
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: isEnabled
                            ? borderClr
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: DefaultTextStyle(
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isEnabled
                              ? fgColor
                              : theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                        child: child!,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
