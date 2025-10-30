import 'package:flutter/material.dart';

/// Visual indicator for combo multiplier during exercises
/// Shows floating multiplier badges with pulsing animations
class ComboMultiplierIndicator extends StatefulWidget {
  const ComboMultiplierIndicator({
    required this.multiplier,
    required this.comboCount,
    this.position = const Offset(20, 20),
    super.key,
  });

  final double multiplier;
  final int comboCount;
  final Offset position;

  @override
  State<ComboMultiplierIndicator> createState() =>
      _ComboMultiplierIndicatorState();
}

class _ComboMultiplierIndicatorState extends State<ComboMultiplierIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Different colors based on combo tier
    Color primaryColor;
    Color secondaryColor;
    if (widget.comboCount >= 10) {
      primaryColor = Colors.purple.shade400;
      secondaryColor = Colors.pink.shade400;
    } else if (widget.comboCount >= 5) {
      primaryColor = Colors.orange.shade400;
      secondaryColor = Colors.red.shade400;
    } else {
      primaryColor = Colors.blue.shade400;
      secondaryColor = Colors.cyan.shade400;
    }

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.multiplier.toStringAsFixed(1),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'x',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.whatshot,
                          color: Colors.white,
                          size: 16,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.comboCount} Combo',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Overlay widget that shows combo multiplier indicator
class ComboMultiplierOverlay extends StatefulWidget {
  const ComboMultiplierOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<ComboMultiplierOverlay> createState() => ComboMultiplierOverlayState();
}

class ComboMultiplierOverlayState extends State<ComboMultiplierOverlay> {
  double? _multiplier;
  int? _comboCount;
  bool _isVisible = false;

  /// Show the combo multiplier indicator
  void show({required double multiplier, required int comboCount}) {
    setState(() {
      _multiplier = multiplier;
      _comboCount = comboCount;
      _isVisible = true;
    });

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        hide();
      }
    });
  }

  /// Hide the combo multiplier indicator
  void hide() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible && _multiplier != null && _comboCount != null)
          ComboMultiplierIndicator(
            multiplier: _multiplier!,
            comboCount: _comboCount!,
          ),
      ],
    );
  }
}
