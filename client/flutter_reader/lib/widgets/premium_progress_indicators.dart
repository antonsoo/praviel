import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';

/// Premium circular progress indicator with gradient
class PremiumCircularProgress extends StatefulWidget {
  const PremiumCircularProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    this.gradient,
    this.backgroundColor,
    this.showPercentage = true,
    this.centerWidget,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool showPercentage;
  final Widget? centerWidget;

  @override
  State<PremiumCircularProgress> createState() =>
      _PremiumCircularProgressState();
}

class _PremiumCircularProgressState extends State<PremiumCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(PremiumCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
    final gradient = widget.gradient ?? VibrantTheme.heroGradient;
    final backgroundColor =
        widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final percentage = (_animation.value * 100).round();

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
                  color: backgroundColor,
                ),
              ),
              // Gradient progress circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GradientCircleProgressPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  gradient: gradient,
                ),
              ),
              // Center content
              widget.centerWidget ??
                  (widget.showPercentage
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percentage%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: widget.size * 0.2,
                              ),
                            ),
                            Text(
                              'Complete',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: widget.size * 0.08,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink()),
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
    required this.color,
  });

  final double progress;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _GradientCircleProgressPainter extends CustomPainter {
  _GradientCircleProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  final double progress;
  final double strokeWidth;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_GradientCircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Premium linear progress indicator with gradient
class PremiumLinearProgress extends StatefulWidget {
  const PremiumLinearProgress({
    super.key,
    required this.progress,
    this.height = 8,
    this.gradient,
    this.backgroundColor,
    this.borderRadius,
    this.showLabel = false,
    this.label,
  });

  final double progress;
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showLabel;
  final String? label;

  @override
  State<PremiumLinearProgress> createState() => _PremiumLinearProgressState();
}

class _PremiumLinearProgressState extends State<PremiumLinearProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(PremiumLinearProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
    final gradient = widget.gradient ?? VibrantTheme.heroGradient;
    final backgroundColor =
        widget.backgroundColor ?? theme.colorScheme.surfaceContainerHigh;
    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    '${(_animation.value * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xs),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _animation.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: borderRadius,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Segmented progress indicator - for multi-step processes
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.height = 6,
    this.spacing = 8,
    this.activeGradient,
    this.inactiveColor,
  });

  final int totalSteps;
  final int currentStep;
  final double height;
  final double spacing;
  final Gradient? activeGradient;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = activeGradient ?? VibrantTheme.heroGradient;
    final inactive =
        inactiveColor ?? theme.colorScheme.surfaceContainerHigh;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < totalSteps - 1 ? spacing : 0,
            ),
            height: height,
            decoration: BoxDecoration(
              gradient: isActive ? gradient : null,
              color: isActive ? null : inactive,
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

/// Animated wave progress - for loading states
class WaveProgress extends StatefulWidget {
  const WaveProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.gradient,
    this.waveColor,
  });

  final double progress;
  final double size;
  final Gradient? gradient;
  final Color? waveColor;

  @override
  State<WaveProgress> createState() => _WaveProgressState();
}

class _WaveProgressState extends State<WaveProgress>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(WaveProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waveColor =
        widget.waveColor ?? theme.colorScheme.primary.withValues(alpha: 0.3);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          AnimatedBuilder(
            animation:
                Listenable.merge([_waveController, _progressController]),
            builder: (context, child) {
              return ClipOval(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _WavePainter(
                    wavePhase: _waveController.value,
                    progress: _progressAnimation.value,
                    waveColor: waveColor,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                '${(_progressAnimation.value * 100).round()}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.wavePhase,
    required this.progress,
    required this.waveColor,
  });

  final double wavePhase;
  final double progress;
  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final waveHeight = size.height * (1 - progress);
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (var x = 0.0; x <= size.width; x++) {
      final y = waveHeight +
          math.sin((x / size.width * 4 * math.pi) + (wavePhase * 2 * math.pi)) *
              10;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.wavePhase != wavePhase || oldDelegate.progress != progress;
}
