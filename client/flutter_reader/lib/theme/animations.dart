import 'package:flutter/material.dart';

/// Animation duration constants following Material Design guidelines
class AppAnimations {
  const AppAnimations._();

  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve spring = Curves.easeOutBack;

  // Custom curves for delightful UX
  static const Curve smoothEnter = Curves.easeOutCubic;
  static const Curve smoothExit = Curves.easeInCubic;
  static const Curve emphasize = Curves.easeOutQuint;
}

/// Shake animation controller for error feedback
class ShakeAnimation extends StatefulWidget {
  const ShakeAnimation({
    required this.child,
    required this.trigger,
    super.key,
    this.duration = const Duration(milliseconds: 400),
    this.offset = 8.0,
  });

  final Widget child;
  final bool trigger;
  final Duration duration;
  final double offset;

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _previousTrigger = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: -1.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 1.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: -0.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.5, end: 0.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !_previousTrigger) {
      _controller.forward(from: 0.0);
    }
    _previousTrigger = widget.trigger;
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
        return Transform.translate(
          offset: Offset(_animation.value * widget.offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Bouncy scale animation for buttons
class BounceAnimation extends StatefulWidget {
  const BounceAnimation({
    required this.child,
    super.key,
    this.onTap,
    this.scale = 0.95,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.smoothEnter,
        reverseCurve: AppAnimations.bounce,
      ),
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
    widget.onTap?.call();
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
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Slide-in animation for page transitions
class SlideInTransition extends PageRouteBuilder {
  SlideInTransition({
    required Widget page,
    super.settings,
    Offset begin = const Offset(1.0, 0.0),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: AppAnimations.normal,
         reverseTransitionDuration: AppAnimations.fast,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final slideAnimation = Tween(begin: begin, end: Offset.zero).animate(
             CurvedAnimation(
               parent: animation,
               curve: AppAnimations.smoothEnter,
               reverseCurve: AppAnimations.smoothExit,
             ),
           );

           final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
             CurvedAnimation(
               parent: animation,
               curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
             ),
           );

           return SlideTransition(
             position: slideAnimation,
             child: FadeTransition(opacity: fadeAnimation, child: child),
           );
         },
       );
}

/// Scale transition for modal dialogs
class ScalePageTransition extends PageRouteBuilder {
  ScalePageTransition({required Widget page, super.settings})
    : super(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.54),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AppAnimations.normal,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: AppAnimations.spring),
          );

          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return Transform.scale(
            scale: scaleAnimation.value,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
      );
}

/// Animated counter for XP and streak numbers
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    super.key,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: AppAnimations.emphasize,
      builder: (context, value, child) {
        return Text('$prefix${value.toInt()}$suffix', style: style);
      },
    );
  }
}
