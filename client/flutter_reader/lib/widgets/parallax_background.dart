import 'package:flutter/material.dart';

/// Parallax background that moves slower than scroll for depth effect
class ParallaxBackground extends StatelessWidget {
  const ParallaxBackground({
    super.key,
    required this.gradient,
    this.parallaxFactor = 0.5,
    this.child,
  });

  final Gradient gradient;
  final double parallaxFactor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Stack(
            children: [
              // Background with parallax effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
              if (child != null) child!,
            ],
          ),
        );
      },
    );
  }
}

/// Parallax layer that responds to scroll
class ParallaxScrollLayer extends StatefulWidget {
  const ParallaxScrollLayer({
    super.key,
    required this.scrollController,
    required this.child,
    this.parallaxFactor = 0.3,
  });

  final ScrollController scrollController;
  final Widget child;
  final double parallaxFactor;

  @override
  State<ParallaxScrollLayer> createState() => _ParallaxScrollLayerState();
}

class _ParallaxScrollLayerState extends State<ParallaxScrollLayer> {
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _offset = widget.scrollController.offset * widget.parallaxFactor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -_offset),
      child: widget.child,
    );
  }
}

/// Animated gradient that shifts colors smoothly
class AnimatedMeshGradient extends StatefulWidget {
  const AnimatedMeshGradient({
    super.key,
    required this.colors,
    this.duration = const Duration(seconds: 8),
  });

  final List<Color> colors;
  final Duration duration;

  @override
  State<AnimatedMeshGradient> createState() => _AnimatedMeshGradientState();
}

class _AnimatedMeshGradientState extends State<AnimatedMeshGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
              stops: [
                0.0,
                _animation.value * 0.5,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 3D depth card with shadow and elevation
class DepthCard extends StatelessWidget {
  const DepthCard({
    super.key,
    required this.child,
    this.depth = 8.0,
    this.borderRadius = 20.0,
    this.padding,
    this.color,
  });

  final Widget child;
  final double depth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Primary shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: depth * 2,
            spreadRadius: depth * 0.2,
            offset: Offset(0, depth),
          ),
          // Secondary shadow for atmosphere
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: depth * 4,
            spreadRadius: depth * 0.5,
            offset: Offset(0, depth * 1.5),
          ),
          // Highlight for dimension
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 1,
              spreadRadius: -1,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}
