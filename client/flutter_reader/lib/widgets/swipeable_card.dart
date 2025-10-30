import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../services/haptic_service.dart';
import '../theme/animations.dart';

/// A card that can be swiped left (wrong) or right (correct)
/// Provides visual feedback and haptic response
class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    required this.child,
    required this.onSwipeComplete,
    super.key,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.enableSwipe = true,
  });

  final Widget child;
  final VoidCallback onSwipeComplete;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final bool enableSwipe;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;
  bool _hasTriggeredHaptic = false;

  static const double _swipeThreshold = 100.0;
  static const double _rotationFactor = 0.0015;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.enableSwipe) return;
    setState(() {
      _isDragging = true;
      _hasTriggeredHaptic = false;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipe) return;

    setState(() {
      _dragPosition += details.delta;
    });

    // Trigger haptic feedback when crossing threshold
    final distance = _dragPosition.dx.abs();
    if (distance > _swipeThreshold && !_hasTriggeredHaptic) {
      HapticService.selection();
      _hasTriggeredHaptic = true;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.enableSwipe) return;

    final distance = _dragPosition.dx;
    final wasOverThreshold = distance.abs() > _swipeThreshold;

    if (wasOverThreshold) {
      // Complete the swipe
      final direction = distance > 0 ? 1.0 : -1.0;
      _animateSwipeOut(direction);

      if (distance > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
    } else {
      // Return to center
      _animateReturn();
    }

    setState(() {
      _isDragging = false;
    });
  }

  Future<void> _animateSwipeOut(double direction) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = Offset(
      direction * screenWidth * 1.5,
      _dragPosition.dy,
    );

    await _animateToPosition(targetOffset);
    widget.onSwipeComplete();
  }

  Future<void> _animateReturn() async {
    await _animateToPosition(Offset.zero);
  }

  Future<void> _animateToPosition(Offset target) async {
    final begin = _dragPosition;
    final animation = Tween<Offset>(begin: begin, end: target).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smoothEnter),
    );

    animation.addListener(() {
      setState(() {
        _dragPosition = animation.value;
      });
    });

    await _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _dragPosition.dx * _rotationFactor;
    final distance = _dragPosition.dx.abs();
    final opacity = math.max(0.0, math.min(1.0, distance / _swipeThreshold));

    final theme = Theme.of(context);
    final isRight = _dragPosition.dx > 0;

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          // Card
          Transform.translate(
            offset: _dragPosition,
            child: Transform.rotate(angle: rotation, child: widget.child),
          ),

          // Swipe direction indicator (overlay)
          if (_isDragging && distance > 30)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity * 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: isRight
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        end: isRight
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        colors: [
                          (isRight
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.error)
                              .withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        isRight ? Icons.check_circle : Icons.cancel,
                        size: 80,
                        color: isRight
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Button to programmatically trigger swipe animation
class SwipeButton extends StatelessWidget {
  const SwipeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BounceAnimation(
      onTap: () {
        HapticService.medium();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
