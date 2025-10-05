import 'package:flutter/material.dart';
import '../theme/animations.dart';

enum EmptyStateType { noHistory, noAchievements, noMessages, error, loading }

class EmptyState extends StatefulWidget {
  const EmptyState({
    required this.type,
    super.key,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.smoothEnter,
          ),
        );

    _iconAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                ScaleTransition(
                  scale: _iconAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: config.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      config.icon,
                      size: 80,
                      color: config.color.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  config.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  config.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Action button
                if (config.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: 32),
                  BounceAnimation(
                    onTap: widget.onAction!,
                    child: FilledButton.icon(
                      onPressed: widget.onAction,
                      icon: Icon(config.actionIcon),
                      label: Text(config.actionLabel!),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _EmptyStateConfig _getConfig() {
    switch (widget.type) {
      case EmptyStateType.noHistory:
        return _EmptyStateConfig(
          icon: widget.icon ?? Icons.history_outlined,
          color: Theme.of(context).colorScheme.primary,
          title: widget.title ?? 'No Lesson History',
          message:
              widget.message ??
              'Complete your first lesson to see your progress here',
          actionLabel: widget.actionLabel ?? 'Start Learning',
          actionIcon: Icons.play_arrow,
        );

      case EmptyStateType.noAchievements:
        return _EmptyStateConfig(
          icon: widget.icon ?? Icons.emoji_events_outlined,
          color: Colors.amber,
          title: widget.title ?? 'No Achievements Yet',
          message:
              widget.message ?? 'Keep learning to unlock badges and rewards!',
          actionLabel: widget.actionLabel,
          actionIcon: Icons.school,
        );

      case EmptyStateType.noMessages:
        return _EmptyStateConfig(
          icon: widget.icon ?? Icons.chat_bubble_outline,
          color: Theme.of(context).colorScheme.secondary,
          title: widget.title ?? 'Start a Conversation',
          message: widget.message ?? 'Practice your Greek with our AI personas',
          actionLabel: widget.actionLabel ?? 'Say Hello',
          actionIcon: Icons.waving_hand,
        );

      case EmptyStateType.error:
        return _EmptyStateConfig(
          icon: widget.icon ?? Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          title: widget.title ?? 'Something Went Wrong',
          message:
              widget.message ?? 'We encountered an error. Please try again.',
          actionLabel: widget.actionLabel ?? 'Retry',
          actionIcon: Icons.refresh,
        );

      case EmptyStateType.loading:
        return _EmptyStateConfig(
          icon: widget.icon ?? Icons.hourglass_empty,
          color: Theme.of(context).colorScheme.tertiary,
          title: widget.title ?? 'Loading...',
          message:
              widget.message ?? 'Please wait while we prepare your content',
          actionLabel: null,
          actionIcon: Icons.refresh,
        );
    }
  }
}

class _EmptyStateConfig {
  const _EmptyStateConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
}

/// Animated loading skeleton for content
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(
              _animation.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Complete skeleton card for lesson/message previews
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 150, height: 16),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SkeletonLoader(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonLoader(width: 200, height: 12),
        ],
      ),
    );
  }
}
