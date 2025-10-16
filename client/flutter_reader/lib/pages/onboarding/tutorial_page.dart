import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../widgets/gamification/xp_counter.dart';
import '../../widgets/gamification/streak_flame.dart';

/// Tutorial screens explaining how the app works
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipTutorial() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipTutorial,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            // Tutorial pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _TutorialPageContent(
                    title: 'Earn XP & Level Up',
                    description:
                        'Complete lessons to earn XP (experience points). As you gain XP, you\'ll level up and unlock new content!',
                    child: SlideInFromBottom(
                      child: XPCounter(
                        xp: 250,
                        size: XPCounterSize.large,
                        showLabel: true,
                      ),
                    ),
                  ),
                  _TutorialPageContent(
                    title: 'Build Your Streak',
                    description:
                        'Complete at least one lesson every day to build your streak. The longer your streak, the more rewards you\'ll earn!',
                    child: SlideInFromBottom(
                      delay: const Duration(milliseconds: 200),
                      child: StreakCounter(
                        streakDays: 7,
                        size: StreakCounterSize.large,
                      ),
                    ),
                  ),
                  _TutorialPageContent(
                    title: 'Choose Your Exercises',
                    description:
                        'Learn through 18 different exercise types: matching, translation, grammar, listening, speaking, and more!',
                    child: SlideInFromBottom(
                      delay: const Duration(milliseconds: 200),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: VibrantSpacing.md,
                        runSpacing: VibrantSpacing.md,
                        children: [
                          _ExerciseTypeChip(
                            icon: Icons.sync_alt_rounded,
                            label: 'Match',
                            color: const Color(0xFF10B981),
                          ),
                          _ExerciseTypeChip(
                            icon: Icons.edit_note_rounded,
                            label: 'Fill-in-the-blank',
                            color: const Color(0xFF3B82F6),
                          ),
                          _ExerciseTypeChip(
                            icon: Icons.translate_rounded,
                            label: 'Translate',
                            color: const Color(0xFF8B5CF6),
                          ),
                          _ExerciseTypeChip(
                            icon: Icons.hearing_rounded,
                            label: 'Listen',
                            color: const Color(0xFFF59E0B),
                          ),
                          _ExerciseTypeChip(
                            icon: Icons.record_voice_over_rounded,
                            label: 'Speak',
                            color: const Color(0xFFEC4899),
                          ),
                          _ExerciseTypeChip(
                            icon: Icons.school_rounded,
                            label: 'Grammar',
                            color: const Color(0xFF06B6D4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _TutorialPageContent(
                    title: 'Compete & Achieve',
                    description:
                        'Climb the leaderboards, unlock achievements, and challenge yourself with daily and weekly goals!',
                    child: SlideInFromBottom(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AchievementIcon(
                                icon: Icons.emoji_events_rounded,
                                color: const Color(0xFFFFD700),
                              ),
                              const SizedBox(width: VibrantSpacing.md),
                              _AchievementIcon(
                                icon: Icons.military_tech_rounded,
                                color: const Color(0xFFC0C0C0),
                              ),
                              const SizedBox(width: VibrantSpacing.md),
                              _AchievementIcon(
                                icon: Icons.workspace_premium_rounded,
                                color: const Color(0xFFCD7F32),
                              ),
                            ],
                          ),
                          const SizedBox(height: VibrantSpacing.xl),
                          Container(
                            padding: const EdgeInsets.all(VibrantSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(
                                VibrantRadius.lg,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.leaderboard_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: VibrantSpacing.md),
                                Text(
                                  'Global Rank: #1',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VibrantSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => AnimatedContainer(
                    duration: VibrantDuration.fast,
                    margin: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.xs,
                    ),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              child: AnimatedScaleButton(
                onTap: _nextPage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: VibrantSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    gradient: VibrantTheme.heroGradient,
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPageContent extends StatelessWidget {
  const _TutorialPageContent({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VibrantSpacing.xl),
          child,
          const SizedBox(height: VibrantSpacing.xl),
          Text(
            description,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExerciseTypeChip extends StatelessWidget {
  const _ExerciseTypeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  const _AchievementIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BounceIn(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 36, color: color),
      ),
    );
  }
}
