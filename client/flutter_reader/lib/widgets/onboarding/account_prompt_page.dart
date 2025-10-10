import 'package:flutter/material.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/signup_page.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// Page that prompts users to create an account after onboarding
/// Highlights the benefits while allowing guest mode
class AccountPromptPage extends StatelessWidget {
  const AccountPromptPage({
    required this.onContinueAsGuest,
    required this.onAccountCreated,
    super.key,
  });

  final VoidCallback onContinueAsGuest;
  final VoidCallback onAccountCreated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: onContinueAsGuest,
                  child: const Text('Continue as Guest'),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: VibrantSpacing.xxl),

                      // Icon with gradient background
                      SlideInFromBottom(
                        delay: const Duration(milliseconds: 100),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: VibrantTheme.heroGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_circle_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: VibrantSpacing.xxl),

                      // Title
                      SlideInFromBottom(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'Create Your Account',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: VibrantSpacing.md),

                      // Description
                      SlideInFromBottom(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'Unlock the full experience with a free account',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: VibrantSpacing.xxl),

                      // Benefits list
                      SlideInFromBottom(
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.all(VibrantSpacing.lg),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VibrantRadius.xl),
                          ),
                          child: Column(
                            children: [
                              _BenefitItem(
                                icon: Icons.emoji_events_rounded,
                                title: 'Compete on Leaderboards',
                                description: 'See how you rank against other learners',
                              ),
                              const SizedBox(height: VibrantSpacing.md),
                              _BenefitItem(
                                icon: Icons.local_fire_department_rounded,
                                title: 'Track Your Streak',
                                description: 'Never lose your progress across devices',
                              ),
                              const SizedBox(height: VibrantSpacing.md),
                              _BenefitItem(
                                icon: Icons.people_rounded,
                                title: 'Challenge Friends',
                                description: 'Add friends and compete in learning duels',
                              ),
                              const SizedBox(height: VibrantSpacing.md),
                              _BenefitItem(
                                icon: Icons.stars_rounded,
                                title: 'Earn Achievements',
                                description: 'Unlock badges and collect rewards',
                              ),
                              const SizedBox(height: VibrantSpacing.md),
                              _BenefitItem(
                                icon: Icons.sync_rounded,
                                title: 'Sync Everywhere',
                                description: 'Access your progress on any device',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              const SizedBox(height: VibrantSpacing.lg),

              SlideInFromBottom(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    // Sign up button
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );

                        // If account was created successfully
                        if (result == true && context.mounted) {
                          onAccountCreated();
                        }
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Create Free Account'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.md),

                    // Sign in button
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );

                        // If login was successful
                        if (result == true && context.mounted) {
                          onAccountCreated();
                        }
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('I Already Have an Account'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.sm),

                    // Guest mode hint
                    TextButton(
                      onPressed: onContinueAsGuest,
                      child: Text(
                        'or continue as guest (limited features)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: VibrantTheme.heroGradient,
            borderRadius: BorderRadius.circular(VibrantRadius.md),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: VibrantSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
