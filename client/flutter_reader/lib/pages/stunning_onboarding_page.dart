import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';
import '../services/haptic_service.dart';
import '../services/language_controller.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/effects/confetti_overlay.dart';

/// Stunning onboarding experience with world-class animations and interactions
/// Inspired by Duolingo, Drops, and Material Design 3
class StunningOnboardingPage extends ConsumerStatefulWidget {
  const StunningOnboardingPage({super.key});

  @override
  ConsumerState<StunningOnboardingPage> createState() => _StunningOnboardingPageState();
}

class _StunningOnboardingPageState extends ConsumerState<StunningOnboardingPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _floatingAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _rotateAnimationController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  int _currentPage = 0;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Floating animation for icons
    _floatingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatingAnimationController, curve: Curves.easeInOut),
    );

    // Scale animation for elements
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleAnimationController, curve: Curves.elasticOut),
    );

    // Rotate animation for decorative elements
    _rotateAnimationController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateAnimationController);

    _scaleAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingAnimationController.dispose();
    _scaleAnimationController.dispose();
    _rotateAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      HapticService.light();
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
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
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _showConfetti = true);
    HapticService.celebrate();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF6366F1), const Color(0xFF8B5CF6),
                        math.sin(_rotateAnimation.value))!,
                      Color.lerp(const Color(0xFF8B5CF6), const Color(0xFFEC4899),
                        math.cos(_rotateAnimation.value))!,
                      Color.lerp(const Color(0xFFEC4899), const Color(0xFFF59E0B),
                        math.sin(_rotateAnimation.value + 1))!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating decorative circles
          ..._buildFloatingDecorations(size),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                if (_currentPage < 3)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.9),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                // Page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticService.selection();
                      _scaleAnimationController.forward(from: 0);
                    },
                    children: [
                      _buildWelcomePage(theme),
                      _buildFeaturesPage(theme),
                      _buildMissionPage(theme),
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
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _currentPage == index
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
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
                        _buildNavButton(
                          onPressed: _previousPage,
                          icon: Icons.arrow_back,
                          label: 'Back',
                          isPrimary: false,
                        )
                      else
                        const SizedBox(width: 100),

                      // Next/Get Started button
                      _buildNavButton(
                        onPressed: _nextPage,
                        icon: _currentPage < 3 ? Icons.arrow_forward : Icons.rocket_launch,
                        label: _currentPage < 3 ? 'Next' : 'Get Started',
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
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

  List<Widget> _buildFloatingDecorations(Size size) {
    return [
      // Top-left circle
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            left: -50 + _floatingAnimation.value,
            top: 100 + _floatingAnimation.value * 0.5,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
            ),
          );
        },
      ),
      // Bottom-right circle
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            right: -30 - _floatingAnimation.value,
            bottom: 150 - _floatingAnimation.value * 0.7,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
              ),
            ),
          );
        },
      ),
      // Middle circle
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Positioned(
            right: size.width * 0.2 - _floatingAnimation.value * 0.5,
            top: size.height * 0.4 + _floatingAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildNavButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 150),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.2),
          foregroundColor: isPrimary ? const Color(0xFF6366F1) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: isPrimary ? 8 : 0,
          shadowColor: isPrimary ? Colors.black.withValues(alpha: 0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: !isPrimary
                ? BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated app icon with pulse effect
            AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Colors.amber, Colors.orange, Colors.deepOrange],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school, size: 70, color: Colors.white),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            // Gradient text
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF7ED)],
                ).createShader(bounds);
              },
              child: const Text(
                'Welcome to\nAncient Languages',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Learn ancient wisdom through\nbeautiful, gamified lessons',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Feature pills
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFeaturePill(Icons.emoji_events, 'Gamified'),
                _buildFeaturePill(Icons.psychology, 'AI-Powered'),
                _buildFeaturePill(Icons.history_edu, 'Authentic'),
                _buildFeaturePill(Icons.trending_up, 'Adaptive'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Learn Like Never Before',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 56),

            _buildFeatureCard(
              Icons.stars,
              'Earn XP & Level Up',
              'Complete lessons, maintain streaks, and unlock achievements',
              0,
            ),

            const SizedBox(height: 24),

            _buildFeatureCard(
              Icons.local_fire_department,
              'Daily Streaks',
              'Build momentum with daily practice and track your progress',
              1,
            ),

            const SizedBox(height: 24),

            _buildFeatureCard(
              Icons.auto_stories,
              'Immersive Reading',
              'Read authentic texts from Homer, Cicero, and the Vedas',
              2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
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
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
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
      },
    );
  }

  Widget _buildMissionPage(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value * 0.5),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 80,
                    color: Colors.white,
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            const Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Text(
              'This isn\'t just about learning languages.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Text(
              'We\'re using ancient languages as a gateway to inject philosophy, theology, history, and great literature into minds that traditionally resist learning.',
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    '"γνῶθι σεαυτόν"',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Know thyself',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionPage(ThemeData theme) {
    final languageCodeAsync = ref.watch(languageControllerProvider);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: languageCodeAsync.when(
          data: (currentLanguageCode) {
            final currentLanguage = availableLanguages.firstWhere(
              (lang) => lang.code == currentLanguageCode,
              orElse: () => availableLanguages.first,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose Your Path',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'You can change this anytime',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 48),

                // Selected language card
                GestureDetector(
                  onTap: () async {
                    final selected = await LanguagePickerSheet.show(
                      context: context,
                      currentLanguageCode: currentLanguageCode,
                    );
                    if (selected != null) {
                      await ref.read(languageControllerProvider.notifier).setLanguage(selected.code);
                      HapticService.selection();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentLanguage.flag,
                          style: const TextStyle(fontSize: 72),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          currentLanguage.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentLanguage.nativeName,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, color: Color(0xFF6366F1), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Tap to change',
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Quick language previews
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: availableLanguages.take(4).map((lang) {
                    return _buildQuickLanguageButton(lang, currentLanguageCode);
                  }).toList(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (error, stack) => Center(
            child: Text(
              'Error loading languages',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLanguageButton(LanguageInfo lang, String currentCode) {
    final isSelected = lang.code == currentCode;
    return GestureDetector(
      onTap: () async {
        await ref.read(languageControllerProvider.notifier).setLanguage(lang.code);
        HapticService.selection();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              lang.name,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
