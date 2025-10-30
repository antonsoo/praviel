import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/haptic_service.dart';
import '../widgets/premium_celebrations.dart';
import '../features/gamification/presentation/providers/gamification_providers.dart';
import 'vibrant_profile_page.dart';

/// Enhanced lesson completion page with premium animations and celebrations
///
/// Shows XP earned, level progress, achievements unlocked, and streak updates
/// with delightful animations that make learning feel rewarding.
class LessonCompletionPage extends ConsumerStatefulWidget {
  const LessonCompletionPage({
    super.key,
    required this.languageCode,
    required this.xpEarned,
    required this.wordsLearned,
    required this.minutesStudied,
    required this.accuracy,
    this.onContinue,
  });

  final String languageCode;
  final int xpEarned;
  final int wordsLearned;
  final int minutesStudied;
  final double accuracy; // 0.0 to 1.0
  final VoidCallback? onContinue;

  @override
  ConsumerState<LessonCompletionPage> createState() => _LessonCompletionPageState();
}

class _LessonCompletionPageState extends ConsumerState<LessonCompletionPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showConfetti = false;
  bool _leveledUp = false;
  int _previousLevel = 0;
  int _newLevel = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Trigger haptic feedback and start animations
    _init();
  }

  Future<void> _init() async {
    // Celebrate success
    if (widget.accuracy >= 0.9) {
      HapticService.celebrate();
      setState(() => _showConfetti = true);
    } else if (widget.accuracy >= 0.7) {
      HapticService.success();
    } else {
      HapticService.light();
    }

    // Get current progress before updating
    final currentProgress = await ref.read(userProgressProvider.future);
    _previousLevel = currentProgress.level;

    // Complete the lesson (updates backend and local state)
    final controller = ref.read(gamificationControllerProvider);
    await controller.completeLesson(
      languageCode: widget.languageCode,
      xpEarned: widget.xpEarned,
      wordsLearned: widget.wordsLearned,
      minutesStudied: widget.minutesStudied,
    );

    // Check if user leveled up
    final newProgress = await ref.read(userProgressProvider.future);
    _newLevel = newProgress.level;

    if (_newLevel > _previousLevel) {
      setState(() => _leveledUp = true);
      HapticService.celebrate();
    }

    // Start animations
    _controller.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProgress = ref.watch(userProgressProvider);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.accuracy >= 0.9
                    ? [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ]
                    : [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
              ),
            ),
          ),

          // Confetti overlay
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiBurst(
                isActive: _showConfetti,
                particleCount: 50,
                colors: [
                  Colors.amber,
                  Colors.orange,
                  Colors.red,
                  Colors.purple,
                  Colors.blue,
                ],
              ),
            ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon
                    _buildSuccessIcon(theme)
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 32),

                    // Title
                    _buildTitle(theme)
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 16),

                    // Subtitle
                    _buildSubtitle(theme)
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 48),

                    // Stats cards
                    userProgress.when(
                      data: (progress) => _buildStatsCards(theme, progress)
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.3, end: 0),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => const SizedBox(),
                    ),

                    const SizedBox(height: 32),

                    // Level up banner
                    if (_leveledUp)
                      _buildLevelUpBanner(theme)
                          .animate(delay: 600.ms)
                          .scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(),

                    const SizedBox(height: 48),

                    // Action buttons
                    _buildActionButtons(theme)
                        .animate(delay: 800.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildSuccessIcon(ThemeData theme) {
    final IconData icon;
    final Color color;

    if (widget.accuracy >= 0.9) {
      icon = Icons.stars;
      color = Colors.amber;
    } else if (widget.accuracy >= 0.7) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.thumb_up;
      color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 80,
        color: color,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    final String title;

    if (widget.accuracy >= 0.9) {
      title = 'Perfect!';
    } else if (widget.accuracy >= 0.7) {
      title = 'Great Job!';
    } else {
      title = 'Lesson Complete!';
    }

    return Text(
      title,
      style: theme.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onPrimaryContainer,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      '${(widget.accuracy * 100).toInt()}% accuracy',
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildStatsCards(ThemeData theme, dynamic progress) {
    return Column(
      children: [
        // XP earned
        _StatCard(
          icon: Icons.star,
          label: 'XP Earned',
          value: '+${widget.xpEarned}',
          color: Colors.amber,
        ),

        const SizedBox(height: 16),

        // Row of smaller stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${progress.currentStreak}',
                color: Colors.orange,
                compact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.book,
                label: 'Words',
                value: '+${widget.wordsLearned}',
                color: Colors.blue,
                compact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.timer,
                label: 'Time',
                value: '${widget.minutesStudied}m',
                color: Colors.purple,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelUpBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.deepPurple.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level Up!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'You reached Level $_newLevel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Continue button
        FilledButton.icon(
          onPressed: () {
            if (widget.onContinue != null) {
              widget.onContinue!();
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            minimumSize: const Size(200, 56),
          ),
        ),

        const SizedBox(height: 12),

        // View progress button
        TextButton(
          onPressed: () {
            // Navigate to profile/progress page
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VibrantProfilePage(),
                ),
              );
            });
          },
          child: const Text('View Progress'),
        ),
      ],
    );
  }
}

/// Reusable stat card widget
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: compact ? 32 : 40,
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: compact ? 24 : 32,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
