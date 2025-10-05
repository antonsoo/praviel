import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated gradient background for stunning visual impact
/// Creates a slowly morphing gradient effect
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    required this.child,
    super.key,
    this.colors = const [
      Color(0xFF667EEA),
      Color(0xFF764BA2),
      Color(0xFFF093FB),
    ],
    this.duration = const Duration(seconds: 6),
  });

  final Widget child;
  final List<Color> colors;
  final Duration duration;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_controller.value * 2 * math.pi),
                math.sin(_controller.value * 2 * math.pi),
              ),
              end: Alignment(
                -math.cos(_controller.value * 2 * math.pi),
                -math.sin(_controller.value * 2 * math.pi),
              ),
              colors: widget.colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Mesh gradient background with floating orbs
class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    required this.child,
    super.key,
    this.primaryColor = const Color(0xFF667EEA),
    this.secondaryColor = const Color(0xFF764BA2),
  });

  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor.withOpacity(0.8),
                widget.secondaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),

        // Animated orb 1
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.1 +
                  (math.sin(_controller1.value * 2 * math.pi) * 50),
              left: MediaQuery.of(context).size.width * 0.2 +
                  (math.cos(_controller1.value * 2 * math.pi) * 50),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.primaryColor.withOpacity(0.4),
                      widget.primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Animated orb 2
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return Positioned(
              bottom: MediaQuery.of(context).size.height * 0.2 +
                  (math.sin(_controller2.value * 2 * math.pi) * 60),
              right: MediaQuery.of(context).size.width * 0.1 +
                  (math.cos(_controller2.value * 2 * math.pi) * 60),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.secondaryColor.withOpacity(0.5),
                      widget.secondaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Animated orb 3
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.5 +
                  (math.sin(_controller3.value * 2 * math.pi) * 40),
              right: MediaQuery.of(context).size.width * 0.6 +
                  (math.cos(_controller3.value * 2 * math.pi) * 40),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.primaryColor.withOpacity(0.3),
                      widget.primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

/// Parallax background with depth
class ParallaxBackground extends StatefulWidget {
  const ParallaxBackground({
    required this.child,
    super.key,
    this.color1 = const Color(0xFF667EEA),
    this.color2 = const Color(0xFF764BA2),
  });

  final Widget child;
  final Color color1;
  final Color color2;

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  double _offsetX = 0;
  double _offsetY = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _offsetX += details.delta.dx * 0.02;
          _offsetY += details.delta.dy * 0.02;
        });
      },
      child: Stack(
        children: [
          // Background layer
          Transform.translate(
            offset: Offset(_offsetX * 0.5, _offsetY * 0.5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color1.withOpacity(0.8),
                    widget.color2.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // Mid layer
          Transform.translate(
            offset: Offset(_offsetX * 0.8, _offsetY * 0.8),
            child: Opacity(
              opacity: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.5),
                    radius: 1.0,
                    colors: [
                      widget.color1.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          widget.child,
        ],
      ),
    );
  }
}
