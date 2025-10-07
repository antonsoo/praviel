import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// GAME-CHANGING immersive lesson card with 3D depth and premium animations
/// This is what makes users go "WOW!"
class ImmersiveLessonCard extends StatefulWidget {
  const ImmersiveLessonCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isLoading = false,
    this.progress,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isLoading;
  final double? progress;

  @override
  State<ImmersiveLessonCard> createState() => _ImmersiveLessonCardState();
}

class _ImmersiveLessonCardState extends State<ImmersiveLessonCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxLarge),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: _isPressed ? 12 : 24,
                offset: Offset(0, _isPressed ? 4 : 12),
                spreadRadius: _isPressed ? 0 : 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 2 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxLarge),
            child: Stack(
              children: [
                // Gradient background
                Container(decoration: BoxDecoration(gradient: widget.gradient)),

                // Animated shimmer effect
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Positioned(
                      left: -200 + (_shimmerController.value * 400),
                      top: -100,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: 100,
                          height: 400,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Floating particles background
                _buildFloatingParticles(),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.space16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const Spacer(),
                          if (widget.isLoading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          if (widget.progress != null) ...[
                            const SizedBox(height: AppSpacing.space12),
                            _buildProgressBar(widget.progress!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Glass border effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xxLarge),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return Stack(
      children: List.generate(8, (index) {
        final random = math.Random(index);
        final left = random.nextDouble() * 100;
        final top = random.nextDouble() * 100;
        final size = 20 + random.nextDouble() * 40;

        return Positioned(
          left: left,
          top: top,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(seconds: 3 + random.nextInt(2)),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              final animatedTop =
                  top + math.sin(value * math.pi * 2 + index) * 20;
              return Transform.translate(
                offset: Offset(0, animatedTop - top),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) {
                setState(() {}); // Trigger rebuild to restart animation
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Stack(
      children: [
        // Glow effect
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
