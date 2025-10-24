/// Premium loading overlay with stunning animations
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Stunning full-screen loading overlay
class PremiumLoadingOverlay extends StatefulWidget {
  const PremiumLoadingOverlay({
    super.key,
    required this.message,
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  State<PremiumLoadingOverlay> createState() => _PremiumLoadingOverlayState();

  /// Show loading overlay as a modal
  static Future<T?> show<T>({
    required BuildContext context,
    required String message,
    String? subtitle,
    required Future<T> Function() task,
  }) async {
    final overlay = OverlayEntry(
      builder: (context) => PremiumLoadingOverlay(
        message: message,
        subtitle: subtitle,
      ),
    );

    Overlay.of(context).insert(overlay);

    try {
      final result = await task();
      overlay.remove();
      return result;
    } catch (e) {
      overlay.remove();
      rethrow;
    }
  }
}

class _PremiumLoadingOverlayState extends State<PremiumLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        width: size.width,
        height: size.height,
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(VibrantSpacing.xl),
            padding: const EdgeInsets.all(VibrantSpacing.xxl),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(VibrantRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated loading indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating ring
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.2),
                                width: 4,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Inner pulsing circle
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 0.6 + (_pulseController.value * 0.2);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3 * _pulseController.value,
                                  ),
                                  blurRadius: 20 * _pulseController.value,
                                  spreadRadius: 5 * _pulseController.value,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Center icon
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ],
                ),

                const SizedBox(height: VibrantSpacing.xl),

                // Message
                Text(
                  widget.message,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (widget.subtitle != null) ...[
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: VibrantSpacing.lg),

                // Animated dots
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final delay = index * 0.33;
                        final animValue = (_pulseController.value + delay) % 1.0;
                        final opacity = (math.sin(animValue * math.pi * 2) + 1) / 2;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.xs,
                          ),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
