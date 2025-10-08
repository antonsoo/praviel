import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// Micro-interactions - subtle feedback on EVERY user action
/// Based on 2025 Flutter UI trends emphasizing responsive micro-interactions

/// Wrap any tappable widget to add haptic + sound + scale micro-interaction
class MicroTap extends StatefulWidget {
  const MicroTap({
    super.key,
    required this.child,
    required this.onTap,
    this.enableHaptic = true,
    this.enableSound = true,
    this.enableScale = true,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enableHaptic;
  final bool enableSound;
  final bool enableScale;
  final double scaleDown;
  final Duration duration;

  @override
  State<MicroTap> createState() => _MicroTapState();
}

class _MicroTapState extends State<MicroTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Micro-interaction sequence: scale + haptic + sound (all parallel)
    if (widget.enableScale) {
      _controller.forward().then((_) => _controller.reverse());
    }
    if (widget.enableHaptic) {
      unawaited(HapticService.light());
    }
    if (widget.enableSound) {
      unawaited(SoundService.instance.tap());
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableScale) {
      return GestureDetector(onTap: _handleTap, child: widget.child);
    }

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Swipe-to-dismiss with micro-interaction feedback
class MicroSwipe extends StatelessWidget {
  const MicroSwipe({
    super.key,
    required this.child,
    required this.onDismissed,
    this.direction = DismissDirection.horizontal,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final void Function(DismissDirection) onDismissed;
  final DismissDirection direction;
  final bool enableHaptic;
  final bool enableSound;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: direction,
      onDismissed: (dir) {
        if (enableHaptic) HapticService.medium();
        if (enableSound) SoundService.instance.swipe();
        onDismissed(dir);
      },
      onUpdate: (details) {
        // Haptic feedback at 50% swipe
        if (details.progress > 0.5 && details.progress < 0.55) {
          if (enableHaptic) HapticService.light();
        }
      },
      child: child,
    );
  }
}

/// Long-press with progressive haptic feedback
class MicroLongPress extends StatefulWidget {
  const MicroLongPress({
    super.key,
    required this.child,
    required this.onLongPress,
    this.duration = const Duration(milliseconds: 500),
    this.enableProgressiveHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final VoidCallback onLongPress;
  final Duration duration;
  final bool enableProgressiveHaptic;
  final bool enableSound;

  @override
  State<MicroLongPress> createState() => _MicroLongPressState();
}

class _MicroLongPressState extends State<MicroLongPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    if (widget.enableProgressiveHaptic) {
      _controller.addListener(() {
        // Progressive haptic at 25%, 50%, 75%, 100%
        final progress = _controller.value;
        if (progress > 0.24 && progress < 0.26) {
          HapticService.light();
        } else if (progress > 0.49 && progress < 0.51) {
          HapticService.light();
        } else if (progress > 0.74 && progress < 0.76) {
          HapticService.medium();
        } else if (progress > 0.99) {
          HapticService.heavy();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    if (_controller.value > 0.99) {
      if (widget.enableSound) SoundService.instance.button();
      widget.onLongPress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

/// Drag-and-drop with haptic feedback on snap
class MicroDrag extends StatelessWidget {
  const MicroDrag({
    super.key,
    required this.child,
    required this.data,
    this.enableHaptic = true,
    this.enableSound = true,
    this.feedbackWidget,
  });

  final Widget child;
  final Object data;
  final bool enableHaptic;
  final bool enableSound;
  final Widget? feedbackWidget;

  @override
  Widget build(BuildContext context) {
    return Draggable(
      data: data,
      feedback: feedbackWidget ?? child,
      childWhenDragging: Opacity(opacity: 0.5, child: child),
      onDragStarted: () {
        if (enableHaptic) HapticService.light();
        if (enableSound) SoundService.instance.tap();
      },
      onDragEnd: (details) {
        if (details.wasAccepted) {
          if (enableHaptic) HapticService.medium();
          if (enableSound) SoundService.instance.success();
        } else {
          if (enableHaptic) HapticService.light();
        }
      },
      child: child,
    );
  }
}

/// Drop target with visual feedback
class MicroDropTarget<T extends Object> extends StatefulWidget {
  const MicroDropTarget({
    super.key,
    required this.child,
    required this.onAccept,
    this.enableHaptic = true,
    this.enableSound = true,
    this.hoverBuilder,
  });

  final Widget child;
  final void Function(T) onAccept;
  final bool enableHaptic;
  final bool enableSound;
  final Widget Function(BuildContext, Widget)? hoverBuilder;

  @override
  State<MicroDropTarget<T>> createState() => _MicroDropTargetState<T>();
}

class _MicroDropTargetState<T extends Object>
    extends State<MicroDropTarget<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) {
        if (!_isHovering) {
          setState(() => _isHovering = true);
          if (widget.enableHaptic) HapticService.light();
        }
        return true;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        if (widget.enableHaptic) HapticService.medium();
        if (widget.enableSound) SoundService.instance.success();
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        Widget content = widget.child;
        if (_isHovering && widget.hoverBuilder != null) {
          content = widget.hoverBuilder!(context, content);
        } else if (_isHovering) {
          content = AnimatedScale(
            scale: 1.05,
            duration: const Duration(milliseconds: 200),
            child: content,
          );
        }
        return content;
      },
    );
  }
}

/// Toggle switch with smooth animation and haptic
class MicroToggle extends StatelessWidget {
  const MicroToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enableHaptic;
  final bool enableSound;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: (newValue) {
        if (enableHaptic) HapticService.light();
        if (enableSound) SoundService.instance.tap();
        onChanged(newValue);
      },
    );
  }
}

/// Slider with haptic feedback at intervals
class MicroSlider extends StatelessWidget {
  const MicroSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.enableHaptic = true,
    this.enableSound = false,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final bool enableHaptic;
  final bool enableSound;

  @override
  Widget build(BuildContext context) {
    double? lastHapticValue;

    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: (newValue) {
        // Haptic feedback at division intervals
        if (enableHaptic && divisions != null) {
          final step = (max - min) / divisions!;
          final currentStep = ((newValue - min) / step).round();
          final lastStep = lastHapticValue != null
              ? ((lastHapticValue! - min) / step).round()
              : -1;

          if (currentStep != lastStep) {
            HapticService.light();
            if (enableSound) SoundService.instance.tick();
          }
          lastHapticValue = newValue;
        }
        onChanged(newValue);
      },
      onChangeEnd: (_) {
        if (enableHaptic) HapticService.light();
      },
    );
  }
}

/// Ripple effect on any widget
class MicroRipple extends StatelessWidget {
  const MicroRipple({
    super.key,
    required this.child,
    required this.onTap,
    this.enableHaptic = true,
    this.enableSound = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enableHaptic;
  final bool enableSound;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (enableHaptic) HapticService.light();
          if (enableSound) SoundService.instance.tap();
          onTap();
        },
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

/// Bounce animation on tap
class MicroBounce extends StatefulWidget {
  const MicroBounce({
    super.key,
    required this.child,
    required this.onTap,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enableHaptic;
  final bool enableSound;

  @override
  State<MicroBounce> createState() => _MicroBounceState();
}

class _MicroBounceState extends State<MicroBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    if (widget.enableHaptic) HapticService.light();
    if (widget.enableSound) SoundService.instance.tap();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(scale: _animation, child: widget.child),
    );
  }
}

// Helper function for unawaited futures
void unawaited(Future<void> future) {
  // Intentionally not awaited
}
