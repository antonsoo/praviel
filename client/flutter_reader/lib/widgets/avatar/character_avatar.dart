import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Simple but expressive character avatar with emotions
/// Uses geometric shapes and gradients (no image assets needed)
enum AvatarEmotion {
  happy,
  excited,
  thinking,
  celebrating,
  sad,
  neutral,
}

class CharacterAvatar extends StatefulWidget {
  const CharacterAvatar({
    super.key,
    this.emotion = AvatarEmotion.happy,
    this.size = 100,
    this.primaryColor = const Color(0xFF7C3AED),
    this.animate = true,
  });

  final AvatarEmotion emotion;
  final double size;
  final Color primaryColor;
  final bool animate;

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CharacterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AvatarPainter(
              emotion: widget.emotion,
              primaryColor: widget.primaryColor,
              animation: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required this.emotion,
    required this.primaryColor,
    required this.animation,
  });

  final AvatarEmotion emotion;
  final Color primaryColor;
  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw head (circle with gradient)
    _drawHead(canvas, center, radius);

    // Draw eyes
    _drawEyes(canvas, center, radius);

    // Draw mouth based on emotion
    _drawMouth(canvas, center, radius);

    // Draw accessories based on emotion
    _drawAccessories(canvas, center, radius);
  }

  void _drawHead(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.9),
          primaryColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);

    // Add shine
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.25,
      shinePaint,
    );
  }

  void _drawEyes(Canvas canvas, Offset center, double radius) {
    final eyeSize = radius * 0.15;
    final eyeSpacing = radius * 0.35;
    final eyeY = center.dy - radius * 0.1;

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pupilPaint = Paint()
      ..color = const Color(0xFF2D3748)
      ..style = PaintingStyle.fill;

    // Left eye
    final leftEyeCenter = Offset(center.dx - eyeSpacing, eyeY);
    canvas.drawCircle(leftEyeCenter, eyeSize, eyePaint);

    // Right eye
    final rightEyeCenter = Offset(center.dx + eyeSpacing, eyeY);
    canvas.drawCircle(rightEyeCenter, eyeSize, eyePaint);

    // Pupils (adjust based on emotion)
    final pupilSize = eyeSize * (emotion == AvatarEmotion.excited ? 0.7 : 0.5);
    final pupilOffset = emotion == AvatarEmotion.thinking
        ? eyeSize * 0.3 * math.sin(animation * 2 * math.pi)
        : 0.0;

    canvas.drawCircle(
      Offset(leftEyeCenter.dx + pupilOffset, leftEyeCenter.dy),
      pupilSize,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(rightEyeCenter.dx + pupilOffset, rightEyeCenter.dy),
      pupilSize,
      pupilPaint,
    );

    // Eyelids for sad
    if (emotion == AvatarEmotion.sad) {
      final eyelidPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: leftEyeCenter,
          width: eyeSize * 2.5,
          height: eyeSize,
        ),
        eyelidPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: rightEyeCenter,
          width: eyeSize * 2.5,
          height: eyeSize,
        ),
        eyelidPaint,
      );
    }
  }

  void _drawMouth(Canvas canvas, Offset center, double radius) {
    final mouthY = center.dy + radius * 0.25;
    final mouthWidth = radius * 0.6;

    final mouthPaint = Paint()
      ..color = const Color(0xFF2D3748)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (emotion) {
      case AvatarEmotion.happy:
      case AvatarEmotion.neutral:
        // Smile
        path.moveTo(center.dx - mouthWidth / 2, mouthY);
        path.quadraticBezierTo(
          center.dx,
          mouthY + radius * 0.2,
          center.dx + mouthWidth / 2,
          mouthY,
        );
        break;

      case AvatarEmotion.excited:
      case AvatarEmotion.celebrating:
        // Big smile
        path.moveTo(center.dx - mouthWidth / 2, mouthY);
        path.quadraticBezierTo(
          center.dx,
          mouthY + radius * 0.3,
          center.dx + mouthWidth / 2,
          mouthY,
        );

        // Open mouth (fill)
        final fillPaint = Paint()
          ..color = const Color(0xFF2D3748)
          ..style = PaintingStyle.fill;

        final mouthPath = Path();
        mouthPath.moveTo(center.dx - mouthWidth / 2, mouthY);
        mouthPath.quadraticBezierTo(
          center.dx,
          mouthY + radius * 0.3,
          center.dx + mouthWidth / 2,
          mouthY,
        );
        mouthPath.quadraticBezierTo(
          center.dx,
          mouthY + radius * 0.15,
          center.dx - mouthWidth / 2,
          mouthY,
        );
        canvas.drawPath(mouthPath, fillPaint);
        return; // Skip stroke

      case AvatarEmotion.thinking:
        // Small curve
        path.moveTo(center.dx - mouthWidth / 3, mouthY);
        path.quadraticBezierTo(
          center.dx,
          mouthY + radius * 0.05,
          center.dx + mouthWidth / 3,
          mouthY,
        );
        break;

      case AvatarEmotion.sad:
        // Frown
        path.moveTo(center.dx - mouthWidth / 2, mouthY);
        path.quadraticBezierTo(
          center.dx,
          mouthY - radius * 0.15,
          center.dx + mouthWidth / 2,
          mouthY,
        );
        break;
    }

    canvas.drawPath(path, mouthPaint);
  }

  void _drawAccessories(Canvas canvas, Offset center, double radius) {
    switch (emotion) {
      case AvatarEmotion.celebrating:
        // Party hat
        final hatPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFF59E0B),
              const Color(0xFFFBBF24),
            ],
          ).createShader(
            Rect.fromLTWH(
              center.dx - radius * 0.5,
              center.dy - radius * 1.2,
              radius,
              radius * 0.8,
            ),
          );

        final hatPath = Path();
        hatPath.moveTo(center.dx - radius * 0.5, center.dy - radius * 0.7);
        hatPath.lineTo(center.dx, center.dy - radius * 1.3);
        hatPath.lineTo(center.dx + radius * 0.5, center.dy - radius * 0.7);
        hatPath.close();
        canvas.drawPath(hatPath, hatPaint);

        // Pom-pom
        final pomPaint = Paint()
          ..color = const Color(0xFFFF6B35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(center.dx, center.dy - radius * 1.3),
          radius * 0.15,
          pomPaint,
        );
        break;

      case AvatarEmotion.thinking:
        // Thought bubble
        final bubblePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

        final bubbleX = center.dx + radius * 0.8;
        final bubbleY = center.dy - radius * 0.6;

        // Dots
        canvas.drawCircle(
          Offset(center.dx + radius * 0.4, center.dy - radius * 0.2),
          radius * 0.08,
          bubblePaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.6, center.dy - radius * 0.4),
          radius * 0.12,
          bubblePaint,
        );

        // Main bubble
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          radius * 0.35,
          bubblePaint,
        );

        // Question mark in bubble
        final textPainter = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              color: primaryColor,
              fontSize: radius * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            bubbleX - textPainter.width / 2,
            bubbleY - textPainter.height / 2,
          ),
        );
        break;

      case AvatarEmotion.excited:
        // Sparkles around head
        final sparklePaint = Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.fill;

        final sparklePositions = [
          Offset(center.dx - radius * 0.9, center.dy - radius * 0.5),
          Offset(center.dx + radius * 0.9, center.dy - radius * 0.5),
          Offset(center.dx - radius * 0.7, center.dy + radius * 0.7),
          Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
        ];

        for (final pos in sparklePositions) {
          _drawStar(canvas, pos, radius * 0.15, sparklePaint);
        }
        break;

      default:
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final x = center.dx + math.cos(angle) * size;
      final y = center.dy + math.sin(angle) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) {
    return oldDelegate.emotion != emotion ||
        oldDelegate.animation != animation;
  }
}

/// Compact avatar indicator for app bar
class CompactAvatar extends StatelessWidget {
  const CompactAvatar({
    super.key,
    this.emotion = AvatarEmotion.happy,
    this.size = 32,
  });

  final AvatarEmotion emotion;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: CharacterAvatar(
        emotion: emotion,
        size: size - 4,
        animate: false,
      ),
    );
  }
}
