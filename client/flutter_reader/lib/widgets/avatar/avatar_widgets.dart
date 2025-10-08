import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../models/avatar.dart';

/// Avatar display widget
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    required this.avatar,
    this.size = 100,
    this.showBackground = true,
    super.key,
  });

  final Avatar avatar;
  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final Widget avatarContent = CustomPaint(
      size: Size(size, size),
      painter: _AvatarPainter(avatar),
    );

    if (!showBackground || avatar.background == null) {
      return avatarContent;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatar.background?.color,
        gradient: avatar.background?.gradient,
        shape: BoxShape.circle,
      ),
      child: avatarContent,
    );
  }
}

/// Avatar painter (simplified geometric style)
class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.avatar);

  final Avatar avatar;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final headRadius = size.width * 0.35;

    // Background circle
    final bgPaint = Paint()
      ..color = avatar.skinTone.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, headRadius, bgPaint);

    // Hair
    _drawHair(canvas, size, center, headRadius);

    // Eyes
    _drawEyes(canvas, size, center);

    // Outfit (bottom part)
    _drawOutfit(canvas, size, center, headRadius);

    // Accessory
    if (avatar.accessory != null) {
      _drawAccessory(canvas, size, center, headRadius);
    }
  }

  void _drawHair(Canvas canvas, Size size, Offset center, double headRadius) {
    final hairPaint = Paint()
      ..color = avatar.hairColor.color
      ..style = PaintingStyle.fill;

    switch (avatar.hairStyle) {
      case HairStyle.short:
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: headRadius),
          -3.14,
          3.14,
          false,
          hairPaint,
        );
        break;
      case HairStyle.long:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(0, -headRadius * 0.3),
              width: headRadius * 2.2,
              height: headRadius * 1.5,
            ),
            Radius.circular(headRadius * 0.5),
          ),
          hairPaint,
        );
        break;
      case HairStyle.curly:
        for (int i = -2; i <= 2; i++) {
          canvas.drawCircle(
            center.translate(i * headRadius * 0.4, -headRadius * 0.8),
            headRadius * 0.25,
            hairPaint,
          );
        }
        break;
      case HairStyle.bun:
        canvas.drawCircle(
          center.translate(0, -headRadius * 0.9),
          headRadius * 0.3,
          hairPaint,
        );
        break;
      case HairStyle.ponytail:
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(headRadius * 0.6, 0),
            width: headRadius * 0.6,
            height: headRadius * 0.8,
          ),
          hairPaint,
        );
        break;
      case HairStyle.bald:
        // No hair
        break;
    }
  }

  void _drawEyes(Canvas canvas, Size size, Offset center) {
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final eyeOffset = size.width * 0.1;
    final eyeY = center.dy - size.height * 0.05;

    switch (avatar.eyes) {
      case Eyes.normal:
        canvas.drawCircle(
          Offset(center.dx - eyeOffset, eyeY),
          size.width * 0.04,
          eyePaint,
        );
        canvas.drawCircle(
          Offset(center.dx + eyeOffset, eyeY),
          size.width * 0.04,
          eyePaint,
        );
        break;
      case Eyes.happy:
        final path = Path()
          ..moveTo(center.dx - eyeOffset - size.width * 0.05, eyeY)
          ..quadraticBezierTo(
            center.dx - eyeOffset,
            eyeY + size.width * 0.05,
            center.dx - eyeOffset + size.width * 0.05,
            eyeY,
          );
        canvas.drawPath(path, eyePaint..strokeWidth = 2..style = PaintingStyle.stroke);

        final path2 = Path()
          ..moveTo(center.dx + eyeOffset - size.width * 0.05, eyeY)
          ..quadraticBezierTo(
            center.dx + eyeOffset,
            eyeY + size.width * 0.05,
            center.dx + eyeOffset + size.width * 0.05,
            eyeY,
          );
        canvas.drawPath(path2, eyePaint);
        break;
      case Eyes.surprised:
        canvas.drawCircle(
          Offset(center.dx - eyeOffset, eyeY),
          size.width * 0.06,
          eyePaint..style = PaintingStyle.stroke..strokeWidth = 2,
        );
        canvas.drawCircle(
          Offset(center.dx + eyeOffset, eyeY),
          size.width * 0.06,
          eyePaint,
        );
        break;
      case Eyes.cool:
        final linePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx - eyeOffset - size.width * 0.05, eyeY),
          Offset(center.dx - eyeOffset + size.width * 0.05, eyeY),
          linePaint,
        );
        canvas.drawLine(
          Offset(center.dx + eyeOffset - size.width * 0.05, eyeY),
          Offset(center.dx + eyeOffset + size.width * 0.05, eyeY),
          linePaint,
        );
        break;
    }
  }

  void _drawOutfit(Canvas canvas, Size size, Offset center, double headRadius) {
    final outfitPaint = Paint()
      ..color = avatar.outfit.color
      ..style = PaintingStyle.fill;

    final neckY = center.dy + headRadius * 0.9;
    final shoulderWidth = size.width * 0.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, neckY + size.height * 0.15),
          width: shoulderWidth,
          height: size.height * 0.3,
        ),
        Radius.circular(size.width * 0.1),
      ),
      outfitPaint,
    );
  }

  void _drawAccessory(Canvas canvas, Size size, Offset center, double headRadius) {
    final accessoryPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (avatar.accessory!) {
      case Accessory.glasses:
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(-size.width * 0.1, -size.height * 0.05),
            width: size.width * 0.15,
            height: size.height * 0.1,
          ),
          accessoryPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(size.width * 0.1, -size.height * 0.05),
            width: size.width * 0.15,
            height: size.height * 0.1,
          ),
          accessoryPaint,
        );
        break;
      case Accessory.sunglasses:
        accessoryPaint.style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(0, -size.height * 0.05),
              width: size.width * 0.5,
              height: size.height * 0.12,
            ),
            Radius.circular(size.width * 0.05),
          ),
          accessoryPaint,
        );
        break;
      case Accessory.hat:
        accessoryPaint.style = PaintingStyle.fill;
        accessoryPaint.color = Colors.red;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(0, -headRadius * 1.2),
              width: size.width * 0.6,
              height: size.height * 0.2,
            ),
            Radius.circular(size.width * 0.1),
          ),
          accessoryPaint,
        );
        break;
      case Accessory.crown:
        accessoryPaint.style = PaintingStyle.fill;
        accessoryPaint.color = const Color(0xFFFFD700);
        final path = Path()
          ..moveTo(center.dx - size.width * 0.25, center.dy - headRadius * 1.0)
          ..lineTo(center.dx - size.width * 0.1, center.dy - headRadius * 1.3)
          ..lineTo(center.dx, center.dy - headRadius * 1.0)
          ..lineTo(center.dx + size.width * 0.1, center.dy - headRadius * 1.3)
          ..lineTo(center.dx + size.width * 0.25, center.dy - headRadius * 1.0)
          ..close();
        canvas.drawPath(path, accessoryPaint);
        break;
      case Accessory.headphones:
        accessoryPaint.style = PaintingStyle.stroke;
        accessoryPaint.strokeWidth = 4;
        accessoryPaint.color = Colors.black;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: headRadius * 1.1),
          -3.14,
          3.14,
          false,
          accessoryPaint,
        );
        break;
      case Accessory.flower:
        accessoryPaint.style = PaintingStyle.fill;
        accessoryPaint.color = Colors.pink;
        canvas.drawCircle(
          center.translate(-headRadius * 0.8, -headRadius * 0.5),
          size.width * 0.1,
          accessoryPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) {
    return oldDelegate.avatar != avatar;
  }
}

