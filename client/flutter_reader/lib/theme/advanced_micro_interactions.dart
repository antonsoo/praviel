import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'vibrant_animations.dart';

/// Advanced micro-interactions for 2025 UI standards
/// 85% of users expect micro-interactions, 67% higher retention with smooth animations

/// Haptic feedback patterns for different interaction types
class AdvancedHaptics {
  /// Light tap - for button presses
  static Future<void> light() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: 10, amplitude: 50);
      } else {
        await Vibration.vibrate(duration: 10);
      }
    }
  }

  /// Medium impact - for selections, toggles
  static Future<void> medium() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: 20, amplitude: 100);
      } else {
        await Vibration.vibrate(duration: 20);
      }
    }
  }

  /// Heavy impact - for confirmations, achievements
  static Future<void> heavy() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: 40, amplitude: 180);
      } else {
        await Vibration.vibrate(duration: 40);
      }
    }
  }

  /// Success pattern - for correct answers
  static Future<void> success() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: 15, amplitude: 80);
        await Future.delayed(const Duration(milliseconds: 50));
        await Vibration.vibrate(duration: 15, amplitude: 120);
      } else {
        await Vibration.vibrate(pattern: [0, 15, 50, 15]);
      }
    }
  }

  /// Error pattern - for incorrect answers
  static Future<void> error() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: 10, amplitude: 100);
        await Future.delayed(const Duration(milliseconds: 40));
        await Vibration.vibrate(duration: 10, amplitude: 100);
        await Future.delayed(const Duration(milliseconds: 40));
        await Vibration.vibrate(duration: 10, amplitude: 100);
      } else {
        await Vibration.vibrate(pattern: [0, 10, 40, 10, 40, 10]);
      }
    }
  }

  /// Warning pattern - for alerts
  static Future<void> warning() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: 30, amplitude: 150);
      } else {
        await Vibration.vibrate(duration: 30);
      }
    }
  }

  /// Notification pattern - for updates, messages
  static Future<void> notification() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: 10, amplitude: 60);
        await Future.delayed(const Duration(milliseconds: 60));
        await Vibration.vibrate(duration: 10, amplitude: 60);
      } else {
        await Vibration.vibrate(pattern: [0, 10, 60, 10]);
      }
    }
  }
}

/// Premium button with advanced micro-interactions
/// Combines scale, rotation, haptic feedback, and optional 3D tilt
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 4,
    this.enable3D = true,
    this.enableHaptic = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.borderRadius = 20,
    this.scaleDown = 0.96,
    this.rotateOnPress = true,
    this.hapticType = HapticType.medium,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool enable3D;
  final bool enableHaptic;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double scaleDown;
  final bool rotateOnPress;
  final HapticType hapticType;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

