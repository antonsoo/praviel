import 'package:flutter/material.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/advanced_micro_interactions.dart';

/// Swipeable card with left/right actions (like iOS Mail)
/// Modern 2025 pattern for list item actions
class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftAction,
    this.rightAction,
    this.leftActionColor = Colors.red,
    this.rightActionColor = Colors.green,
    this.leftActionIcon = Icons.delete,
    this.rightActionIcon = Icons.check,
    this.swipeThreshold = 0.4,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Widget? leftAction;
  final Widget? rightAction;
  final Color leftActionColor;
  final Color rightActionColor;
  final IconData leftActionIcon;
  final IconData rightActionIcon;
  final double swipeThreshold;
  final bool enableHaptic;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  bool _dragUnderway = false;
  bool _hapticTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.normal,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    _hapticTriggered = false;
    if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragUnderway) return;

    final delta = details.primaryDelta ?? 0;
    final screenWidth = context.size?.width ?? 1;
    setState(() {
      _dragExtent += delta / screenWidth;
      _dragExtent = _dragExtent.clamp(-1.0, 1.0);
    });

    // Trigger haptic when passing threshold
    if (widget.enableHaptic && !_hapticTriggered) {
      if (_dragExtent.abs() > widget.swipeThreshold) {
        AdvancedHaptics.light();
        _hapticTriggered = true;
      }
    }

    // Reset haptic flag if user drags back
    if (_hapticTriggered && _dragExtent.abs() < widget.swipeThreshold) {
      _hapticTriggered = false;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragUnderway) return;
    _dragUnderway = false;

    final isSwipeLeft = _dragExtent < 0;
    final passedThreshold = _dragExtent.abs() > widget.swipeThreshold;

    if (passedThreshold) {
      // Complete swipe action
      if (isSwipeLeft && widget.onSwipeLeft != null) {
        _animateSwipe(isLeft: true);
        widget.onSwipeLeft!();
      } else if (!isSwipeLeft && widget.onSwipeRight != null) {
        _animateSwipe(isLeft: false);
        widget.onSwipeRight!();
      } else {
        _resetPosition();
      }
    } else {
      _resetPosition();
    }
  }

  void _animateSwipe({required bool isLeft}) async {
    await _controller.animateTo(
      isLeft ? -1.5 : 1.5,
      duration: VibrantDuration.moderate,
      curve: VibrantCurve.smooth,
    );
    if (mounted) {
      setState(() {
        _dragExtent = 0;
      });
      _controller.reset();
    }
  }

  void _resetPosition() {
    _controller.animateTo(0.0);
    setState(() {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = Offset(_dragExtent * screenWidth, 0);

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Background actions
          Positioned.fill(
            child: Row(
              children: [
                // Right swipe action (left side)
                if (widget.onSwipeRight != null)
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      color: widget.rightActionColor,
                      child: widget.rightAction ??
                          Icon(
                            widget.rightActionIcon,
                            color: Colors.white,
                            size: 28,
                          ),
                    ),
                  ),
                // Left swipe action (right side)
                if (widget.onSwipeLeft != null)
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: widget.leftActionColor,
                      child: widget.leftAction ??
                          Icon(
                            widget.leftActionIcon,
                            color: Colors.white,
                            size: 28,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          // Foreground card
          Transform.translate(
            offset: offset,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Dismissible card with animation
class DismissibleCard extends StatelessWidget {
  const DismissibleCard({
    super.key,
    required this.child,
    required this.onDismissed,
    this.direction = DismissDirection.horizontal,
    this.background,
    this.secondaryBackground,
    this.dismissThreshold = 0.4,
  });

  final Widget child;
  final void Function(DismissDirection) onDismissed;
  final DismissDirection direction;
  final Widget? background;
  final Widget? secondaryBackground;
  final double dismissThreshold;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: direction,
      dismissThresholds: {
        DismissDirection.startToEnd: dismissThreshold,
        DismissDirection.endToStart: dismissThreshold,
      },
      background: background ??
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.green,
            child: const Icon(Icons.check, color: Colors.white, size: 28),
          ),
      secondaryBackground: secondaryBackground ??
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
      onDismissed: (direction) {
        AdvancedHaptics.medium();
        onDismissed(direction);
      },
      child: child,
    );
  }
}

/// Pull to refresh with custom indicator
class PremiumRefreshIndicator extends StatelessWidget {
  const PremiumRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await AdvancedHaptics.light();
        await onRefresh();
        await AdvancedHaptics.success();
      },
      color: color ?? colorScheme.primary,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      displacement: displacement,
      strokeWidth: 3.0,
      child: child,
    );
  }
}

/// Draggable item with feedback
class DraggableItem<T extends Object> extends StatefulWidget {
  const DraggableItem({
    super.key,
    required this.data,
    required this.child,
    required this.feedback,
    this.childWhenDragging,
    this.onDragStarted,
    this.onDragCompleted,
    this.onDraggableCanceled,
    this.enableHaptic = true,
  });

  final T data;
  final Widget child;
  final Widget feedback;
  final Widget? childWhenDragging;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragCompleted;
  final void Function(Velocity, Offset)? onDraggableCanceled;
  final bool enableHaptic;

  @override
  State<DraggableItem<T>> createState() => _DraggableItemState<T>();
}

class _DraggableItemState<T extends Object> extends State<DraggableItem<T>> {
  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<T>(
      data: widget.data,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.9,
          child: widget.feedback,
        ),
      ),
      childWhenDragging: widget.childWhenDragging ??
          Opacity(
            opacity: 0.3,
            child: widget.child,
          ),
      onDragStarted: () {
        if (widget.enableHaptic) {
          AdvancedHaptics.medium();
        }
        widget.onDragStarted?.call();
      },
      onDragCompleted: () {
        if (widget.enableHaptic) {
          AdvancedHaptics.success();
        }
        widget.onDragCompleted?.call();
      },
      onDraggableCanceled: (velocity, offset) {
        if (widget.enableHaptic) {
          AdvancedHaptics.light();
        }
        widget.onDraggableCanceled?.call(velocity, offset);
      },
      child: widget.child,
    );
  }
}

/// Drag target with visual feedback
class DragTargetZone<T extends Object> extends StatefulWidget {
  const DragTargetZone({
    super.key,
    required this.child,
    required this.onAccept,
    this.onWillAccept,
    this.onLeave,
    this.highlightColor,
    this.enableHaptic = true,
  });

  final Widget child;
  final void Function(T) onAccept;
  final bool Function(T?)? onWillAccept;
  final void Function(T?)? onLeave;
  final Color? highlightColor;
  final bool enableHaptic;

  @override
  State<DragTargetZone<T>> createState() => _DragTargetZoneState<T>();
}

class _DragTargetZoneState<T extends Object> extends State<DragTargetZone<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<T>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        if (widget.enableHaptic) {
          AdvancedHaptics.light();
        }
        return widget.onWillAccept?.call(details.data) ?? true;
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        if (widget.enableHaptic) {
          AdvancedHaptics.success();
        }
        widget.onAccept(details.data);
      },
      onLeave: (data) {
        setState(() => _isHovering = false);
        widget.onLeave?.call(data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: VibrantDuration.fast,
          curve: VibrantCurve.smooth,
          decoration: BoxDecoration(
            border: _isHovering
                ? Border.all(
                    color: widget.highlightColor ?? colorScheme.primary,
                    width: 2,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.child,
        );
      },
    );
  }
}
