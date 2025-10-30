import 'dart:ui';
import 'package:flutter/material.dart';

/// Modern glassmorphism card with frosted glass blur effect (2025 design trend)
/// Inspired by Apple's Liquid Glass from WWDC 2025
class GlassmorphismCard extends StatelessWidget {
  const GlassmorphismCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderOpacity = 0.2,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.gradient,
    this.border = true,
    this.elevation = 0,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final bool border;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: elevation > 0
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: elevation * 4,
                  spreadRadius: elevation * 0.5,
                  offset: Offset(0, elevation * 2),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: opacity),
                      Colors.white.withValues(alpha: opacity * 0.5),
                    ],
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border
                  ? Border.all(
                      color: Colors.white.withValues(alpha: borderOpacity),
                      width: 1.5,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Frosted glass app bar with blur effect
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.blur = 10.0,
    this.height = kToolbarHeight,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double blur;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.7),
                (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.5),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: leading,
            title: title,
            actions: actions,
          ),
        ),
      ),
    );
  }
}

/// Liquid glass button with dynamic blur and refraction (WWDC 2025 inspired)
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.blur = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double blur;
  final EdgeInsetsGeometry padding;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel:
          widget.onPressed != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassmorphismCard(
          blur: widget.blur,
          opacity: 0.15,
          borderOpacity: 0.3,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}
