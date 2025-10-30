import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/vibrant_theme.dart';

/// Advanced progress indicators with smooth morphing animations
/// 2025 trend: Dynamic, personality-filled progress indicators

/// Morphing circular progress indicator
/// Smoothly transitions between different progress values
class MorphingCircularProgress extends StatefulWidget {
  const MorphingCircularProgress({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8.0,
    this.gradient,
    this.backgroundColor,
    this.showPercentage = true,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool showPercentage;
  final Duration animationDuration;

  @override
  State<MorphingCircularProgress> createState() =>
      _MorphingCircularProgressState();
}

class _MorphingCircularProgressState extends State<MorphingCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: _currentProgress,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(MorphingCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _currentProgress = _animation.value;
      _animation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveGradient = widget.gradient ?? VibrantTheme.premiumGradient;
    final effectiveBackgroundColor =
        widget.backgroundColor ?? colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircleProgressPainter(
                  progress: 1.0,
                  strokeWidth: widget.strokeWidth,
                  color: effectiveBackgroundColor,
                  gradient: null,
                ),
              ),
              // Progress arc with gradient
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircleProgressPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  color: null,
                  gradient: effectiveGradient,
                ),
              ),
              // Percentage text
              if (widget.showPercentage)
                Text(
                  '${(_animation.value * 100).toInt()}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  _CircleProgressPainter({
    required this.progress,
    required this.strokeWidth,
    this.color,
    this.gradient,
  });

  final double progress;
  final double strokeWidth;
  final Color? color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else if (color != null) {
      paint.color = color!;
    }

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        strokeWidth != oldDelegate.strokeWidth ||
        color != oldDelegate.color;
  }
}

/// Wave progress indicator - liquid fill effect
class WaveProgressIndicator extends StatefulWidget {
  const WaveProgressIndicator({
    super.key,
    required this.progress,
    this.width = 200,
    this.height = 100,
    this.color,
    this.waveHeight = 8.0,
    this.showPercentage = true,
  });

  final double progress;
  final double width;
  final double height;
  final Color? color;
  final double waveHeight;
  final bool showPercentage;

  @override
  State<WaveProgressIndicator> createState() => _WaveProgressIndicatorState();
}

class _WaveProgressIndicatorState extends State<WaveProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor =
        widget.color ?? VibrantTheme.premiumGradient.colors.first;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: effectiveColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _WavePainter(
                      progress: widget.progress,
                      wavePhase: _waveController.value * 2 * math.pi,
                      color: effectiveColor,
                      waveHeight: widget.waveHeight,
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.showPercentage)
            Text(
              '${(widget.progress * 100).toInt()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: widget.progress > 0.5
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    required this.waveHeight,
  });

  final double progress;
  final double wavePhase;
  final Color color;
  final double waveHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final fillHeight = size.height * (1 - progress);
    final path = Path();

    path.moveTo(0, fillHeight);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final y = fillHeight +
          math.sin((normalizedX * 2 * math.pi) + wavePhase) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Draw second wave slightly offset
    final path2 = Path();
    path2.moveTo(0, fillHeight);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final y = fillHeight +
          math.sin((normalizedX * 2 * math.pi) + wavePhase + math.pi / 2) *
              waveHeight *
              0.7;
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return progress != oldDelegate.progress ||
        wavePhase != oldDelegate.wavePhase;
  }
}

/// Segmented progress bar with smooth transitions
class SegmentedProgressBar extends StatefulWidget {
  const SegmentedProgressBar({
    super.key,
    required this.progress,
    this.segmentCount = 5,
    this.height = 8.0,
    this.activeColor,
    this.inactiveColor,
    this.gap = 4.0,
  });

  final double progress;
  final int segmentCount;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final double gap;

  @override
  State<SegmentedProgressBar> createState() => _SegmentedProgressBarState();
}

class _SegmentedProgressBarState extends State<SegmentedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<double>(
      begin: _currentProgress,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(SegmentedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _currentProgress = _animation.value;
      _animation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveActiveColor =
        widget.activeColor ?? VibrantTheme.premiumGradient.colors.first;
    final effectiveInactiveColor =
        widget.inactiveColor ?? colorScheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth =
                (constraints.maxWidth - (widget.gap * (widget.segmentCount - 1))) /
                    widget.segmentCount;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.segmentCount, (index) {
                final segmentProgress = (_animation.value * widget.segmentCount) - index;
                final isActive = segmentProgress > 0;
                final fillRatio = segmentProgress.clamp(0.0, 1.0);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: segmentWidth,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    color: effectiveInactiveColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: segmentWidth * fillRatio,
                      height: widget.height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            effectiveActiveColor,
                            effectiveActiveColor.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: effectiveActiveColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

/// Pulsing loader - for indeterminate progress
class PulsingLoader extends StatefulWidget {
  const PulsingLoader({
    super.key,
    this.size = 60,
    this.color,
    this.dotCount = 3,
  });

  final double size;
  final Color? color;
  final int dotCount;

  @override
  State<PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<PulsingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size / 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.dotCount, (index) {
              final delay = index / widget.dotCount;
              final value = (_controller.value + delay) % 1.0;
              final scale = 0.5 + (math.sin(value * 2 * math.pi) * 0.5);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: effectiveColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
