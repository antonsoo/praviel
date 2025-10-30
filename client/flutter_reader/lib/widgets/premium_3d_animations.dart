import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';

/// Premium 3D card flip and transform animations
/// 2025 trend: Depth and dimension in UI

/// 3D flip card - flips between front and back
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.isFlipped = false,
    this.onFlip,
    this.flipDuration = const Duration(milliseconds: 600),
    this.flipAxis = Axis.horizontal,
  });

  final Widget front;
  final Widget back;
  final bool isFlipped;
  final VoidCallback? onFlip;
  final Duration flipDuration;
  final Axis flipAxis;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flipDuration,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticService.light();
    if (_controller.isAnimating) return;

    if (_controller.value >= 0.5) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < math.pi / 2;
          final rotationAngle = _flipAnimation.value;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001); // perspective

          if (widget.flipAxis == Axis.horizontal) {
            transform.rotateY(rotationAngle);
          } else {
            transform.rotateX(rotationAngle);
          }

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: isShowingFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateY(widget.flipAxis == Axis.horizontal ? math.pi : 0)
                      ..rotateX(widget.flipAxis == Axis.vertical ? math.pi : 0),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

/// 3D rotating card on hover/press
class RotatingCard extends StatefulWidget {
  const RotatingCard({
    super.key,
    required this.child,
    this.maxRotation = 0.1,
    this.shadowIntensity = 0.3,
    this.enableHover = true,
  });

  final Widget child;
  final double maxRotation;
  final double shadowIntensity;
  final bool enableHover;

  @override
  State<RotatingCard> createState() => _RotatingCardState();
}

class _RotatingCardState extends State<RotatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset? _localPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePosition(Offset position, Size size) {
    setState(() {
      _localPosition = Offset(
        (position.dx / size.width - 0.5) * 2, // -1 to 1
        (position.dy / size.height - 0.5) * 2, // -1 to 1
      );
    });
  }

  void _resetPosition() {
    setState(() {
      _localPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) => _resetPosition(),
      onHover: (event) {
        if (widget.enableHover) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            _updatePosition(event.localPosition, box.size);
          }
        }
      },
      child: GestureDetector(
        onPanUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            _updatePosition(
              details.localPosition,
              renderBox.size,
            );
          }
        },
        onPanEnd: (_) => _resetPosition(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: _buildTransform(),
          child: widget.child,
        ),
      ),
    );
  }

  Matrix4 _buildTransform() {
    if (_localPosition == null) {
      return Matrix4.identity();
    }

    return Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(-_localPosition!.dy * widget.maxRotation)
      ..rotateY(_localPosition!.dx * widget.maxRotation);
  }
}

/// Stacked cards with 3D depth effect
class StackedCards extends StatelessWidget {
  const StackedCards({
    super.key,
    required this.cards,
    this.offset = 8.0,
    this.scaleDecrement = 0.05,
  });

  final List<Widget> cards;
  final double offset;
  final double scaleDecrement;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(cards.length, (index) {
        final reversedIndex = cards.length - 1 - index;
        return Transform.translate(
          offset: Offset(0, reversedIndex * offset),
          child: Transform.scale(
            scale: 1.0 - (reversedIndex * scaleDecrement),
            child: Opacity(
              opacity: 1.0 - (reversedIndex * 0.2),
              child: cards[index],
            ),
          ),
        );
      }).reversed.toList(),
    );
  }
}

/// Parallax tilt card - tilts based on device orientation or mouse position
class ParallaxTiltCard extends StatefulWidget {
  const ParallaxTiltCard({
    super.key,
    required this.child,
    this.tiltFactor = 0.01,
    this.shadowIntensity = 0.2,
  });

  final Widget child;
  final double tiltFactor;
  final double shadowIntensity;

  @override
  State<ParallaxTiltCard> createState() => _ParallaxTiltCardState();
}

class _ParallaxTiltCardState extends State<ParallaxTiltCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateTilt(Offset position, Size size) {
    setState(() {
      _tilt = Offset(
        (position.dx / size.width - 0.5) * widget.tiltFactor,
        (position.dy / size.height - 0.5) * widget.tiltFactor,
      );
    });
  }

  void _resetTilt() {
    setState(() {
      _tilt = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) => _resetTilt(),
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          _updateTilt(event.localPosition, box.size);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-_tilt.dy)
          ..rotateY(_tilt.dx),
        child: widget.child,
      ),
    );
  }
}

/// Expanding card animation - scales and reveals content
class ExpandingCard extends StatefulWidget {
  const ExpandingCard({
    super.key,
    required this.collapsedChild,
    required this.expandedChild,
    this.isExpanded = false,
    this.onToggle,
    this.duration = const Duration(milliseconds: 400),
  });

  final Widget collapsedChild;
  final Widget expandedChild;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Duration duration;

  @override
  State<ExpandingCard> createState() => _ExpandingCardState();
}

class _ExpandingCardState extends State<ExpandingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ExpandingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticService.medium();
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                // Collapsed state
                Opacity(
                  opacity: 1.0 - _fadeAnimation.value,
                  child: widget.collapsedChild,
                ),
                // Expanded state
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: widget.expandedChild,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card with depth shadow that responds to tilt
class DepthCard extends StatefulWidget {
  const DepthCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.shadowColor,
    this.maxShadowOffset = 20.0,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final Color? shadowColor;
  final double maxShadowOffset;

  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard> {
  Offset _tilt = Offset.zero;

  void _updateTilt(Offset position, Size size) {
    setState(() {
      _tilt = Offset(
        (position.dx / size.width - 0.5) * 2,
        (position.dy / size.height - 0.5) * 2,
      );
    });
  }

  void _resetTilt() {
    setState(() {
      _tilt = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveShadowColor =
        widget.shadowColor ?? theme.colorScheme.shadow;
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(VibrantRadius.xl);

    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) => _resetTilt(),
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          _updateTilt(event.localPosition, box.size);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: [
            BoxShadow(
              color: effectiveShadowColor.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: Offset(
                _tilt.dx * widget.maxShadowOffset,
                _tilt.dy * widget.maxShadowOffset + 10,
              ),
            ),
            BoxShadow(
              color: effectiveShadowColor.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: Offset(
                _tilt.dx * widget.maxShadowOffset * 0.5,
                _tilt.dy * widget.maxShadowOffset * 0.5 + 5,
              ),
            ),
          ],
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-_tilt.dy * 0.05)
            ..rotateY(_tilt.dx * 0.05),
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
