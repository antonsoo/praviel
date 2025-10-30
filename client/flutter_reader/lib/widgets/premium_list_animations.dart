import 'package:flutter/material.dart';

/// Premium staggered list animations for smooth content reveals
/// 2025 trend: Orchestrated, choreographed UI animations

/// Staggered fade-in animation for list items
/// Each item animates in sequence with a slight delay
class StaggeredListAnimation extends StatelessWidget {
  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
    this.verticalOffset = 50.0,
  });

  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, verticalOffset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated list wrapper that handles staggered animations automatically
class StaggeredAnimatedList extends StatelessWidget {
  const StaggeredAnimatedList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
    this.verticalOffset = 50.0,
    this.padding,
    this.physics,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;
  final double verticalOffset;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return StaggeredListAnimation(
          index: index,
          delay: staggerDelay,
          duration: animationDuration,
          curve: curve,
          verticalOffset: verticalOffset,
          child: children[index],
        );
      },
    );
  }
}

/// Slide-in list animation with scale effect
class SlideScaleListItem extends StatefulWidget {
  const SlideScaleListItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
  });

  final int index;
  final Widget child;
  final Duration delay;

  @override
  State<SlideScaleListItem> createState() => _SlideScaleListItemState();
}

class _SlideScaleListItemState extends State<SlideScaleListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation after delay
    Future.delayed(widget.delay * widget.index, () {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Cascading reveal animation - like cards falling into place
class CascadingReveal extends StatefulWidget {
  const CascadingReveal({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.slideDistance = 80.0,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final double slideDistance;

  @override
  State<CascadingReveal> createState() => _CascadingRevealState();
}

class _CascadingRevealState extends State<CascadingReveal>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<double>(begin: widget.slideDistance, end: 0.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimations[index].value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimations[index].value),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}

/// Bouncing entrance animation for list items
class BouncingListItem extends StatefulWidget {
  const BouncingListItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
  });

  final int index;
  final Widget child;
  final Duration delay;

  @override
  State<BouncingListItem> createState() => _BouncingListItemState();
}

class _BouncingListItemState extends State<BouncingListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.9,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    Future.delayed(widget.delay * widget.index, () {
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
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _bounceAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// Rotating fade-in animation
class RotatingFadeIn extends StatefulWidget {
  const RotatingFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 80),
  });

  final int index;
  final Widget child;
  final Duration delay;

  @override
  State<RotatingFadeIn> createState() => _RotatingFadeInState();
}

class _RotatingFadeInState extends State<RotatingFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotateAnimation = Tween<double>(
      begin: -0.2,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay * widget.index, () {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.rotate(angle: _rotateAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Grid item stagger animation
class StaggeredGridAnimation extends StatelessWidget {
  const StaggeredGridAnimation({
    super.key,
    required this.index,
    required this.child,
    this.gridWidth = 2,
    this.baseDelay = const Duration(milliseconds: 50),
  });

  final int index;
  final Widget child;
  final int gridWidth;
  final Duration baseDelay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        );
      },
      child: child,
    );
  }
}

/// Shimmer reveal - items appear with a light sweep effect
class ShimmerReveal extends StatefulWidget {
  const ShimmerReveal({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  final List<Widget> children;
  final Duration staggerDelay;

  @override
  State<ShimmerReveal> createState() => _ShimmerRevealState();
}

class _ShimmerRevealState extends State<ShimmerReveal>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _shimmerAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _shimmerAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: -1.0,
        end: 2.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                Positioned.fill(
                  child: ClipRect(
                    child: Transform.translate(
                      offset: Offset(_shimmerAnimations[index].value * 300, 0),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}
