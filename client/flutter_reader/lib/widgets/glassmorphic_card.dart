import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';

/// Premium glassmorphic card with frosted glass effect
/// Inspired by iOS design language and modern web apps
class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderGradient,
    this.blur = 20.0,
    this.opacity = 0.15,
    this.borderOpacity = 0.25,
    this.borderWidth = 1.5,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.shadowColor,
    this.elevation = 0,
  });

  final Widget child;
  final Gradient? gradient;
  final Gradient? borderGradient;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? shadowColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(VibrantRadius.xl);

    final cardContent = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(VibrantSpacing.lg),
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: opacity),
                    Colors.white.withValues(alpha: opacity * 0.6),
                  ],
                ),
            borderRadius: effectiveBorderRadius,
            border: borderGradient != null
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: borderOpacity),
                    width: borderWidth,
                  ),
          ),
          child: child,
        ),
      ),
    );

    final cardWithShadow = elevation > 0
        ? Container(
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: (shadowColor ?? colorScheme.shadow)
                      .withValues(alpha: 0.08 * elevation),
                  blurRadius: 8.0 * elevation,
                  offset: Offset(0, 4.0 * elevation),
                ),
                BoxShadow(
                  color: (shadowColor ?? colorScheme.shadow)
                      .withValues(alpha: 0.05 * elevation),
                  blurRadius: 4.0 * elevation,
                  offset: Offset(0, 2.0 * elevation),
                ),
              ],
            ),
            child: cardContent,
          )
        : cardContent;

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveBorderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveBorderRadius,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: cardWithShadow,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardWithShadow,
    );
  }
}

/// Premium animated card with scale and glow effects
class PremiumAnimatedCard extends StatefulWidget {
  const PremiumAnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.enableHoverEffect = true,
    this.enableGlow = true,
    this.glowColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enableHoverEffect;
  final bool enableGlow;
  final Color? glowColor;

  @override
  State<PremiumAnimatedCard> createState() => _PremiumAnimatedCardState();
}

class _PremiumAnimatedCardState extends State<PremiumAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChange(bool hovering) {
    if (!widget.enableHoverEffect) return;

    setState(() => _isHovered = hovering);
    if (hovering && !_isPressed) {
      _controller.forward();
    } else if (!hovering && !_isPressed) {
      _controller.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.value = 0.5;
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(VibrantRadius.xl);
    final effectiveGlowColor =
        widget.glowColor ?? colorScheme.primary.withValues(alpha: 0.3);

    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? _onTapDown : null,
        onTapUp: widget.onTap != null ? _onTapUp : null,
        onTapCancel: widget.onTap != null ? _onTapCancel : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Container(
                decoration: widget.enableGlow && _glowAnimation.value > 0
                    ? BoxDecoration(
                        borderRadius: effectiveBorderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: effectiveGlowColor.withValues(
                              alpha: 0.3 * _glowAnimation.value,
                            ),
                            blurRadius: 20 * _glowAnimation.value,
                            spreadRadius: 2 * _glowAnimation.value,
                          ),
                          BoxShadow(
                            color: effectiveGlowColor.withValues(
                              alpha: 0.2 * _glowAnimation.value,
                            ),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 0,
                          ),
                        ],
                      )
                    : null,
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: widget.gradient ?? VibrantTheme.premiumGradient,
                    borderRadius: effectiveBorderRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Neomorphic card with soft shadows and highlights
class NeomorphicCard extends StatelessWidget {
  const NeomorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.depth = 8.0,
    this.isPressed = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double depth;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF0F0F0);
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(VibrantRadius.xl);

    // Note: Flutter doesn't support inset shadows in BoxShadow
    // Using regular shadows for pressed state with smaller offset/blur
    final shadows = isPressed
        ? <BoxShadow>[
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: depth * 0.3,
              offset: Offset(depth * 0.15, depth * 0.15),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: depth,
              offset: Offset(depth * 0.5, depth * 0.5),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.9),
              blurRadius: depth,
              offset: Offset(-depth * 0.5, -depth * 0.5),
            ),
          ];

    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: effectiveBorderRadius,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// PulseCard - Basic card with subtle animations (improved)
class PulseCard extends StatelessWidget {
  const PulseCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.elevation = 2.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Border? border;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(VibrantRadius.lg);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: VibrantShadow.md(colorScheme),
      ),
      child: Material(
        color: color ?? colorScheme.surface,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: Container(
            padding: padding ?? const EdgeInsets.all(VibrantSpacing.lg),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: effectiveBorderRadius,
              border: border ??
                  Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass card for reader tab (already exists in app, enhanced version)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      blur: 16.0,
      opacity: 0.12,
      borderOpacity: 0.2,
      elevation: 1.5,
      child: child,
    );
  }
}
