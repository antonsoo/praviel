import 'package:flutter/material.dart';

/// Duolingo-style shake animation for incorrect answers
/// Shakes horizontally ±8px over 400ms (3 cycles)
class ShakeAnimation extends StatefulWidget {
  const ShakeAnimation({
    super.key,
    required this.child,
    required this.shake,
    this.onComplete,
  });

  final Widget child;
  final bool shake;
  final VoidCallback? onComplete;

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create shake pattern: 0 → 8 → -8 → 8 → -8 → 8 → 0
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
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
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Success flash animation for correct answers
/// Green background flash with scale effect
class SuccessFlashAnimation extends StatefulWidget {
  const SuccessFlashAnimation({
    super.key,
    required this.child,
    required this.flash,
    this.onComplete,
  });

  final Widget child;
  final bool flash;
  final VoidCallback? onComplete;

  @override
  State<SuccessFlashAnimation> createState() => _SuccessFlashAnimationState();
}

class _SuccessFlashAnimationState extends State<SuccessFlashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _colorAnimation =
        ColorTween(
          begin: Colors.transparent,
          end: const Color(0xFF58CC02).withValues(alpha: 0.15),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.5, curve: Curves.easeOut),
          ),
        );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(SuccessFlashAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flash && !oldWidget.flash) {
      _controller.forward(from: 0);
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
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(16),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Checkmark scale animation for correct answers
/// Scales from 0.5 to 1.0 with bounce
class CheckmarkScaleAnimation extends StatefulWidget {
  const CheckmarkScaleAnimation({
    super.key,
    required this.child,
    required this.show,
  });

  final Widget child;
  final bool show;

  @override
  State<CheckmarkScaleAnimation> createState() =>
      _CheckmarkScaleAnimationState();
}

class _CheckmarkScaleAnimationState extends State<CheckmarkScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(CheckmarkScaleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    } else if (!widget.show && oldWidget.show) {
      _controller.reverse();
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// XP float-up animation for lesson completion
/// Floats up 30px over 1200ms with fade
class XpFloatAnimation extends StatefulWidget {
  const XpFloatAnimation({
    super.key,
    required this.child,
    required this.animate,
    this.onComplete,
  });

  final Widget child;
  final bool animate;
  final VoidCallback? onComplete;

  @override
  State<XpFloatAnimation> createState() => _XpFloatAnimationState();
}

class _XpFloatAnimationState extends State<XpFloatAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _offsetAnimation = Tween<double>(
      begin: 0,
      end: -30,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(XpFloatAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
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
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offsetAnimation.value),
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Streak pulse animation
/// Scales from 1.0 to 1.2 and back with elastic curve
class StreakPulseAnimation extends StatefulWidget {
  const StreakPulseAnimation({
    super.key,
    required this.child,
    this.continuous = false,
  });

  final Widget child;
  final bool continuous;

  @override
  State<StreakPulseAnimation> createState() => _StreakPulseAnimationState();
}

class _StreakPulseAnimationState extends State<StreakPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    if (widget.continuous) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(StreakPulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.continuous && !oldWidget.continuous) {
      _controller.repeat();
    } else if (!widget.continuous && oldWidget.continuous) {
      _controller.stop();
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}
