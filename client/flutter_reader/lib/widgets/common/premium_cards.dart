import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/advanced_micro_interactions.dart';

/// Premium card designs for 2025 modern UI
/// Glassmorphism, neumorphism, and gradient overlays

/// Glassmorphic card with blur and transparency
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = 16,
    this.opacity = 0.15,
    this.borderRadius = VibrantRadius.lg,
    this.padding = const EdgeInsets.all(VibrantSpacing.lg),
    this.border = true,
    this.elevation = 0,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool border;
  final int elevation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border
                ? Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1.5,
                  )
                : null,
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: elevation * 4.0,
                      offset: Offset(0, elevation * 2.0),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Neumorphic card - soft UI design
class NeumorphicCard extends StatelessWidget {
  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VibrantSpacing.lg),
    this.borderRadius = VibrantRadius.lg,
    this.pressed = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseColor = isDark ? colorScheme.surface : colorScheme.surfaceContainer;

    return AnimatedContainer(
      duration: VibrantDuration.fast,
      curve: VibrantCurve.smooth,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: pressed
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.7),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.8),
                  offset: const Offset(-6, -6),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Gradient card with overlay
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding = const EdgeInsets.all(VibrantSpacing.lg),
    this.borderRadius = VibrantRadius.lg,
    this.elevation = 2,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final int elevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15 * elevation),
            blurRadius: 4.0 * elevation,
            offset: Offset(0, 2.0 * elevation),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Holographic card with shifting gradient
class HolographicCard extends StatefulWidget {
  const HolographicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VibrantSpacing.lg),
    this.borderRadius = VibrantRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                  _animation.value,
                )!,
                Color.lerp(
                  const Color(0xFF764BA2),
                  const Color(0xFFF093FB),
                  _animation.value,
                )!,
                Color.lerp(
                  const Color(0xFFF093FB),
                  const Color(0xFF4FACFE),
                  _animation.value,
                )!,
              ],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0xFF667EEA),
                  const Color(0xFFF093FB),
                  _animation.value,
                )!
                    .withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Card with animated border gradient
class AnimatedBorderCard extends StatefulWidget {
  const AnimatedBorderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VibrantSpacing.lg),
    this.borderRadius = VibrantRadius.lg,
    this.borderWidth = 2.0,
    this.gradientColors = const [
      Color(0xFF6366F1),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
    ],
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderWidth;
  final List<Color> gradientColors;

  @override
  State<AnimatedBorderCard> createState() => _AnimatedBorderCardState();
}

class _AnimatedBorderCardState extends State<AnimatedBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            gradient: SweepGradient(
              colors: widget.gradientColors,
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(
                widget.borderRadius - widget.borderWidth,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Interactive card with 3D depth and hover effects
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(VibrantSpacing.lg),
    this.borderRadius = VibrantRadius.lg,
    this.enable3D = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool enable3D;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovering = false;
  double _rotateX = 0;
  double _rotateY = 0;

  void _handleHover(PointerHoverEvent event) {
    if (!widget.enable3D) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.globalToLocal(event.position);
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      setState(() {
        _rotateX = ((position.dy - centerY) / centerY) * 0.05;
        _rotateY = ((position.dx - centerX) / centerX) * -0.05;
        _isHovering = true;
      });
    }
  }

  void _handleExit(PointerExitEvent event) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
      _isHovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onHover: _handleHover,
      onExit: _handleExit,
      child: GestureDetector(
        onTap: () {
          AdvancedHaptics.light();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: VibrantDuration.normal,
          curve: VibrantCurve.smooth,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_rotateX)
            ..rotateY(_rotateY),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovering ? 0.2 : 0.1),
                blurRadius: _isHovering ? 20 : 10,
                offset: Offset(0, _isHovering ? 12 : 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shimmer card - loading state
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 200,
    this.borderRadius = VibrantRadius.lg,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
