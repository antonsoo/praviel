import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';

/// Premium button with gradient, glow, and sophisticated animations
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.width,
    this.height = 58,
    this.fontSize = 17,
    this.glowIntensity = 0.4,
    this.enableHaptics = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final double height;
  final double fontSize;
  final double glowIntensity;
  final bool enableHaptics;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    _controller.forward();
    if (widget.enableHaptics) {
      HapticService.medium();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (widget.onPressed == null) return;
    _controller.reverse();
  }

  void _onHoverChange(bool hovering) {
    if (hovering && widget.onPressed != null) {
      _controller.forward(from: _controller.value);
    } else {
      _controller.reverse(from: _controller.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = widget.gradient ?? VibrantTheme.heroGradient;
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  boxShadow: [
                    if (!isDisabled)
                      BoxShadow(
                        color: gradient.colors.first.withValues(
                          alpha: widget.glowIntensity * _glowAnimation.value,
                        ),
                        blurRadius: 24 * (1 + _glowAnimation.value * 0.5),
                        spreadRadius: 2 * _glowAnimation.value,
                        offset: const Offset(0, 8),
                      ),
                    if (!isDisabled)
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.15 * (1 - _glowAnimation.value * 0.3),
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDisabled
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.surfaceContainerHigh,
                              theme.colorScheme.surfaceContainer,
                            ],
                          )
                        : gradient,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    child: InkWell(
                      onTap: widget.onPressed,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.1),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: isDisabled
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: VibrantSpacing.sm),
                            ],
                            Text(
                              widget.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isDisabled
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white,
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Outline button with premium animations
class PremiumOutlineButton extends StatefulWidget {
  const PremiumOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
    this.width,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double height;

  @override
  State<PremiumOutlineButton> createState() => _PremiumOutlineButtonState();
}

class _PremiumOutlineButtonState extends State<PremiumOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _borderAnimation = Tween<double>(begin: 2.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChange(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDisabled = widget.onPressed == null;

    final effectiveBorderColor =
        widget.borderColor ?? colorScheme.primary;
    final effectiveTextColor =
        widget.textColor ?? colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              border: Border.all(
                color: isDisabled
                    ? colorScheme.outline
                    : effectiveBorderColor,
                width: _borderAnimation.value,
              ),
              boxShadow: _isHovered && !isDisabled
                  ? [
                      BoxShadow(
                        color: effectiveBorderColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(VibrantRadius.md - 1),
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(VibrantRadius.md - 1),
                splashColor: effectiveBorderColor.withValues(alpha: 0.1),
                highlightColor: effectiveBorderColor.withValues(alpha: 0.05),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: isDisabled
                              ? colorScheme.onSurfaceVariant
                              : effectiveTextColor,
                          size: 22,
                        ),
                        const SizedBox(width: VibrantSpacing.sm),
                      ],
                      Text(
                        widget.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isDisabled
                              ? colorScheme.onSurfaceVariant
                              : effectiveTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Floating action button with premium style
class PremiumFAB extends StatefulWidget {
  const PremiumFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.gradient,
    this.size = 64,
    this.enablePulse = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final Gradient? gradient;
  final double size;
  final bool enablePulse;

  @override
  State<PremiumFAB> createState() => _PremiumFABState();
}

class _PremiumFABState extends State<PremiumFAB>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _tapController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _tapController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onTap() {
    _tapController.forward().then((_) {
      _tapController.reverse();
    });
    HapticService.heavy();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? VibrantTheme.heroGradient;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _tapController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(
                    alpha: 0.4 * _pulseAnimation.value,
                  ),
                  blurRadius: 24 * _pulseAnimation.value,
                  spreadRadius: 4 * (_pulseAnimation.value - 1),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onPressed != null ? _onTap : null,
                customBorder: const CircleBorder(),
                splashColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.2),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    shape: BoxShape.circle,
                  ),
                  child: widget.label != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: widget.size * 0.35,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.label!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.size * 0.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          widget.icon,
                          color: Colors.white,
                          size: widget.size * 0.4,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Neomorphic button with soft 3D effect
class NeomorphicButton extends StatefulWidget {
  const NeomorphicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;

  @override
  State<NeomorphicButton> createState() => _NeomorphicButtonState();
}

class _NeomorphicButtonState extends State<NeomorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF0F0F0);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticService.light();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(VibrantRadius.md),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(-3, -3),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(
                      alpha: isDark ? 0.05 : 0.7,
                    ),
                    blurRadius: 8,
                    offset: const Offset(3, 3),
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(6, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(
                      alpha: isDark ? 0.1 : 0.9,
                    ),
                    blurRadius: 12,
                    offset: const Offset(-6, -6),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: VibrantSpacing.sm),
              ],
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