/// Avatar customization screen
class AvatarCustomizationScreen extends StatefulWidget {
  const AvatarCustomizationScreen({
    required this.initialAvatar,
    required this.onSave,
    super.key,
  });

  final Avatar initialAvatar;
  final Function(Avatar) onSave;

  @override
  State<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen> {
  late Avatar _currentAvatar;

  String _formatLabel(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.initialAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Avatar'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(_currentAvatar);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(VibrantRadius.xl),
                bottomRight: Radius.circular(VibrantRadius.xl),
              ),
            ),
            child: Column(
              children: [
                AvatarWidget(
                  avatar: _currentAvatar,
                  size: 150,
                  showBackground: true,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  '${_formatLabel(_currentAvatar.outfit.name)} look',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),

          // Customization options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              children: [
                _buildSection(
                  'Skin Tone',
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: SkinTone.values.map((tone) {
                      return _ColorOption(
                        color: tone.color,
                        isSelected: _currentAvatar.skinTone == tone,
                        onTap: () {
                          setState(() {
                            _currentAvatar = _currentAvatar.copyWith(skinTone: tone);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                _buildSection(
                  'Hair Style',
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    children: HairStyle.values.map((style) {
                      return _TextOption(
                        label: style.name,
                        isSelected: _currentAvatar.hairStyle == style,
                        onTap: () {
                          setState(() {
                            _currentAvatar = _currentAvatar.copyWith(hairStyle: style);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                _buildSection(
                  'Hair Color',
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: HairColor.values.map((color) {
                      return _ColorOption(
                        color: color.color,
                        isSelected: _currentAvatar.hairColor == color,
                        onTap: () {
                          setState(() {
                            _currentAvatar = _currentAvatar.copyWith(hairColor: color);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                _buildSection(
                  'Eyes',
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    children: Eyes.values.map((eyes) {
                      return _TextOption(
                        label: eyes.name,
                        isSelected: _currentAvatar.eyes == eyes,
                        onTap: () {
                          setState(() {
                            _currentAvatar = _currentAvatar.copyWith(eyes: eyes);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                _buildSection(
                  'Outfit',
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    children: Outfit.values.map((outfit) {
                      return _TextOption(
                        label: outfit.name,
                        isSelected: _currentAvatar.outfit == outfit,
                        onTap: () {
                          setState(() {
                            _currentAvatar = _currentAvatar.copyWith(outfit: outfit);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                _buildSection(
                  'Accessory',
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    children: [
                      _TextOption(
                        label: 'None',
                        isSelected: _currentAvatar.accessory == null,
                        onTap: () {
                          setState(() {
                            _currentAvatar = _currentAvatar.copyWith(accessory: null);
                          });
                        },
                      ),
                      ...Accessory.values.map((accessory) {
                        return _TextOption(
                          label: accessory.name,
                          isSelected: _currentAvatar.accessory == accessory,
                          onTap: () {
                            setState(() {
                              _currentAvatar = _currentAvatar.copyWith(accessory: accessory);
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          content,
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _TextOption extends StatelessWidget {
  const _TextOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.md,
          vertical: VibrantSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VibrantRadius.md),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
