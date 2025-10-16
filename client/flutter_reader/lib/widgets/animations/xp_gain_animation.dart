import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Floating XP gain animation that appears when user earns XP
/// Animates upward with fade out effect
class XpGainAnimation extends StatefulWidget {
  const XpGainAnimation({
    required this.xpAmount,
    required this.position,
    this.onComplete,
    this.showMultiplier = false,
    this.multiplier = 1.0,
    super.key,
  });

  final int xpAmount;
  final Offset position;
  final VoidCallback? onComplete;
  final bool showMultiplier;
  final double multiplier;

  @override
  State<XpGainAnimation> createState() => _XpGainAnimationState();
}

class _XpGainAnimationState extends State<XpGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Slide upward
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -100.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Fade out near the end
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Scale up then down slightly
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
          left: widget.position.dx,
          top: widget.position.dy + _slideAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.xpAmount} XP',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (widget.showMultiplier && widget.multiplier > 1.0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${widget.multiplier.toStringAsFixed(1)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

/// Overlay that shows XP gain animations on top of content
class XpGainOverlay extends StatefulWidget {
  const XpGainOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<XpGainOverlay> createState() => XpGainOverlayState();
}

class XpGainOverlayState extends State<XpGainOverlay> {
  final List<Widget> _activeAnimations = [];
  int _animationKey = 0;

  /// Show XP gain animation at the specified position
  void showXpGain({
    required int xpAmount,
    Offset? position,
    bool showMultiplier = false,
    double multiplier = 1.0,
  }) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final defaultPosition = Offset(
      size.width / 2 - 50, // Center horizontally (approximate)
      size.height / 2 - 100, // Slightly above center
    );

    final animPosition = position ?? defaultPosition;
    final key = _animationKey++;

    setState(() {
      _activeAnimations.add(
        XpGainAnimation(
          key: ValueKey(key),
          xpAmount: xpAmount,
          position: animPosition,
          showMultiplier: showMultiplier,
          multiplier: multiplier,
          onComplete: () {
            setState(() {
              _activeAnimations.removeWhere(
                (w) => (w.key as ValueKey).value == key,
              );
            });
          },
        ),
      );
    });
  }

  /// Show multiple XP animations with staggered timing
  void showMultipleXpGains({
    required List<int> xpAmounts,
    Offset? startPosition,
  }) {
    for (int i = 0; i < xpAmounts.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;

          final size = renderBox.size;
          final baseX = startPosition?.dx ?? (size.width / 2 - 50);
          final baseY = startPosition?.dy ?? (size.height / 2 - 100);

          // Add random offset for visual variety
          final random = math.Random();
          final offsetX = baseX + (random.nextDouble() - 0.5) * 100;
          final offsetY = baseY + (random.nextDouble() - 0.5) * 50;

          showXpGain(
            xpAmount: xpAmounts[i],
            position: Offset(offsetX, offsetY),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [widget.child, ..._activeAnimations]);
  }
}
