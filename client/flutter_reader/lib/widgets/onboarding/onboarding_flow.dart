import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// Onboarding screen data
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    this.lottieAsset,
  });

  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final String? lottieAsset; // For future Lottie animations
}

/// Complete onboarding flow
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: 'Welcome to Ancient Languages!',
      description: 'Master Ancient Greek and Latin with AI-powered lessons',
      icon: Icons.school_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      title: 'Earn XP & Level Up',
      description:
          'Complete lessons to gain experience points and climb the ranks',
      icon: Icons.auto_awesome_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      title: 'Build Your Streak',
      description: 'Practice daily to build an unstoppable learning streak',
      icon: Icons.local_fire_department_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      title: 'Unlock Achievements',
      description: 'Complete challenges and earn awesome rewards',
      icon: Icons.emoji_events_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      title: 'Power-Ups & Boosters',
      description: 'Use special abilities to enhance your learning experience',
      icon: Icons.flash_on_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      title: 'Let\'s Begin!',
      description: 'Start your journey to mastering ancient languages',
      icon: Icons.rocket_launch_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipOnboarding() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // Progress indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VibrantSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Navigation button
            Padding(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              child: FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual onboarding page widget
class _OnboardingPageWidget extends StatelessWidget {
  const _OnboardingPageWidget({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: page.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(page.icon, size: 80, color: Colors.white),
          ),

          const SizedBox(height: VibrantSpacing.xxl),

          // Title
          Text(
            page.title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Description
          Text(
            page.description,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Goal selection page (after main onboarding)
class GoalSelectionPage extends StatefulWidget {
  const GoalSelectionPage({required this.onGoalSelected, super.key});

  final Function(LearningGoal) onGoalSelected;

  @override
  State<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage> {
  LearningGoal? _selectedGoal;

  final List<LearningGoal> _goals = const [
    LearningGoal(
      id: 'casual',
      title: 'Casual Learner',
      description: '5-10 min/day • Just for fun',
      icon: Icons.coffee_rounded,
      dailyXP: 25,
    ),
    LearningGoal(
      id: 'regular',
      title: 'Regular Student',
      description: '15-20 min/day • Build a habit',
      icon: Icons.school_rounded,
      dailyXP: 50,
    ),
    LearningGoal(
      id: 'serious',
      title: 'Serious Scholar',
      description: '30-45 min/day • Deep learning',
      icon: Icons.menu_book_rounded,
      dailyXP: 100,
    ),
    LearningGoal(
      id: 'intense',
      title: 'Dedicated Master',
      description: '1+ hour/day • Achieve fluency',
      icon: Icons.star_rounded,
      dailyXP: 200,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Goal')),
      body: ListView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        children: [
          Text(
            'How much time can you dedicate?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Choose a daily goal that fits your schedule. You can always change it later.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xxl),

          ..._goals.map((goal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
              child: AnimatedScaleButton(
                onTap: () {
                  setState(() {
                    _selectedGoal = goal;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: _selectedGoal == goal
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    border: Border.all(
                      color: _selectedGoal == goal
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _selectedGoal == goal
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(VibrantRadius.md),
                        ),
                        child: Icon(
                          goal.icon,
                          color: _selectedGoal == goal
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              goal.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedGoal == goal)
                        Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: VibrantSpacing.xl),

          FilledButton(
            onPressed: _selectedGoal != null
                ? () => widget.onGoalSelected(_selectedGoal!)
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

/// Learning goal model
class LearningGoal {
  const LearningGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.dailyXP,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int dailyXP;
}
