import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated flame icon that grows with streak count
/// Provides visual feedback for daily streak progress
class StreakFlame extends StatefulWidget {
  const StreakFlame({required this.streakDays, super.key, this.size = 40});

  final int streakDays;
  final double size;

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late AnimationController _pulseController;
  late Animation<double> _flickerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Flicker animation for flame effect
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _flickerAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );

    // Pulse animation for emphasis on high streaks
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

    if (widget.streakDays >= 7) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(StreakFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakDays >= 7 && oldWidget.streakDays < 7) {
      _pulseController.repeat();
    } else if (widget.streakDays < 7 && oldWidget.streakDays >= 7) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getFlameColor() {
    if (widget.streakDays >= 30) {
      return Colors.deepPurple; // Epic streak!
    } else if (widget.streakDays >= 14) {
      return Colors.red; // Hot streak
    } else if (widget.streakDays >= 7) {
      return Colors.deepOrange; // Week streak
    } else if (widget.streakDays >= 3) {
      return Colors.orange; // Getting started
    } else {
      return Colors.orangeAccent; // New streak
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFlameColor();
    final intensity = math.min(widget.streakDays / 30.0, 1.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_flickerController, _pulseController]),
      builder: (context, child) {
        final scale =
            _flickerAnimation.value *
            (widget.streakDays >= 7 ? _pulseAnimation.value : 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.3 + (intensity * 0.3)),
                  color.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              Icons.local_fire_department,
              size: widget.size * 0.7,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

/// Streak counter with animated flame
class StreakDisplay extends StatefulWidget {
  const StreakDisplay({required this.streakDays, super.key, this.onTap});

  final int streakDays;
  final VoidCallback? onTap;

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayedStreak = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animateCount();
  }

  @override
  void didUpdateWidget(StreakDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakDays != oldWidget.streakDays) {
      _animateCount();
    }
  }

  void _animateCount() {
    final animation = IntTween(
      begin: _displayedStreak,
      end: widget.streakDays,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    animation.addListener(() {
      setState(() {
        _displayedStreak = animation.value;
      });
    });

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.1),
              Colors.deepOrange.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreakFlame(streakDays: widget.streakDays, size: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_displayedStreak Day${_displayedStreak == 1 ? '' : 's'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Streak',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Streak milestone celebration widget
class StreakMilestone extends StatelessWidget {
  const StreakMilestone({required this.streakDays, super.key});

  final int streakDays;

  String _getMilestoneMessage() {
    if (streakDays >= 100) return '🏆 LEGENDARY STREAK!';
    if (streakDays >= 50) return '⭐ EPIC STREAK!';
    if (streakDays >= 30) return '🔥 MONTH MASTER!';
    if (streakDays >= 14) return '💪 TWO WEEKS!';
    if (streakDays >= 7) return '🎉 WEEK WARRIOR!';
    if (streakDays >= 3) return '✨ 3 DAY STREAK!';
    return '🔥 STREAK STARTED!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.deepOrange.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          StreakFlame(streakDays: streakDays, size: 80),
          const SizedBox(height: 16),
          Text(
            _getMilestoneMessage(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.deepOrange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep it up! Don\'t break the chain!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
