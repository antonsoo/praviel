import 'package:flutter/material.dart';
import '../theme/animations.dart';
import '../services/haptic_service.dart';

enum AchievementType {
  streak3('3 Day Streak', Icons.local_fire_department, Colors.orange),
  streak7('Week Warrior', Icons.local_fire_department, Colors.deepOrange),
  streak30('Month Master', Icons.local_fire_department, Colors.red),
  level5('Level 5', Icons.military_tech, Colors.amber),
  level10('Level 10', Icons.military_tech, Colors.yellow),
  level20('Level 20', Icons.military_tech, Colors.amber),
  perfectScore('Perfect Score', Icons.stars, Colors.purple),
  speedster('Speed Demon', Icons.flash_on, Colors.lightBlue),
  scholar('Greek Scholar', Icons.school, Colors.teal);

  const AchievementType(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;
}

class AchievementBadge extends StatefulWidget {
  const AchievementBadge({
    required this.achievement,
    super.key,
    this.size = 80,
    this.unlocked = true,
    this.showAnimation = false,
  });

  final AchievementType achievement;
  final double size;
  final bool unlocked;
  final bool showAnimation;

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: AppAnimations.spring),
        );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 50),
    ]).animate(_controller);

    if (widget.showAnimation) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _controller.forward();
        HapticService.celebrate();
      });
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showAnimation ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.showAnimation ? _rotateAnimation.value * 0.3 : 0.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.unlocked
                    ? RadialGradient(
                        colors: [
                          widget.achievement.color.withOpacity(0.8),
                          widget.achievement.color,
                        ],
                      )
                    : null,
                color: widget.unlocked
                    ? null
                    : theme.colorScheme.surfaceContainerHighest,
                boxShadow: widget.unlocked
                    ? [
                        BoxShadow(
                          color: widget.achievement.color.withOpacity(
                            widget.showAnimation
                                ? _glowAnimation.value * 0.6
                                : 0.3,
                          ),
                          blurRadius: widget.showAnimation
                              ? 20 + (_glowAnimation.value * 20)
                              : 20,
                          spreadRadius: widget.showAnimation
                              ? _glowAnimation.value * 5
                              : 0,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.achievement.icon,
                size: widget.size * 0.5,
                color: widget.unlocked
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Achievement unlock dialog with celebration
class AchievementUnlockDialog extends StatelessWidget {
  const AchievementUnlockDialog({required this.achievement, super.key});

  final AchievementType achievement;

  static Future<void> show(BuildContext context, AchievementType achievement) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementUnlockDialog(achievement: achievement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 Achievement Unlocked!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AchievementBadge(
              achievement: achievement,
              size: 120,
              showAnimation: true,
            ),
            const SizedBox(height: 24),
            Text(
              achievement.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: achievement.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement grid for displaying all achievements
class AchievementGrid extends StatelessWidget {
  const AchievementGrid({required this.unlockedAchievements, super.key});

  final Set<AchievementType> unlockedAchievements;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: AchievementType.values.length,
      itemBuilder: (context, index) {
        final achievement = AchievementType.values[index];
        final unlocked = unlockedAchievements.contains(achievement);

        return Column(
          children: [
            AchievementBadge(
              achievement: achievement,
              unlocked: unlocked,
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: unlocked
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
