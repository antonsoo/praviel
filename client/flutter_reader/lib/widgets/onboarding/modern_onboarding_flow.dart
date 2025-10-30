/// Modern, personalized onboarding flow inspired by modern language learning app best practices.
///
/// Focus on the user's journey, not the app's features.
/// Implements gradual engagement and personalization.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/language_controller.dart';
import '../../models/language.dart';
import '../language_info_sheet.dart';

/// User's learning goal
enum LearningGoal {
  academic('Academic Research', Icons.menu_book_rounded, 'Study ancient texts and literature'),
  spiritual('Spiritual/Religious', Icons.auto_stories_rounded, 'Read sacred texts in original language'),
  cultural('Cultural Heritage', Icons.account_balance_rounded, 'Connect with my cultural roots'),
  personal('Personal Enrichment', Icons.psychology_rounded, 'Expand my knowledge and mind'),
  professional('Professional Development', Icons.work_rounded, 'Enhance my career prospects');

  const LearningGoal(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

/// User's experience level
enum ExperienceLevel {
  beginner('Complete Beginner', Icons.star_border_rounded, 'Never studied ancient languages'),
  some('Some Experience', Icons.star_half_rounded, 'Studied a bit in school or on my own'),
  advanced('Advanced Learner', Icons.star_rounded, 'Proficient in one or more ancient languages');

  const ExperienceLevel(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

/// User's time commitment
enum TimeCommitment {
  casual('5-10 min/day', Icons.timer_rounded, 'Casual learner'),
  regular('15-20 min/day', Icons.timer_10_rounded, 'Regular practice'),
  serious('30+ min/day', Icons.timer_3_rounded, 'Serious student');

  const TimeCommitment(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

/// Modern onboarding flow with personalization
class ModernOnboardingFlow extends ConsumerStatefulWidget {
  const ModernOnboardingFlow({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  ConsumerState<ModernOnboardingFlow> createState() => _ModernOnboardingFlowState();
}

class _ModernOnboardingFlowState extends ConsumerState<ModernOnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User selections
  LearningGoal? _selectedGoal;
  ExperienceLevel? _selectedLevel;
  TimeCommitment? _selectedTime;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _fadeController.reset();
      _fadeController.forward();
    } else {
      widget.onComplete();
    }
  }

  void _skipToLanguageSelection() {
    setState(() => _currentPage = 4);
    _pageController.animateToPage(
      4,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildWelcomePage(),
          _buildGoalSelectionPage(),
          _buildExperienceLevelPage(),
          _buildTimeCommitmentPage(),
          _buildLanguageSelectionPage(),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep blue
            Color(0xFF7C3AED), // Purple
          ],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  child: TextButton(
                    onPressed: _skipToLanguageSelection,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(VibrantSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ancient scroll icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.xxl),

                        // Title
                        Text(
                          'Unlock Ancient Wisdom',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: VibrantSpacing.lg),

                        // Subtitle
                        Text(
                          'Learn Latin, Greek, Hebrew, Sanskrit,\nand 42 more ancient languages',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: VibrantSpacing.xxl * 2),

                        // Get Started button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _nextPage,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF1E3A8A),
                              padding: const EdgeInsets.symmetric(
                                vertical: VibrantSpacing.lg,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(VibrantRadius.md),
                              ),
                            ),
                            child: Text(
                              'Get Started',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: VibrantSpacing.lg),

                        // Subtitle
                        Text(
                          'Free • No account required to start',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSelectionPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: TextButton(
                  onPressed: _skipToLanguageSelection,
                  child: const Text('Skip'),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.xl,
                  vertical: VibrantSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    LinearProgressIndicator(value: 0.25),
                    const SizedBox(height: VibrantSpacing.xxl),

                    // Question
                    Text(
                      'Why do you want to learn\nan ancient language?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.lg),

                    Text(
                      'This helps us personalize your learning experience',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.xxl),

                    // Goal options
                    ...LearningGoal.values.map((goal) {
                      final isSelected = _selectedGoal == goal;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                        child: AnimatedScaleButton(
                          onTap: () {
                            setState(() => _selectedGoal = goal);
                            Future.delayed(const Duration(milliseconds: 300), _nextPage);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(VibrantSpacing.lg),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(VibrantRadius.lg),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(VibrantSpacing.md),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                                  ),
                                  child: Icon(
                                    goal.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: VibrantSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.label,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: VibrantSpacing.xxs),
                                      Text(
                                        goal.description,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceLevelPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: TextButton(
                  onPressed: _skipToLanguageSelection,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.xl,
                  vertical: VibrantSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: 0.50),
                    const SizedBox(height: VibrantSpacing.xxl),
                    Text(
                      "What's your experience\nwith ancient languages?",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xxl),
                    ...ExperienceLevel.values.map((level) {
                      final isSelected = _selectedLevel == level;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                        child: AnimatedScaleButton(
                          onTap: () {
                            setState(() => _selectedLevel = level);
                            Future.delayed(const Duration(milliseconds: 300), _nextPage);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(VibrantSpacing.lg),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(VibrantRadius.lg),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  level.icon,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  size: 32,
                                ),
                                const SizedBox(width: VibrantSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level.label,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        level.description,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCommitmentPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: TextButton(
                  onPressed: _skipToLanguageSelection,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.xl,
                  vertical: VibrantSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: 0.75),
                    const SizedBox(height: VibrantSpacing.xxl),
                    Text(
                      'How much time can you\ndedicate each day?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    Text(
                      "We'll create a personalized learning schedule",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xxl),
                    ...TimeCommitment.values.map((time) {
                      final isSelected = _selectedTime == time;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                        child: AnimatedScaleButton(
                          onTap: () {
                            setState(() => _selectedTime = time);
                            Future.delayed(const Duration(milliseconds: 300), _nextPage);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(VibrantSpacing.lg),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(VibrantRadius.lg),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  time.icon,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  size: 32,
                                ),
                                const SizedBox(width: VibrantSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        time.label,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        time.description,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedLanguageAsync = ref.watch(languageControllerProvider);
    final selectedLanguage = selectedLanguageAsync.value ?? '';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Column(
              children: [
                LinearProgressIndicator(value: 1.0),
                const SizedBox(height: VibrantSpacing.lg),
                Text(
                  'Choose Your First Language',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  'You can learn more languages anytime',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
              itemCount: availableLanguages.length,
              itemBuilder: (context, index) {
                final language = availableLanguages[index];
                final isSelected = selectedLanguage == language.code;
                final enabled = language.isAvailable;

                return Padding(
                  padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                  child: AnimatedScaleButton(
                    onTap: () {
                      if (enabled) {
                        ref
                            .read(languageControllerProvider.notifier)
                            .setLanguage(language.code);
                      }
                    },
                    child: Opacity(
                      opacity: enabled ? 1.0 : 0.5,
                      child: Container(
                        padding: const EdgeInsets.all(VibrantSpacing.lg),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(VibrantRadius.lg),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(language.flag, style: TextStyle(fontSize: 40)),
                            const SizedBox(width: VibrantSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    language.nativeName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.info_outline_rounded, size: 20),
                              onPressed: () =>
                                  LanguageInfoSheet.show(context: context, language: language),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: FilledButton(
              onPressed: selectedLanguage.isNotEmpty ? widget.onComplete : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
