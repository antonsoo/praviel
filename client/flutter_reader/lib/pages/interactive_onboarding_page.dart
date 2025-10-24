import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';
import '../services/language_controller.dart';
import '../widgets/effects/confetti_overlay.dart';

/// 2025 Interactive Onboarding inspired by Duolingo's "delayed signup" pattern
/// Shows value FIRST with an interactive mini-lesson before asking for commitment
class InteractiveOnboardingPage extends ConsumerStatefulWidget {
  const InteractiveOnboardingPage({super.key});

  @override
  ConsumerState<InteractiveOnboardingPage> createState() => _InteractiveOnboardingPageState();
}

class _InteractiveOnboardingPageState extends ConsumerState<InteractiveOnboardingPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _floatingController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  int _currentPage = 0;
  bool _showConfetti = false;
  String? _selectedLanguage;
  bool _answerCorrect = false;

  // Mini lesson data - translating "Hello" in different languages
  final Map<String, Map<String, dynamic>> _miniLessons = {
    'lat': {
      'word': 'Salve',
      'translation': 'Hello',
      'options': ['Hello', 'Goodbye', 'Please', 'Thank you'],
      'fun_fact': 'Salve was the everyday greeting in ancient Rome!',
    },
    'grc-cls': {
      'word': 'Χαῖρε',
      'translation': 'Hello',
      'options': ['Hello', 'Goodbye', 'Welcome', 'Friend'],
      'fun_fact': 'Χαῖρε (Khaire) literally means "rejoice" in ancient Greek!',
    },
    'hbo': {
      'word': 'שָׁלוֹם',
      'translation': 'Peace/Hello',
      'options': ['Peace', 'War', 'Food', 'House'],
      'fun_fact': 'Shalom means both "hello" and "peace" in Hebrew!',
    },
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(_shimmerController);

    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      HapticService.light();
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
      _scaleController.forward(from: 0);
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticService.light();
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _showConfetti = true);
    HapticService.celebrate();

    // Save onboarding completion and selected language
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (_selectedLanguage != null) {
      await prefs.setString('selected_language', _selectedLanguage!);
      // Update language controller
      ref.read(languageControllerProvider.notifier).setLanguage(_selectedLanguage!);
    }

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _currentPage == 2 && _answerCorrect
                    ? [const Color(0xFF10B981), const Color(0xFF059669), const Color(0xFF047857)]
                    : [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                        const Color(0xFFEC4899),
                      ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Progress bar
                _buildProgressBar(),

                // Page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe - use buttons only
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        if (index != 2) _answerCorrect = false; // Reset answer state
                      });
                      HapticService.selection();
                    },
                    children: [
                      _buildWelcomePage(theme, size),
                      _buildLanguageSelectionPage(theme),
                      _buildMiniLessonPage(theme), // Interactive lesson BEFORE commitment
                      _buildGoalSelectionPage(theme),
                      _buildFinalPage(theme),
                    ],
                  ),
                ),

                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),

          // Confetti overlay
          if (_showConfetti)
            const ConfettiOverlay(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentPage;
          final isCurrent = index == _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isCurrent
                    ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 8)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme, Size size) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFEA580C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                            blurRadius: 50,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_stories, size: 80, color: Colors.white),
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF7ED)],
                  ).createShader(bounds);
                },
                child: const Text(
                  'Learn Ancient\nWisdom',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Master Latin, Greek, and Hebrew\nthrough interactive lessons',
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              _buildShimmeringBadge('Start in just 2 minutes', Icons.timer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmeringBadge(String text, IconData icon) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3 + (_shimmerAnimation.value.abs() * 0.1)),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelectionPage(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Your\nFirst Language',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'You can learn more languages later',
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            _buildLanguageCard('lat', '🏛️', 'Classical Latin', 'Language of Rome'),
            const SizedBox(height: 20),
            _buildLanguageCard('grc-cls', '🏺', 'Classical Greek', 'Language of Homer'),
            const SizedBox(height: 20),
            _buildLanguageCard('hbo', '📜', 'Biblical Hebrew', 'Language of the Torah'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(String code, String emoji, String name, String description) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLanguage = code);
        HapticService.medium();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected
                          ? const Color(0xFF6366F1).withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLessonPage(ThemeData theme) {
    if (_selectedLanguage == null) return const SizedBox.shrink();

    final lesson = _miniLessons[_selectedLanguage]!;
    final word = lesson['word'] as String;
    final translation = lesson['translation'] as String;
    final options = lesson['options'] as List<String>;
    final funFact = lesson['fun_fact'] as String;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_answerCorrect) ...[
              const Text(
                'Try Your First\nTranslation!',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // The word to translate
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                'Select the English translation:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              // Options
              ...options.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildOptionButton(option, translation),
                  )),
            ] else ...[
              // Success state
              const Icon(Icons.celebration, color: Colors.white, size: 100),
              const SizedBox(height: 30),
              const Text(
                'Perfect! 🎉',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                funFact,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Text(
                'You earned 50 XP!',
                style: TextStyle(
                  fontSize: 22,
                  color: const Color(0xFFFBBF24),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer) {
    return ElevatedButton(
      onPressed: () {
        HapticService.light();
        if (option == correctAnswer) {
          setState(() {
            _answerCorrect = true;
          });
          HapticService.celebrate();
          // Auto-advance after 2 seconds on correct answer
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) _nextPage();
          });
        } else {
          HapticService.error();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        elevation: 0,
      ),
      child: Text(
        option,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGoalSelectionPage(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'What\'s Your\nLearning Goal?',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            _buildGoalCard(Icons.explore, 'Explore', 'Discover ancient texts'),
            const SizedBox(height: 16),
            _buildGoalCard(Icons.school, 'Academic', 'Study for research'),
            const SizedBox(height: 16),
            _buildGoalCard(Icons.auto_stories, 'Religious', 'Read sacred texts'),
            const SizedBox(height: 16),
            _buildGoalCard(Icons.favorite, 'Hobby', 'Personal enrichment'),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white, size: 100),
            const SizedBox(height: 40),
            const Text(
              'You\'re Ready\nto Begin!',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            Text(
              'Your personalized learning path\nhas been created',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            _buildFeatureBadge(Icons.emoji_events, 'Earn XP & Level Up'),
            const SizedBox(height: 16),
            _buildFeatureBadge(Icons.local_fire_department, 'Build Daily Streaks'),
            const SizedBox(height: 16),
            _buildFeatureBadge(Icons.psychology, 'AI-Powered Lessons'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canGoNext = _currentPage != 1 || _selectedLanguage != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentPage > 0 && _currentPage != 2) // Hide back on lesson page
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            )
          else
            const SizedBox(width: 100),

          // Next/Start button
          if (_currentPage != 2 || _answerCorrect) // Hide next on lesson until correct
            FilledButton.icon(
              onPressed: canGoNext ? _nextPage : null,
              icon: Icon(_currentPage < 4 ? Icons.arrow_forward : Icons.rocket_launch),
              label: Text(_currentPage < 4 ? 'Next' : 'Start Learning'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(width: 150),
        ],
      ),
    );
  }
}
