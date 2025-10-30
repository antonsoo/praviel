import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/vibrant_animations.dart';

/// Advanced empty state with animations and engaging copy (2025 UX best practices)
class AdvancedEmptyState extends StatefulWidget {
  const AdvancedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.lottieAsset,
    this.customAnimation,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? lottieAsset;
  final Widget? customAnimation;

  @override
  State<AdvancedEmptyState> createState() => _AdvancedEmptyStateState();
}

class _AdvancedEmptyStateState extends State<AdvancedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.slow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: VibrantCurve.smooth),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: VibrantCurve.playful),
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
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon or lottie
            ScaleTransition(
              scale: _scaleAnimation,
              child: widget.lottieAsset != null
                  ? SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        widget.lottieAsset!,
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    )
                  : widget.customAnimation ??
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.secondaryContainer,
                            ],
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 60,
                          color: colorScheme.primary,
                        ),
                      ),
            ),

            const SizedBox(height: 32),

            // Animated title
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Animated subtitle
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Text(
                  widget.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ),
            ),

            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnimation,
                child: FilledButton.icon(
                  onPressed: widget.onAction,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(widget.actionLabel!),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specific empty states for common scenarios
class NoLessonsEmptyState extends StatelessWidget {
  const NoLessonsEmptyState({super.key, this.onStartLearning});

  final VoidCallback? onStartLearning;

  @override
  Widget build(BuildContext context) {
    return AdvancedEmptyState(
      icon: Icons.school_outlined,
      title: 'Your Learning Journey Awaits!',
      subtitle:
          'Start your first lesson to unlock the wisdom of ancient languages',
      actionLabel: 'Start Learning',
      onAction: onStartLearning,
    );
  }
}

class NoHistoryEmptyState extends StatelessWidget {
  const NoHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdvancedEmptyState(
      icon: Icons.history,
      title: 'No History Yet',
      subtitle: 'Complete lessons to see your learning journey here',
    );
  }
}

class NoAchievementsEmptyState extends StatelessWidget {
  const NoAchievementsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdvancedEmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Achieve Greatness!',
      subtitle: 'Complete challenges and lessons to unlock achievements',
    );
  }
}

class NoConnectionEmptyState extends StatelessWidget {
  const NoConnectionEmptyState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AdvancedEmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'No Connection',
      subtitle: 'Check your internet connection and try again',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return AdvancedEmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      subtitle: 'Try different keywords or check your spelling',
    );
  }
}
