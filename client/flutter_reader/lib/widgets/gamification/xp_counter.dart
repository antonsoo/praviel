import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// Animated XP counter that shows current XP with a pulsing effect
class XPCounter extends StatelessWidget {
  const XPCounter({
    super.key,
    required this.xp,
    this.size = XPCounterSize.medium,
    this.showLabel = true,
  });

  final int xp;
  final XPCounterSize size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = size == XPCounterSize.large ? 32.0 : size == XPCounterSize.medium ? 24.0 : 18.0;
    final iconSize = size == XPCounterSize.large ? 28.0 : size == XPCounterSize.medium ? 22.0 : 18.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == XPCounterSize.large ? 20 : size == XPCounterSize.medium ? 16 : 12,
        vertical: size == XPCounterSize.large ? 12 : size == XPCounterSize.medium ? 10 : 8,
      ),
      decoration: BoxDecoration(
        gradient: VibrantTheme.xpGradient,
        borderRadius: BorderRadius.circular(size == XPCounterSize.large ? 16 : size == XPCounterSize.medium ? 14 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.white,
            size: iconSize,
          ),
          SizedBox(width: size == XPCounterSize.small ? 6 : 8),
          Text(
            xp.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: size == XPCounterSize.small ? 4 : 6),
            Text(
              'XP',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: size == XPCounterSize.large ? 16 : size == XPCounterSize.medium ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum XPCounterSize { small, medium, large }

/// Animated XP gain widget that shows the XP increase
class XPGainBadge extends StatefulWidget {
  const XPGainBadge({
    super.key,
    required this.xpGained,
    this.delay = Duration.zero,
  });

  final int xpGained;
  final Duration delay;

  @override
  State<XPGainBadge> createState() => _XPGainBadgeState();
}

class _XPGainBadgeState extends State<XPGainBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.playful,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
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
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: VibrantTheme.xpGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.xpGained} XP',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// XP Progress bar with level information
class XPProgressBar extends StatelessWidget {
  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.levelStartXP,
    required this.levelEndXP,
    required this.currentLevel,
    this.height = 12,
    this.showLabels = true,
  });

  final int currentXP;
  final int levelStartXP;
  final int levelEndXP;
  final int currentLevel;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = ((currentXP - levelStartXP) / (levelEndXP - levelStartXP)).clamp(0.0, 1.0);
    final xpRemaining = levelEndXP - currentXP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level $currentLevel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$xpRemaining XP to Level ${currentLevel + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Stack(
          children: [
            // Background track
            Container(
              height: height,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Progress fill with gradient
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: VibrantTheme.xpGradient,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Animated XP progress bar that animates when XP changes
class AnimatedXPProgressBar extends StatefulWidget {
  const AnimatedXPProgressBar({
    super.key,
    required this.currentXP,
    required this.levelStartXP,
    required this.levelEndXP,
    required this.currentLevel,
    this.height = 12,
    this.showLabels = true,
    this.duration = VibrantDuration.slow,
  });

  final int currentXP;
  final int levelStartXP;
  final int levelEndXP;
  final int currentLevel;
  final double height;
  final bool showLabels;
  final Duration duration;

  @override
  State<AnimatedXPProgressBar> createState() => _AnimatedXPProgressBarState();
}

class _AnimatedXPProgressBarState extends State<AnimatedXPProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _updateAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedXPProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXP != widget.currentXP) {
      _updateAnimation();
      _controller.forward(from: 0.0);
    }
  }

  void _updateAnimation() {
    final newProgress = ((widget.currentXP - widget.levelStartXP) /
        (widget.levelEndXP - widget.levelStartXP))
        .clamp(0.0, 1.0);

    _animation = Tween<double>(
      begin: _previousProgress,
      end: newProgress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.smooth,
    ));

    _previousProgress = newProgress;
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
    final xpRemaining = widget.levelEndXP - widget.currentXP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level ${widget.currentLevel}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$xpRemaining XP to Level ${widget.currentLevel + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Stack(
          children: [
            // Background track
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
            // Animated progress fill
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: _animation.value,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: VibrantTheme.xpGradient,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
