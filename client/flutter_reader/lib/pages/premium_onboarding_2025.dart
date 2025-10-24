import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';
import '../services/haptic_service.dart';
import '../services/language_controller.dart';
import '../widgets/effects/confetti_overlay.dart';

/// Premium 2025 Onboarding Experience
///
/// Design principles based on:
/// - Apple Liquid Glass (WWDC 2025): Translucent glass-like elements, bolder left-aligned typography
/// - Material 3 Expressive: Dynamic color, expressive design that makes users feel something
/// - 44pt+ touch targets (Apple accessibility standard)
/// - Professional polish matching Google/Apple/Adobe quality standards
class PremiumOnboarding2025 extends ConsumerStatefulWidget {
  const PremiumOnboarding2025({super.key});

  @override
  ConsumerState<PremiumOnboarding2025> createState() => _PremiumOnboarding2025State();
}

class _PremiumOnboarding2025State extends ConsumerState<PremiumOnboarding2025>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _heroController;
  late Animation<double> _heroAnimation;

  int _currentPage = 0;
  String? _selectedLanguage;
  bool _showConfetti = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _heroController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      HapticService.light();
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _showConfetti = true);
    HapticService.celebrate();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    await prefs.setBool('onboarding_complete', true);

    if (_selectedLanguage != null) {
      await prefs.setString('selected_language', _selectedLanguage!);
      ref.read(languageControllerProvider.notifier).setLanguage(_selectedLanguage!);
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Premium gradient background with subtle animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _currentPage == 0
                    ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                    : _currentPage == 1
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF10B981), const Color(0xFF059669)],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Minimal progress indicator (Apple style)
                _buildProgressIndicator(),

                // Page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticService.selection();
                    },
                    children: [
                      _buildWelcomePage(size),
                      _buildLanguageSelectionPage(size),
                      _buildGoalPage(size),
                    ],
                  ),
                ),

                // Navigation buttons (Apple-style 44pt+ touch targets)
                _buildNavigationButtons(),
              ],
            ),
          ),

          // Confetti celebration
          if (_showConfetti) const ConfettiOverlay(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage(Size size) {
    return FadeTransition(
      opacity: _heroAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned (Liquid Glass standard)
          children: [
            // Hero icon with Liquid Glass effect
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const Icon(
                    Icons.auto_stories,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Bold left-aligned headline (Liquid Glass typography standard)
            const Text(
              'Unlock the\nWisdom of\nAncient Texts',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.05,
                letterSpacing: -2,
              ),
            ),

            const SizedBox(height: 24),

            // Subtitle with proper spacing
            Text(
              'Master Latin, Greek, Hebrew, and 43 other ancient languages through interactive lessons designed by scholars.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 48),

            // Feature list with icons
            _buildFeatureRow(Icons.auto_graph, 'AI-powered learning paths'),
            const SizedBox(height: 16),
            _buildFeatureRow(Icons.emoji_events, 'Gamified progress tracking'),
            const SizedBox(height: 16),
            _buildFeatureRow(Icons.library_books, 'Read authentic classical texts'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 44, // Apple 44pt minimum touch target
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelectionPage(Size size) {
    // Filter languages by search query
    final filteredLanguages = _searchQuery.isEmpty
        ? availableLanguages
        : availableLanguages.where((lang) {
            final query = _searchQuery.toLowerCase();
            return lang.name.toLowerCase().contains(query) ||
                   lang.nativeName.toLowerCase().contains(query) ||
                   lang.code.toLowerCase().contains(query);
          }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Bold left-aligned headline
          const Text(
            'Choose Your\nLanguage',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Select from 46 ancient languages',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),

          const SizedBox(height: 24),

          // Search bar with Liquid Glass effect
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  decoration: InputDecoration(
                    hintText: 'Search languages...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 17,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Scrollable language grid - ALL 46 LANGUAGES!
          Expanded(
            child: filteredLanguages.isEmpty
                ? Center(
                    child: Text(
                      'No languages found',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 17,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = filteredLanguages[index];
                      return _buildLanguageCard(lang);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(LanguageInfo lang) {
    final isSelected = _selectedLanguage == lang.code;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedLanguage = lang.code);
        HapticService.medium();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.25),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isSelected ? 5 : 10,
              sigmaY: isSelected ? 5 : 10,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flag emoji
                  Text(
                    lang.flag,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  // Language name (bold, left-aligned)
                  Text(
                    lang.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Check icon if selected
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPage(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Your\nDaily Goal',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -2,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'How much time do you want to dedicate?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

          const SizedBox(height: 48),

          _buildGoalOption('Casual', '5 min/day', 'Perfect for busy schedules'),
          const SizedBox(height: 16),
          _buildGoalOption('Regular', '10 min/day', 'Recommended for steady progress'),
          const SizedBox(height: 16),
          _buildGoalOption('Serious', '20 min/day', 'Fast-track your learning'),
          const SizedBox(height: 16),
          _buildGoalOption('Intense', '30+ min/day', 'For dedicated scholars'),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String title, String duration, String description) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => HapticService.medium(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
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
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canContinue = _currentPage == 0 ||
                       (_currentPage == 1 && _selectedLanguage != null) ||
                       _currentPage == 2;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Back button (if not on first page)
          if (_currentPage > 0)
            Expanded(
              child: TextButton(
                onPressed: _previousPage,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18), // 44pt+ height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (_currentPage > 0) const SizedBox(width: 12),

          // Continue/Get Started button
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: FilledButton(
              onPressed: canContinue ? _nextPage : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 18), // 44pt+ height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage == 2 ? 'Get Started' : 'Continue',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
