import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';
import '../services/haptic_service.dart';
import '../services/language_controller.dart';
import '../widgets/ancient_label.dart';
import '../widgets/language_picker_sheet.dart';

/// Onboarding flow for new users
/// Introduces the app mission, core features, and language selection
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      HapticService.light();
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticService.light();
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    HapticService.celebrate();
    // Mark onboarding as complete in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              if (_currentPage < 3)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),

              // Page view
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    HapticService.selection();
                  },
                  children: [
                    _buildWelcomePage(theme),
                    _buildFeaturesPage(theme),
                    _buildPhilosophyPage(theme),
                    _buildLanguageSelectionPage(theme),
                  ],
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.amber
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _previousPage,
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'Back',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 80),

                    // Next/Get Started button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage < 3 ? 'Next' : 'Get Started',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage < 3
                                ? Icons.arrow_forward
                                : Icons.rocket_launch,
                            color: Colors.black87,
                          ),
                        ],
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
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon with glow
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.amber.shade300, Colors.orange.shade400],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.school, size: 80, color: Colors.white),
          ),

          const SizedBox(height: 48),

          // Welcome text
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [Colors.amber.shade300, Colors.orange.shade400],
              ).createShader(bounds);
            },
            child: Text(
              'Welcome to\nAncient Languages',
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Learn ancient languages,\nunlock ancient wisdom',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Feature badges
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildBadge(theme, Icons.translate, 'Ancient Greek'),
              _buildBadge(theme, Icons.menu_book, 'Latin'),
              _buildBadge(theme, Icons.language, 'Hebrew'),
              _buildBadge(theme, Icons.self_improvement, 'Sanskrit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gamified Learning',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 48),

          _buildFeatureItem(
            theme,
            Icons.stars,
            'Earn XP & Level Up',
            'Complete lessons, maintain streaks, and climb the ranks',
          ),

          const SizedBox(height: 32),

          _buildFeatureItem(
            theme,
            Icons.local_fire_department,
            'Build Daily Streaks',
            'Practice every day to build unstoppable momentum',
          ),

          const SizedBox(height: 32),

          _buildFeatureItem(
            theme,
            Icons.emoji_events,
            'Compete & Achieve',
            'Unlock achievements, challenge friends on leaderboards',
          ),

          const SizedBox(height: 32),

          _buildFeatureItem(
            theme,
            Icons.auto_stories,
            'Story Mode',
            'Learn through interactive narratives and quests',
          ),
        ],
      ),
    );
  }

  Widget _buildPhilosophyPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: Colors.amber),

          const SizedBox(height: 32),

          Text(
            'Our Mission',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          Text(
            'This isn\'t just about learning languages.\n\n'
            'We\'re using ancient languages as a gateway to inject '
            'philosophy, theology, history, and great literature into minds '
            'that traditionally resist learning.\n\n'
            'Our goal: make studying Plato, Homer, and the Vedas '
            'more addictive than social media.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              '"γνῶθι σεαυτόν"\n(Know thyself)',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.amber,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionPage(ThemeData theme) {
    final languageCodeAsync = ref.watch(languageControllerProvider);
    final sections = ref.watch(languageMenuSectionsProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: languageCodeAsync.when(
        data: (currentLanguageCode) {
          final available = sections.available;
          final upcoming = sections.comingSoon;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Language',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You can change this later',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    if (available.isNotEmpty) ...[
                      _buildLanguageSectionHeader(
                        theme,
                        'Available now',
                        available.length,
                      ),
                      const SizedBox(height: 12),
                      ...available.map(
                        (language) => _buildLanguageTile(
                          theme,
                          currentLanguageCode,
                          language,
                          enabled: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      _buildLanguageSectionHeader(
                        theme,
                        'Coming soon',
                        upcoming.length,
                      ),
                      const SizedBox(height: 12),
                      ...upcoming.map(
                        (language) => _buildLanguageTile(
                          theme,
                          currentLanguageCode,
                          language,
                          enabled: false,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                onPressed: () async {
                  final selected = await LanguagePickerSheet.show(
                    context: context,
                    currentLanguageCode: currentLanguageCode,
                  );
                  if (selected != null) {
                    await _handleLanguageSelection(
                      selected,
                      allowUnavailable: selected.isAvailable,
                    );
                  }
                },
                icon: const Icon(Icons.language),
                label: const Text(
                  'Browse full language catalog',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load languages',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    ThemeData theme,
    String currentLanguageCode,
    LanguageInfo language, {
    required bool enabled,
  }) {
    final colorScheme = theme.colorScheme;
    final isSelected = language.code == currentLanguageCode;
    final status = _languageStatusLabel(language, enabled);
    final opacity = enabled ? 1.0 : 0.45;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTap: () =>
                _handleLanguageSelection(language, allowUnavailable: enabled),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    language.flag,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                                color: isSelected ? Colors.amber : Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (status != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AncientLabel(
                        language: language,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.start,
                        showTooltip: false,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.amber, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLanguageSelection(
    LanguageInfo language, {
    required bool allowUnavailable,
  }) async {
    if (!allowUnavailable && !language.isAvailable) {
      if (!mounted) return;
      final status = _languageStatusLabel(language, false) ?? 'Unavailable';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${language.name} is $status. Follow our roadmap for release updates.',
          ),
        ),
      );
      return;
    }

    HapticService.selection();
    // Ensure language is saved before proceeding
    await ref
        .read(languageControllerProvider.notifier)
        .setLanguage(language.code);

    // Add a small delay to ensure SharedPreferences write completes
    await Future.delayed(const Duration(milliseconds: 100));
  }

  String? _languageStatusLabel(LanguageInfo language, bool enabled) {
    if (!enabled) {
      return language.comingSoon ? 'Coming soon' : 'Planned';
    }
    if (!language.isFullCourse) {
      return 'Partial course';
    }
    return null;
  }

  Widget _buildLanguageSectionHeader(ThemeData theme, String title, int count) {
    return Text(
      '$title ($count)',
      style: theme.textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildBadge(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.amber, size: 32),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
