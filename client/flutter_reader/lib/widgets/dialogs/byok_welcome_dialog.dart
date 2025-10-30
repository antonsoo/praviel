import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto-show BYOK (Bring Your Own Key) dialog for new users
/// Beautiful Material Design 3 dialog that welcomes users and explains API key options
class BYOKWelcomeDialog extends StatelessWidget {
  const BYOKWelcomeDialog({super.key});

  static const String _shownKey = 'byok_welcome_shown';

  /// Check if this dialog should be shown to the user
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasBeenShown = prefs.getBool(_shownKey) ?? false;
    return !hasBeenShown;
  }

  /// Mark the dialog as shown so it doesn't appear again
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shownKey, true);
  }

  /// Show the dialog if it hasn't been shown before
  static Future<void> showIfNeeded(BuildContext context) async {
    if (await shouldShow()) {
      if (context.mounted) {
        await show(context);
      }
    }
  }

  /// Show the dialog
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BYOKWelcomeDialog(),
    );
    await markAsShown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with gradient background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.key_rounded,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Welcome! 🎉',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'To generate personalized lessons, you have two options:',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Option 1: Echo Mode
            _buildOptionCard(
              context,
              icon: Icons.offline_bolt,
              iconColor: colorScheme.tertiary,
              title: 'Echo Mode (Free)',
              description: 'Start learning immediately with pre-made lessons',
              features: [
                'No API key required',
                'Works offline',
                'Great for beginners',
              ],
            ),

            const SizedBox(height: 16),

            // Option 2: BYOK
            _buildOptionCard(
              context,
              icon: Icons.psychology,
              iconColor: colorScheme.primary,
              title: 'AI-Powered (Bring Your Own Key)',
              description: 'Unlock personalized, adaptive lessons with AI',
              features: [
                'Custom difficulty',
                'Personalized content',
                'Unlimited lessons',
              ],
            ),

            const SizedBox(height: 28),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can change this anytime in Settings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // User will use Echo mode by default
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Use Echo Mode'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/settings/byok');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Add API Key'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
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
          ),
          const SizedBox(height: 14),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