enum HapticType { light, medium, heavy, success, error }

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  double _tiltX = 0;
  double _tiltY = 0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.quick,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.snappy));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.rotateOnPress ? 0.005 : 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _triggerHaptic() async {
    if (!widget.enableHaptic) return;
    switch (widget.hapticType) {
      case HapticType.light:
        await AdvancedHaptics.light();
        break;
      case HapticType.medium:
        await AdvancedHaptics.medium();
        break;
      case HapticType.heavy:
        await AdvancedHaptics.heavy();
        break;
      case HapticType.success:
        await AdvancedHaptics.success();
        break;
      case HapticType.error:
        await AdvancedHaptics.error();
        break;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      _triggerHaptic();
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleHover(PointerHoverEvent event) {
    if (!widget.enable3D) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.globalToLocal(event.position);
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      final tiltX = ((position.dy - centerY) / centerY) * 8;
      final tiltY = ((position.dx - centerX) / centerX) * -8;
      setState(() {
        _tiltX = tiltX;
        _tiltY = tiltY;
      });
    }
  }

  void _handleExit(PointerExitEvent event) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onHover: _handleHover,
      onExit: _handleExit,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(_tiltX * math.pi / 180)
                ..rotateY(_tiltY * math.pi / 180)
                ..rotateZ(_rotationAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: AnimatedContainer(
            duration: VibrantDuration.normal,
            curve: VibrantCurve.smooth,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              color: widget.gradient == null
                  ? (widget.backgroundColor ??
                      (isDisabled
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primary))
                  : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: (widget.gradient != null
                                ? Colors.black
                                : widget.backgroundColor ??
                                    colorScheme.primary)
                            .withValues(alpha: _isPressed ? 0.2 : 0.3),
                        blurRadius: _isPressed ? 8 : widget.elevation * 4,
                        offset: Offset(0, _isPressed ? 2 : widget.elevation * 2),
                      ),
                    ],
            ),
            child: DefaultTextStyle(
              style: theme.textTheme.labelLarge!.copyWith(
                color: widget.foregroundColor ??
                    (isDisabled
                        ? colorScheme.onSurfaceVariant
                        : Colors.white),
                fontWeight: FontWeight.w700,
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: widget.foregroundColor ??
                      (isDisabled
                          ? colorScheme.onSurfaceVariant
                          : Colors.white),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Breathing animation - subtle continuous movement for idle states
class BreathingWidget extends StatefulWidget {
  const BreathingWidget({
    super.key,
    required this.child,
    this.minScale = 0.98,
    this.maxScale = 1.02,
    this.duration = const Duration(seconds: 3),
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Floating animation - gentle up/down movement
class FloatingWidget extends StatefulWidget {
  const FloatingWidget({
    super.key,
    required this.child,
    this.offset = 8.0,
    this.duration = const Duration(seconds: 2),
    this.delay = Duration.zero,
  });

  final Widget child;
  final double offset;
  final Duration duration;
  final Duration delay;

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.offset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Glow animation - pulsing glow effect for important elements
class GlowingWidget extends StatefulWidget {
  const GlowingWidget({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.minGlow = 4.0,
    this.maxGlow = 16.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color glowColor;
  final double minGlow;
  final double maxGlow;
  final Duration duration;

  @override
  State<GlowingWidget> createState() => _GlowingWidgetState();
}

class _GlowingWidgetState extends State<GlowingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minGlow,
      end: widget.maxGlow,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.5),
                blurRadius: _animation.value,
                spreadRadius: _animation.value / 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Ripple effect - expanding circular ripple on interaction
class RippleEffect extends StatefulWidget {
  const RippleEffect({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;
  late Animation<double> _fadeAnimation;
  Offset? _ripplePosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _ripplePosition = details.localPosition;
    });
    _controller.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: CustomPaint(
        painter: _RipplePainter(
          rippleAnimation: _rippleAnimation,
          fadeAnimation: _fadeAnimation,
          ripplePosition: _ripplePosition,
          color: widget.color,
        ),
        child: widget.child,
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.rippleAnimation,
    required this.fadeAnimation,
    required this.ripplePosition,
    required this.color,
  }) : super(repaint: rippleAnimation);

  final Animation<double> rippleAnimation;
  final Animation<double> fadeAnimation;
  final Offset? ripplePosition;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (ripplePosition == null) return;

    final paint = Paint()
      ..color = color.withValues(alpha: fadeAnimation.value)
      ..style = PaintingStyle.fill;

    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height);
    final radius = maxRadius * rippleAnimation.value;

    canvas.drawCircle(ripplePosition!, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.rippleAnimation != rippleAnimation ||
      oldDelegate.fadeAnimation != fadeAnimation ||
      oldDelegate.ripplePosition != ripplePosition;
}

/// Magnetic button - attracts to touch point before tap
class MagneticButton extends StatefulWidget {
  const MagneticButton({
    super.key,
    required this.child,
    required this.onTap,
    this.magneticStrength = 0.3,
  });

  final Widget child;
  final VoidCallback onTap;
  final double magneticStrength;

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.fast,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.globalToLocal(event.position);
      final center = Offset(size.width / 2, size.height / 2);
      final delta = position - center;
      setState(() {
        _offset = delta * widget.magneticStrength;
      });
    }
  }

  void _handlePointerExit(PointerExitEvent event) {
    setState(() {
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _handlePointerMove(event as PointerMoveEvent),
      onExit: _handlePointerExit,
      child: AnimatedContainer(
        duration: VibrantDuration.fast,
        curve: VibrantCurve.smooth,
        transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
