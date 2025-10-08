import 'dart:math' show pi;
import 'package:flutter/material.dart';

/// Animation durations following Material Design guidelines
class VibrantDuration {
  /// Micro-interactions (100-200ms)
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 200);

  /// Standard animations (250-400ms)
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration moderate = Duration(milliseconds: 400);

  /// Emphasis animations (500-700ms)
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);

  /// Celebration animations (1000ms+)
  static const Duration celebration = Duration(milliseconds: 1000);
  static const Duration epic = Duration(milliseconds: 1500);
}

/// Animation curves for personality
class VibrantCurve {
  /// Bouncy entrance
  static const Curve bounceIn = Curves.elasticOut;

  /// Smooth standard
  static const Curve smooth = Curves.easeOutCubic;

  /// Snappy feel
  static const Curve snappy = Curves.easeInOutCubic;

  /// Playful overshoot
  static const Curve playful = Curves.easeOutBack;

  /// Springy physics
  static const Curve spring = Curves.easeOutQuart;
}

/// Animated scale button with haptic feedback
class AnimatedScaleButton extends StatefulWidget {
  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.95,
    this.duration = VibrantDuration.quick,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Animated card that pulses on tap
class PulseCard extends StatefulWidget {
  const PulseCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.borderRadius,
    this.elevation = 2,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final double elevation;

  @override
  State<PulseCard> createState() => _PulseCardState();
}

class _PulseCardState extends State<PulseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.quick,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(20);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.gradient == null ? (widget.color ?? colorScheme.surface) : null,
            gradient: widget.gradient,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08 * widget.elevation),
                blurRadius: 4 * widget.elevation,
                offset: Offset(0, 2 * widget.elevation),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: borderRadius,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shake animation for errors
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    this.shakeCount = 3,
    this.shakeOffset = 8.0,
    this.duration = VibrantDuration.moderate,
  });

  final Widget child;
  final int shakeCount;
  final double shakeOffset;
  final Duration duration;

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = TweenSequence<double>(
      List.generate(widget.shakeCount * 2, (index) {
        return TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: index.isEven ? widget.shakeOffset : -widget.shakeOffset,
          ).chain(CurveTween(curve: Curves.elasticIn)),
          weight: 1.0,
        );
      })..add(
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.0),
          weight: 1.0,
        ),
      ),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Slide in from bottom animation
class SlideInFromBottom extends StatefulWidget {
  const SlideInFromBottom({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = VibrantDuration.moderate,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<SlideInFromBottom> createState() => _SlideInFromBottomState();
}

class _SlideInFromBottomState extends State<SlideInFromBottom>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.spring,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Scale in animation for new elements
class ScaleIn extends StatefulWidget {
  const ScaleIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = VibrantDuration.moderate,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn>
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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.playful,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Floating XP text animation
class FloatingXP extends StatefulWidget {
  const FloatingXP({
    super.key,
    required this.xp,
    required this.startPosition,
    this.onComplete,
  });

  final int xp;
  final Offset startPosition;
  final VoidCallback? onComplete;

  @override
  State<FloatingXP> createState() => _FloatingXPState();
}

class _FloatingXPState extends State<FloatingXP>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideUp;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );

    _slideUp = Tween<double>(
      begin: 0.0,
      end: -80.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx,
          top: widget.startPosition.dy + _slideUp.value,
          child: Opacity(
            opacity: _fade.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '+${widget.xp} XP',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Success pulse animation
class SuccessPulse extends StatefulWidget {
  const SuccessPulse({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SuccessPulse> createState() => SuccessPulseState();
}

class SuccessPulseState extends State<SuccessPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.playful,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void pulse() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

/// Error shake wrapper - use this for shake on error
class ErrorShakeWrapper extends StatefulWidget {
  const ErrorShakeWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ErrorShakeWrapper> createState() => ErrorShakeWrapperState();
}

class ErrorShakeWrapperState extends State<ErrorShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Flip card animation - for revealing answers
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.isFlipped = false,
  });

  final Widget front;
  final Widget back;
  final bool isFlipped;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: angle <= pi / 2
              ? widget.front
              : Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: widget.back,
                ),
        );
      },
    );
  }
}

/// Bounce in animation - for new elements
class BounceIn extends StatefulWidget {
  const BounceIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Shimmer loading effect
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// Grow animation - for counters/numbers
class GrowNumber extends StatefulWidget {
  const GrowNumber({
    super.key,
    required this.value,
    required this.style,
  });

  final int value;
  final TextStyle? style;

  @override
  State<GrowNumber> createState() => _GrowNumberState();
}

class _GrowNumberState extends State<GrowNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.playful,
    );

    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(GrowNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 1.0 + (_animation.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Text(
            '${widget.value}',
            style: widget.style,
          ),
        );
      },
    );
  }
}
