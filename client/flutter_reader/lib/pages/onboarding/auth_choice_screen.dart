import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/login_page.dart';
import '../auth/signup_page.dart';
import '../../services/haptic_service.dart';

/// Authentication choice screen wrapper that returns whether onboarding should be shown
class AuthChoiceScreenWithOnboarding extends ConsumerStatefulWidget {
  const AuthChoiceScreenWithOnboarding({super.key});

  @override
  ConsumerState<AuthChoiceScreenWithOnboarding> createState() =>
      _AuthChoiceScreenWithOnboardingState();
}

class _AuthChoiceScreenWithOnboardingState
    extends ConsumerState<AuthChoiceScreenWithOnboarding> {
  void _handleSignUp() async {
    HapticService.light();
    // Navigate to signup page
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignupPage()));

    if (!mounted) return;

    // After signup, show onboarding
    if (result == true) {
      Navigator.of(context).pop(true); // Return true to show onboarding
    }
  }

  void _handleLogin() async {
    HapticService.light();
    // Navigate to login page
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginPage()));

    if (!mounted) return;

    // After login, show onboarding if it's their first time
    if (result == true) {
      Navigator.of(context).pop(true); // Return true to show onboarding
    }
  }

  void _handleContinueAsGuest() {
    HapticService.light();
    // Guests should see onboarding on first launch
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthChoiceScreen(
      onSignUp: _handleSignUp,
      onLogin: _handleLogin,
      onContinueAsGuest: _handleContinueAsGuest,
    );
  }
}

/// Authentication choice screen shown before onboarding
/// Offers Sign Up, Login, or Continue as Guest options with beautiful UI
class AuthChoiceScreen extends ConsumerStatefulWidget {
  const AuthChoiceScreen({
    super.key,
    this.onSignUp,
    this.onLogin,
    this.onContinueAsGuest,
  });

  final VoidCallback? onSignUp;
  final VoidCallback? onLogin;
  final VoidCallback? onContinueAsGuest;

  @override
  ConsumerState<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends ConsumerState<AuthChoiceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (widget.onSignUp != null) {
      widget.onSignUp!();
    } else {
      HapticService.light();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  void _handleLogin() {
    if (widget.onLogin != null) {
      widget.onLogin!();
    } else {
      HapticService.light();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _handleContinueAsGuest() {
    if (widget.onContinueAsGuest != null) {
      widget.onContinueAsGuest!();
    } else {
      HapticService.light();
      Navigator.of(context).pop(true); // Show onboarding when returning
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero icon with Liquid Glass effect
                    Center(
                      child: Container(
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
                              Icons.person_add_outlined,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Bold left-aligned headline (Liquid Glass typography)
                    const Text(
                      'Ready to\nBegin Your\nJourney?',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -2,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Create an account to save your progress, earn achievements, and compete with friends.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Sign Up button (primary CTA)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _handleSignUp,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667EEA),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Login button (secondary CTA)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _handleLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'I Already Have an Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue as Guest button (tertiary option)
                    Center(
                      child: TextButton(
                        onPressed: _handleContinueAsGuest,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Continue as Guest',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Benefits info box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'With an account, you get:',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildBenefit(
                                Icons.cloud_sync,
                                'Cloud sync across devices',
                              ),
                              const SizedBox(height: 8),
                              _buildBenefit(
                                Icons.emoji_events,
                                'Achievements & leaderboards',
                              ),
                              const SizedBox(height: 8),
                              _buildBenefit(
                                Icons.whatshot,
                                'Streak tracking & rewards',
                              ),
                              const SizedBox(height: 8),
                              _buildBenefit(
                                Icons.people,
                                'Connect with learners',
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
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}
