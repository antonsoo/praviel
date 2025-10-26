import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// Gesture-based navigation - 2025 trend moving away from button-heavy interfaces
/// Swipe gestures for more natural, fluid navigation

/// Swipe-to-go-back gesture detector
class SwipeToGoBack extends StatelessWidget {
  const SwipeToGoBack({
    super.key,
    required this.child,
    this.onSwipeBack,
    this.enabled = true,
    this.threshold = 0.3,
  });

  final Widget child;
  final VoidCallback? onSwipeBack;
  final bool enabled;
  final double threshold; // 0.0 to 1.0, fraction of screen width

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe from left edge to go back
        if (details.velocity.pixelsPerSecond.dx > 300) {
          HapticService.light();
          SoundService.instance.whoosh();
          if (onSwipeBack != null) {
            onSwipeBack!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: child,
    );
  }
}

/// Swipe between pages/tabs
class SwipeBetweenPages extends StatefulWidget {
  const SwipeBetweenPages({
    super.key,
    required this.pages,
    this.initialPage = 0,
    this.onPageChanged,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final List<Widget> pages;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final bool enableHaptic;
  final bool enableSound;

  @override
  State<SwipeBetweenPages> createState() => _SwipeBetweenPagesState();
}

class _SwipeBetweenPagesState extends State<SwipeBetweenPages> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView(
          controller: _controller,
          onPageChanged: (page) {
            setState(() => _currentPage = page);
            if (widget.enableHaptic) HapticService.light();
            if (widget.enableSound) SoundService.instance.swipe();
            widget.onPageChanged?.call(page);
          },
          children: widget.pages,
        ),
        if (widget.pages.length > 1)
          Positioned(
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: isActive ? 16 : 8,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pull-to-refresh with custom animation
class PullToRefreshGesture extends StatefulWidget {
  const PullToRefreshGesture({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enableHaptic;
  final bool enableSound;

  @override
  State<PullToRefreshGesture> createState() => _PullToRefreshGestureState();
}

class _PullToRefreshGestureState extends State<PullToRefreshGesture> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    if (widget.enableHaptic) await HapticService.medium();
    if (widget.enableSound) await SoundService.instance.whoosh();

    await widget.onRefresh();

    if (mounted) {
      setState(() => _isRefreshing = false);
      if (widget.enableHaptic) await HapticService.light();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        RefreshIndicator(onRefresh: _handleRefresh, child: widget.child),
        if (_isRefreshing)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Chip(
                      avatar: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Refreshing'),
                      backgroundColor: colorScheme.surfaceContainerHigh
                          .withValues(alpha: 0.9),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Swipe card (like Tinder) for lesson selection
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final bool enableHaptic;
  final bool enableSound;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  int _swipeDirection = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _isDragging = true;
    });

    // Haptic at threshold
    if (_dragOffset.dx.abs() > 100 && _dragOffset.dx.abs() < 105) {
      if (widget.enableHaptic) HapticService.light();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    const threshold = 100.0;

    if (_dragOffset.dx > threshold) {
      // Swiped right
      _animateSwipe(true);
    } else if (_dragOffset.dx < -threshold) {
      // Swiped left
      _animateSwipe(false);
    } else {
      // Return to center
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  void _animateSwipe(bool right) {
    _swipeDirection = right ? 1 : -1;
    _controller.forward().then((_) {
      if (widget.enableHaptic) HapticService.medium();
      if (widget.enableSound) SoundService.instance.swipe();

      if (right) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }

      // Reset
      _controller.reset();
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final screenWidth = MediaQuery.of(context).size.width;
          final animatedOffset = Offset(
            _controller.value * _swipeDirection * screenWidth,
            0,
          );
          final animatedAngle = _controller.value * 0.3 * _swipeDirection;
          final effectiveOffset = _isDragging ? _dragOffset : animatedOffset;
          final effectiveAngle = _isDragging
              ? _dragOffset.dx / 1000
              : animatedAngle;

          return Transform.translate(
            offset: effectiveOffset,
            child: Transform.rotate(angle: effectiveAngle, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Pinch-to-zoom gesture
class PinchToZoom extends StatefulWidget {
  const PinchToZoom({
    super.key,
    required this.child,
    this.minScale = 0.8,
    this.maxScale = 3.0,
    this.enableHaptic = true,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final bool enableHaptic;

  @override
  State<PinchToZoom> createState() => _PinchToZoomState();
}

class _PinchToZoomState extends State<PinchToZoom> {
  double _scale = 1.0;
  double _previousScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _previousScale = _scale;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_previousScale * details.scale).clamp(
            widget.minScale,
            widget.maxScale,
          );
        });

        // Haptic at 1.0 (normal size)
        if (_scale > 0.98 && _scale < 1.02 && _previousScale != 1.0) {
          if (widget.enableHaptic) HapticService.light();
        }
      },
      onScaleEnd: (details) {
        if (widget.enableHaptic) HapticService.light();
      },
      child: Transform.scale(scale: _scale, child: widget.child),
    );
  }
}

/// Double-tap-to-action gesture
class DoubleTapAction extends StatelessWidget {
  const DoubleTapAction({
    super.key,
    required this.child,
    required this.onDoubleTap,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final VoidCallback onDoubleTap;
  final bool enableHaptic;
  final bool enableSound;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        if (enableHaptic) HapticService.medium();
        if (enableSound) SoundService.instance.button();
        onDoubleTap();
      },
      child: child,
    );
  }
}

/// Long-press-and-drag gesture (for reordering)
class LongPressDrag extends StatelessWidget {
  const LongPressDrag({
    super.key,
    required this.child,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback onDragStart;
  final void Function(DragUpdateDetails) onDragUpdate;
  final void Function(DragEndDetails) onDragEnd;
  final bool enableHaptic;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        if (enableHaptic) HapticService.heavy();
        onDragStart();
      },
      onLongPressMoveUpdate: (details) {
        onDragUpdate(
          DragUpdateDetails(
            globalPosition: details.globalPosition,
            localPosition: details.localPosition,
          ),
        );
      },
      onLongPressEnd: (details) {
        if (enableHaptic) HapticService.light();
        onDragEnd(DragEndDetails(velocity: Velocity.zero));
      },
      child: child,
    );
  }
}

/// Edge-swipe detector (like iOS back gesture)
class EdgeSwipeDetector extends StatelessWidget {
  const EdgeSwipeDetector({
    super.key,
    required this.child,
    required this.onLeftEdgeSwipe,
    this.onRightEdgeSwipe,
    this.edgeWidth = 20.0,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final VoidCallback onLeftEdgeSwipe;
  final VoidCallback? onRightEdgeSwipe;
  final double edgeWidth;
  final bool enableHaptic;
  final bool enableSound;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: (details) {
            final isLeftEdge = details.globalPosition.dx < edgeWidth;
            final isRightEdge =
                details.globalPosition.dx > constraints.maxWidth - edgeWidth;

            if (isLeftEdge || isRightEdge) {
              if (enableHaptic) HapticService.light();
            }
          },
          onHorizontalDragEnd: (details) {
            final startX = details.globalPosition.dx;
            final velocity = details.velocity.pixelsPerSecond.dx;

            if (startX < edgeWidth && velocity > 300) {
              // Left edge swipe to right
              if (enableHaptic) HapticService.medium();
              if (enableSound) SoundService.instance.whoosh();
              onLeftEdgeSwipe();
            } else if (startX > constraints.maxWidth - edgeWidth &&
                velocity < -300 &&
                onRightEdgeSwipe != null) {
              // Right edge swipe to left
              if (enableHaptic) HapticService.medium();
              if (enableSound) SoundService.instance.whoosh();
              onRightEdgeSwipe!();
            }
          },
          child: child,
        );
      },
    );
  }
}

/// Shake-to-action gesture (fun easter egg)
class ShakeGesture extends StatefulWidget {
  const ShakeGesture({
    super.key,
    required this.child,
    required this.onShake,
    this.threshold = 2.5,
    this.enableHaptic = true,
    this.enableSound = true,
  });

  final Widget child;
  final VoidCallback onShake;
  final double threshold;
  final bool enableHaptic;
  final bool enableSound;

  @override
  State<ShakeGesture> createState() => _ShakeGestureState();
}

class _ShakeGestureState extends State<ShakeGesture> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _lastAcceleration = 0.0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Calculate the magnitude of acceleration (excluding gravity effects)
        // For shake detection, we look at the total acceleration change
        final acceleration = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        // Calculate the change in acceleration (jerk)
        final accelerationChange = (acceleration - _lastAcceleration).abs();
        _lastAcceleration = acceleration;

        // Detect shake: sudden acceleration change above threshold
        if (accelerationChange > widget.threshold) {
          final now = DateTime.now();

          // Debounce: Only trigger once per second
          if (_lastShakeTime == null ||
              now.difference(_lastShakeTime!) > const Duration(seconds: 1)) {
            _lastShakeTime = now;

            if (widget.enableHaptic) HapticService.heavy();
            if (widget.enableSound) SoundService.instance.celebration();
            widget.onShake();
          }
        }
      },
      onError: (error) {
        // Sensor not available, silently ignore
        debugPrint('Accelerometer error: $error');
      },
      cancelOnError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
