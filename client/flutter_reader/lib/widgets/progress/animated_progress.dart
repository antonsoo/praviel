import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// Animated progress indicators for 2025 UI standards
/// Circular, linear, and custom shapes with smooth animations

/// Animated circular progress with gradient
class AnimatedCircularProgress extends StatefulWidget {
  const AnimatedCircularProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    this.gradient,
    this.backgroundColor,
    this.showPercentage = true,
    this.child,
    this.duration = VibrantDuration.celebration,
  });

  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool showPercentage;
  final Widget? child;
  final Duration duration;

  @override
  State<AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _previousProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(
          CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _CircularProgressPainter(
              progress: _progressAnimation.value,
              strokeWidth: widget.strokeWidth,
              gradient: widget.gradient ?? VibrantTheme.successGradient,
              backgroundColor:
                  widget.backgroundColor ?? colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: widget.child ??
                  (widget.showPercentage
                      ? Text(
                          '${(_progressAnimation.value * 100).toInt()}%',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null),
            ),
          );
        },
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradientPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        gradientPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animated linear progress bar
class AnimatedLinearProgress extends StatefulWidget {
  const AnimatedLinearProgress({
    super.key,
    required this.progress,
    this.height = 8,
    this.gradient,
    this.backgroundColor,
    this.borderRadius = VibrantRadius.full,
    this.duration = VibrantDuration.moderate,
  });

  final double progress;
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double borderRadius;
  final Duration duration;

  @override
  State<AnimatedLinearProgress> createState() => _AnimatedLinearProgressState();
}

class _AnimatedLinearProgressState extends State<AnimatedLinearProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedLinearProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(
          CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.gradient ?? VibrantTheme.auroraGradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: (widget.gradient != null
                            ? Colors.blue
                            : colorScheme.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Segmented progress indicator
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.totalSegments,
    required this.completedSegments,
    this.segmentWidth = 40,
    this.segmentHeight = 8,
    this.spacing = 4,
    this.activeGradient,
    this.inactiveColor,
  });

  final int totalSegments;
  final int completedSegments;
  final double segmentWidth;
  final double segmentHeight;
  final double spacing;
  final Gradient? activeGradient;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSegments, (index) {
        final isCompleted = index < completedSegments;
        return Padding(
          padding: EdgeInsets.only(
            right: index < totalSegments - 1 ? spacing : 0,
          ),
          child: ScaleIn(
            delay: Duration(milliseconds: 50 * index),
            child: Container(
              width: segmentWidth,
              height: segmentHeight,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? (activeGradient ?? VibrantTheme.successGradient)
                    : null,
                color: isCompleted
                    ? null
                    : (inactiveColor ?? colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(VibrantRadius.full),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Pulse progress - for indeterminate loading
class PulseProgress extends StatefulWidget {
  const PulseProgress({
    super.key,
    this.size = 60,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<PulseProgress> createState() => _PulseProgressState();
}

class _PulseProgressState extends State<PulseProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (widget.color ?? colorScheme.primary)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.5,
                height: widget.size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color ?? colorScheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Step progress indicator
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.stepSize = 32,
    this.lineThickness = 2,
  });

  final int totalSteps;
  final int currentStep;
  final double stepSize;
  final double lineThickness;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isEven) {
          // Step circle
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          return ScaleIn(
            delay: Duration(milliseconds: 50 * stepIndex),
            child: Container(
              width: stepSize,
              height: stepSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCompleted || isCurrent
                    ? VibrantTheme.auroraGradient
                    : null,
                color: isCompleted || isCurrent
                    ? null
                    : colorScheme.surfaceContainerHighest,
                border: isCurrent
                    ? Border.all(
                        color: colorScheme.primary,
                        width: 3,
                      )
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: stepSize * 0.6,
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isCurrent
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          );
        } else {
          // Connecting line
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;

          return Expanded(
            child: Container(
              height: lineThickness,
              color: isCompleted
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
            ),
          );
        }
      }),
    );
  }
}
