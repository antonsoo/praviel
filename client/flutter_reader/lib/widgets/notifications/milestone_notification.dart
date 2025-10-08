import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Type of milestone notification
enum MilestoneType {
  xpMilestone,
  streakMilestone,
  levelUp,
  achievementUnlocked,
  dailyGoalMet,
  perfectLesson,
  combo,
}

/// Milestone notification data
class MilestoneNotification {
  const MilestoneNotification({
    required this.type,
    required this.title,
    required this.message,
    this.icon,
    this.gradient,
    this.duration = const Duration(seconds: 3),
  });

  final MilestoneType type;
  final String title;
  final String message;
  final IconData? icon;
  final Gradient? gradient;
  final Duration duration;
}

/// Service for showing milestone notifications
class MilestoneNotificationService {
  static final List<OverlayEntry> _activeNotifications = [];

  /// Show a milestone notification at the top of the screen
  static void show({
    required BuildContext context,
    required MilestoneNotification notification,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _MilestoneNotificationWidget(
        notification: notification,
        onDismiss: () {
          entry.remove();
          _activeNotifications.remove(entry);
        },
      ),
    );

    _activeNotifications.add(entry);
    overlay.insert(entry);

    // Auto-dismiss
    Future.delayed(notification.duration, () {
      if (_activeNotifications.contains(entry)) {
        entry.remove();
        _activeNotifications.remove(entry);
      }
    });
  }

  /// Show XP milestone notification
  static void showXPMilestone(BuildContext context, int xp) {
    show(
      context: context,
      notification: MilestoneNotification(
        type: MilestoneType.xpMilestone,
        title: '$xp XP!',
        message: 'You\'re making great progress!',
        icon: Icons.auto_awesome_rounded,
        gradient: VibrantTheme.xpGradient,
      ),
    );
  }

  /// Show streak milestone notification
  static void showStreakMilestone(BuildContext context, int days) {
    show(
      context: context,
      notification: MilestoneNotification(
        type: MilestoneType.streakMilestone,
        title: '$days Day Streak! 🔥',
        message: 'You\'re on fire!',
        icon: Icons.local_fire_department_rounded,
        gradient: VibrantTheme.streakGradient,
      ),
    );
  }

  /// Show daily goal met notification
  static void showDailyGoalMet(BuildContext context) {
    show(
      context: context,
      notification: MilestoneNotification(
        type: MilestoneType.dailyGoalMet,
        title: 'Daily Goal Complete! 🎯',
        message: 'You hit your target!',
        icon: Icons.check_circle_rounded,
        gradient: VibrantTheme.successGradient,
      ),
    );
  }

  /// Show perfect lesson notification
  static void showPerfectLesson(BuildContext context) {
    show(
      context: context,
      notification: MilestoneNotification(
        type: MilestoneType.perfectLesson,
        title: 'Perfect! 💯',
        message: 'You got every answer right!',
        icon: Icons.emoji_events_rounded,
        gradient: VibrantTheme.successGradient,
      ),
    );
  }

  /// Show combo notification
  static void showCombo(BuildContext context, int count) {
    show(
      context: context,
      notification: MilestoneNotification(
        type: MilestoneType.combo,
        title: '$count Combo! ⚡',
        message: 'Keep it going!',
        icon: Icons.bolt_rounded,
        gradient: VibrantTheme.heroGradient,
      ),
    );
  }

  /// Dismiss all active notifications
  static void dismissAll() {
    for (final entry in _activeNotifications) {
      entry.remove();
    }
    _activeNotifications.clear();
  }
}

/// Milestone notification widget (internal)
class _MilestoneNotificationWidget extends StatefulWidget {
  const _MilestoneNotificationWidget({
    required this.notification,
    required this.onDismiss,
  });

  final MilestoneNotification notification;
  final VoidCallback onDismiss;

  @override
  State<_MilestoneNotificationWidget> createState() =>
      _MilestoneNotificationWidgetState();
}

class _MilestoneNotificationWidgetState
    extends State<_MilestoneNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top: MediaQuery.of(context).padding.top + VibrantSpacing.md,
      left: VibrantSpacing.lg,
      right: VibrantSpacing.lg,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                gradient:
                    widget.notification.gradient ?? VibrantTheme.heroGradient,
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                boxShadow: VibrantShadow.lg(colorScheme),
              ),
              child: Row(
                children: [
                  if (widget.notification.icon != null)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.notification.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  const SizedBox(width: VibrantSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.notification.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.notification.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Snackbar-style milestone notification (bottom of screen)
class BottomMilestoneSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: VibrantSpacing.sm),
            ],
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? colorScheme.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VibrantRadius.md),
        ),
        margin: const EdgeInsets.all(VibrantSpacing.lg),
      ),
    );
  }
}
