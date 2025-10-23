import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/language_controller.dart';
import '../../models/language.dart';
import '../language_info_sheet.dart';

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
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: 'Welcome to Ancient Languages!',
      description:
          'Master Ancient Greek, Latin, Hebrew, and Sanskrit with AI-powered lessons',
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
  ];

  // Total pages including language selection page
  int get _totalPages => _pages.length + 1;

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
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  // Language selection is the second-to-last page
                  if (index == _pages.length) {
                    return _LanguageSelectionPage();
                  }
                  return _OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // Progress indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VibrantSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
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
                  _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
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

/// Language selection page in onboarding
class _LanguageSelectionPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final languageCodeAsync = ref.watch(languageControllerProvider);
    final sections = ref.watch(languageMenuSectionsProvider);

    return languageCodeAsync.when(
      data: (currentLanguageCode) {
        final available = sections.available;
        final upcoming = sections.comingSoon;

        Widget buildLanguageCard(
          LanguageInfo language, {
          required bool enabled,
        }) {
          final isSelected = language.code == currentLanguageCode;
          final statusText = _languageStatusLabel(language, enabled);
          final status = statusText.isEmpty ? null : statusText;

          final badge = status == null
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.xs,
                    vertical: VibrantSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );

          final cardContent = Container(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    language.flag,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              language.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badge != null) badge,
                        ],
                      ),
                      const SizedBox(height: VibrantSpacing.xxs),
                      Text(
                        language.nativeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textDirection: language.textDirection,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info button
                    IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () async {
                        await LanguageInfoSheet.show(
                          context: context,
                          language: language,
                        );
                      },
                      tooltip: 'Learn more about ${language.name}',
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                  ],
                ),
              ],
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
            child: AnimatedScaleButton(
              onTap: () async {
                if (enabled) {
                  await ref
                      .read(languageControllerProvider.notifier)
                      .setLanguage(language.code);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${language.name} is ${language.comingSoon ? 'coming soon' : 'planned'} — join the waitlist to get early access.',
                      ),
                    ),
                  );
                }
              },
              child: Opacity(opacity: enabled ? 1.0 : 0.45, child: cardContent),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'Choose Your Language',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: VibrantSpacing.lg),

              // Description
              Text(
                'Select which ancient language you want to learn',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: VibrantSpacing.xxxl),

              Expanded(
                child: ListView(
                  children: [
                    _buildSectionHeading(
                      theme,
                      title: 'Available now',
                      count: available.length,
                    ),
                    ...available.map(
                      (language) => buildLanguageCard(language, enabled: true),
                    ),
                    if (upcoming.isNotEmpty) ...[
                      const SizedBox(height: VibrantSpacing.lg),
                      _buildSectionHeading(
                        theme,
                        title: 'Coming soon',
                        count: upcoming.length,
                      ),
                      ...upcoming.map(
                        (language) =>
                            buildLanguageCard(language, enabled: false),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: VibrantSpacing.md),
            Text(
              'Unable to load languages',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSectionHeading(
  ThemeData theme, {
  required String title,
  required int count,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
    child: Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: VibrantSpacing.xs),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

String _languageStatusLabel(LanguageInfo language, bool enabled) {
  if (!enabled) {
    return language.comingSoon ? 'Coming soon' : 'Planned';
  }
  if (!language.isFullCourse) {
    return 'Partial course';
  }
  return '';
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
