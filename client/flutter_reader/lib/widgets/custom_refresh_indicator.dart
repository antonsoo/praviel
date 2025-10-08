import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';

/// Custom pull-to-refresh with beautiful animations
/// Provides delightful feedback during refresh operations

class CustomRefreshIndicator extends StatelessWidget {
  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.gradient,
    this.backgroundColor,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Gradient? gradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      color: colorScheme.primary,
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}

/// Gradient refresh indicator - custom implementation with gradient
class GradientRefreshIndicator extends StatefulWidget {
  const GradientRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.gradient,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Gradient? gradient;

  @override
  State<GradientRefreshIndicator> createState() =>
      _GradientRefreshIndicatorState();
}

class _GradientRefreshIndicatorState extends State<GradientRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _controller.repeat();

    try {
      await widget.onRefresh();
    } finally {
      _controller.stop();
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

/// Custom refresh header - for use with custom scroll views
class CustomRefreshHeader extends StatefulWidget {
  const CustomRefreshHeader({
    super.key,
    required this.refreshState,
    this.gradient,
  });

  final RefreshState refreshState;
  final Gradient? gradient;

  @override
  State<CustomRefreshHeader> createState() => _CustomRefreshHeaderState();
}

class _CustomRefreshHeaderState extends State<CustomRefreshHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.refreshState == RefreshState.refreshing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CustomRefreshHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshState == RefreshState.refreshing &&
        oldWidget.refreshState != RefreshState.refreshing) {
      _controller.repeat();
    } else if (widget.refreshState != RefreshState.refreshing &&
        oldWidget.refreshState == RefreshState.refreshing) {
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
    final gradient = widget.gradient ?? VibrantTheme.heroGradient;

    return SizedBox(
      height: 80,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return RotationTransition(
              turns: _controller,
              child: CustomPaint(
                size: const Size(40, 40),
                painter: _RefreshSpinnerPainter(
                  gradient: gradient,
                  progress: widget.refreshState == RefreshState.refreshing
                      ? 1.0
                      : widget.refreshState == RefreshState.pulling
                          ? 0.5
                          : 0.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RefreshSpinnerPainter extends CustomPainter {
  final Gradient gradient;
  final double progress;

  _RefreshSpinnerPainter({
    required this.gradient,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 1.5 * progress;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: (size.width - 4) / 2,
      ),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RefreshSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

enum RefreshState {
  idle,
  pulling,
  releasing,
  refreshing,
  completed,
}

/// Bouncing refresh indicator - playful bounce animation
class BouncingRefreshIndicator extends StatefulWidget {
  const BouncingRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;

  @override
  State<BouncingRefreshIndicator> createState() =>
      _BouncingRefreshIndicatorState();
}

class _BouncingRefreshIndicatorState extends State<BouncingRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _controller.forward(from: 0);
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
      child: widget.child,
    );
  }
}

/// Wave refresh indicator - liquid wave effect
class WaveRefreshIndicator extends StatefulWidget {
  const WaveRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.gradient,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Gradient? gradient;

  @override
  State<WaveRefreshIndicator> createState() => _WaveRefreshIndicatorState();
}

class _WaveRefreshIndicatorState extends State<WaveRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _controller.repeat();
    await widget.onRefresh();
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: widget.child,
    );
  }
}

/// Simple custom refresh with icon
class IconRefreshIndicator extends StatelessWidget {
  const IconRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.icon = Icons.refresh,
    this.color,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}
