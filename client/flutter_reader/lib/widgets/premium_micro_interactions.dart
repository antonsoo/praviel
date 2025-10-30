import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';

/// Premium micro-interactions inspired by 2025 UI/UX trends
/// These widgets add delightful, satisfying feedback to user actions

/// Shimmer button with animated gradient sweep
/// Catches attention without being overwhelming
class ShimmerButton extends StatefulWidget {
  const ShimmerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.shimmerDuration = const Duration(milliseconds: 2000),
    this.shimmerInterval = const Duration(seconds: 3),
    this.borderRadius,
    this.padding,
    this.enableHaptics = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final Duration shimmerDuration;
  final Duration shimmerInterval;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptics;

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration,
    );

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startShimmerCycle();
  }

  Future<void> _startShimmerCycle() async {
    while (mounted) {
      await Future.delayed(widget.shimmerInterval);
      if (mounted) {
        await _controller.forward();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradient ?? VibrantTheme.premiumGradient;
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(VibrantRadius.lg);

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            boxShadow: [
              BoxShadow(
                color: effectiveGradient.colors.first.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: effectiveBorderRadius,
            child: InkWell(
              onTap: widget.onPressed == null
                  ? null
                  : () {
                      if (widget.enableHaptics) {
                        HapticService.medium();
                      }
                      widget.onPressed!();
                    },
              borderRadius: effectiveBorderRadius,
              child: Stack(
                children: [
                  // Base gradient
                  Container(
                    padding: widget.padding ??
                        const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.xl,
                          vertical: VibrantSpacing.md,
                        ),
                    decoration: BoxDecoration(
                      gradient: effectiveGradient,
                      borderRadius: effectiveBorderRadius,
                    ),
                    child: child,
                  ),
                  // Shimmer overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: effectiveBorderRadius,
                      child: Transform.translate(
                        offset: Offset(_shimmerAnimation.value * 200, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Particle burst effect widget
/// Shows expanding particles when triggered
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.isActive,
    this.particleCount = 12,
    this.colors,
    this.size = 100,
  });

  final bool isActive;
  final int particleCount;
  final List<Color>? colors;
  final double size;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColors = widget.colors ??
        [
          VibrantTheme.xpGradient.colors.first,
          VibrantTheme.streakGradient.colors.first,
          VibrantTheme.successGradient.colors.first,
          VibrantTheme.premiumGradient.colors.first,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(widget.particleCount, (index) {
              final angle = (2 * math.pi * index) / widget.particleCount;
              final distance = widget.size * 0.4 * _expandAnimation.value;
              final xOffset = distance * math.cos(angle);
              final yOffset = distance * math.sin(angle);
              final color = effectiveColors[index % effectiveColors.length];

              return Transform.translate(
                offset: Offset(xOffset, yOffset),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Ripple effect widget that expands outward
/// Great for indicating taps or achievements
class RippleEffect extends StatefulWidget {
  const RippleEffect({
    super.key,
    required this.isActive,
    this.color,
    this.rippleCount = 3,
    this.size = 200,
  });

  final bool isActive;
  final Color? color;
  final int rippleCount;
  final double size;

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(RippleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(widget.rippleCount, (index) {
              final delay = index / widget.rippleCount;
              final adjustedValue =
                  (_controller.value + delay) % 1.0;

              return Transform.scale(
                scale: adjustedValue,
                child: Opacity(
                  opacity: 1.0 - adjustedValue,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: effectiveColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Morphing icon button that smoothly transitions between two icons
class MorphingIconButton extends StatefulWidget {
  const MorphingIconButton({
    super.key,
    required this.icon1,
    required this.icon2,
    required this.isIcon1,
    required this.onPressed,
    this.size = 24.0,
    this.color,
    this.duration = const Duration(milliseconds: 300),
  });

  final IconData icon1;
  final IconData icon2;
  final bool isIcon1;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final Duration duration;

  @override
  State<MorphingIconButton> createState() => _MorphingIconButtonState();
}

class _MorphingIconButtonState extends State<MorphingIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(_controller);

    if (!widget.isIcon1) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MorphingIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isIcon1 != oldWidget.isIcon1) {
      if (widget.isIcon1) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticService.light();
        widget.onPressed();
      },
      icon: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_rotationAnimation.value),
              child: _controller.value < 0.5
                  ? Icon(
                      widget.icon1,
                      size: widget.size,
                      color: widget.color,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: Icon(
                        widget.icon2,
                        size: widget.size,
                        color: widget.color,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// Pulse dot indicator - great for showing "live" or "active" status
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    this.size = 12.0,
    this.color,
    this.pulseDuration = const Duration(milliseconds: 1500),
  });

  final double size;
  final Color? color;
  final Duration pulseDuration;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing outer ring
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: widget.size * 2,
                  height: widget.size * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: effectiveColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            // Solid center dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor,
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bouncing arrow - great for indicating "scroll down" or directional cues
class BouncingArrow extends StatefulWidget {
  const BouncingArrow({
    super.key,
    this.direction = AxisDirection.down,
    this.color,
    this.size = 32.0,
  });

  final AxisDirection direction;
  final Color? color;
  final double size;

  @override
  State<BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<BouncingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIconForDirection() {
    switch (widget.direction) {
      case AxisDirection.up:
        return Icons.keyboard_arrow_up_rounded;
      case AxisDirection.down:
        return Icons.keyboard_arrow_down_rounded;
      case AxisDirection.left:
        return Icons.keyboard_arrow_left_rounded;
      case AxisDirection.right:
        return Icons.keyboard_arrow_right_rounded;
    }
  }

  Offset _getOffsetForDirection(double value) {
    switch (widget.direction) {
      case AxisDirection.up:
        return Offset(0, -value);
      case AxisDirection.down:
        return Offset(0, value);
      case AxisDirection.left:
        return Offset(-value, 0);
      case AxisDirection.right:
        return Offset(value, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _getOffsetForDirection(_bounceAnimation.value),
          child: Icon(
            _getIconForDirection(),
            size: widget.size,
            color: effectiveColor,
          ),
        );
      },
    );
  }
}
