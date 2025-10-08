import 'package:flutter/material.dart';
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
    return PageView(
      controller: _controller,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
        if (widget.enableHaptic) HapticService.light();
        if (widget.enableSound) SoundService.instance.swipe();
        widget.onPageChanged?.call(page);
      },
      children: widget.pages,
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
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: widget.child,
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
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      child: Transform.translate(
        offset: _isDragging ? _dragOffset : Offset.zero,
        child: Transform.rotate(
          angle: _isDragging ? _dragOffset.dx / 1000 : 0,
          child: widget.child,
        ),
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
          _scale = (_previousScale * details.scale)
              .clamp(widget.minScale, widget.maxScale);
        });

        // Haptic at 1.0 (normal size)
        if (_scale > 0.98 && _scale < 1.02 && _previousScale != 1.0) {
          if (widget.enableHaptic) HapticService.light();
        }
      },
      onScaleEnd: (details) {
        if (widget.enableHaptic) HapticService.light();
      },
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
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
        onDragUpdate(DragUpdateDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
        ));
      },
      onLongPressEnd: (details) {
        if (enableHaptic) HapticService.light();
        onDragEnd(DragEndDetails(
          velocity: Velocity.zero,
        ));
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
  // Note: Shake detection requires accelerometer package (sensors_plus)
  // This implementation uses a fallback mechanism
  // For full shake detection, add sensors_plus to pubspec.yaml and:
  // 1. Import: import 'package:sensors_plus/sensors_plus.dart';
  // 2. Listen to: accelerometerEvents.listen((AccelerometerEvent event) {...})
  // 3. Detect shake: if (sqrt(x^2 + y^2 + z^2) > threshold) onShake();

  int _shakeTapCount = 0;
  DateTime? _lastTapTime;

  void _handleRapidTapSequence() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      _shakeTapCount++;

      // Trigger shake callback after 3 rapid taps (simulates shake)
      if (_shakeTapCount >= 3) {
        if (widget.enableHaptic) HapticService.heavy();
        if (widget.enableSound) SoundService.instance.celebration();
        widget.onShake();
        _shakeTapCount = 0;
        _lastTapTime = null;
        return;
      }
    } else {
      _shakeTapCount = 1;
    }

    _lastTapTime = now;
  }

  @override
  Widget build(BuildContext context) {
    // Fallback: Use rapid tap detection as shake alternative
    return GestureDetector(
      onTap: _handleRapidTapSequence,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,
          // Visual hint for shake gesture (bottom-right corner)
          Positioned(
            bottom: 16,
            right: 16,
            child: Opacity(
              opacity: 0.3,
              child: Tooltip(
                message: 'Tap rapidly 3 times to simulate shake\n(Add sensors_plus package for real shake detection)',
                child: Icon(
                  Icons.vibration,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
