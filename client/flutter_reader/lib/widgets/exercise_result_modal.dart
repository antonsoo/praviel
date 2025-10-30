import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_tokens.dart';
import '../theme/premium_gradients.dart';
import 'animated_progress_ring.dart';
import 'particle_success.dart';

/// STUNNING exercise result modal that celebrates success
/// This is what makes learning feel like a game
class ExerciseResultModal extends StatelessWidget {
  const ExerciseResultModal({
    super.key,
    required this.isCorrect,
    required this.correctCount,
    required this.totalCount,
    required this.xpGained,
    this.feedbackMessage,
  });

  final bool isCorrect;
  final int correctCount;
  final int totalCount;
  final int xpGained;
  final String? feedbackMessage;

  static Future<void> show({
    required BuildContext context,
    required bool isCorrect,
    required int correctCount,
    required int totalCount,
    required int xpGained,
    String? feedbackMessage,
  }) async {
    HapticFeedback.heavyImpact();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) => ExerciseResultModal(
        isCorrect: isCorrect,
        correctCount: correctCount,
        totalCount: totalCount,
        xpGained: xpGained,
        feedbackMessage: feedbackMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = totalCount > 0 ? correctCount / totalCount : 0.0;
    final percentage = (score * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxLarge),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result icon with particles
            if (isCorrect) ...[
              ParticleSuccess(child: _buildSuccessIcon(theme)),
            ] else ...[
              _buildTryAgainIcon(theme),
            ],

            const SizedBox(height: AppSpacing.space32),

            // Title
            Text(
              isCorrect ? _getSuccessTitle(percentage) : 'Keep Practicing!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.space16),

            // Score display with animated ring
            AnimatedProgressRing(
              progress: score,
              size: 140,
              strokeWidth: 14,
              gradient: _getGradientForScore(percentage),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _getColorForScore(percentage),
                    ),
                  ),
                  Text(
                    '$correctCount/$totalCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space24),

            // XP gained
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space24,
                vertical: AppSpacing.space16,
              ),
              decoration: BoxDecoration(
                gradient: PremiumGradients.premiumButton,
                borderRadius: BorderRadius.circular(AppRadius.large),
                boxShadow: PremiumShadows.glow(const Color(0xFFFBBF24)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    '+$xpGained XP',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            if (feedbackMessage != null) ...[
              const SizedBox(height: AppSpacing.space16),
              Text(
                feedbackMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppSpacing.space32),

            // Close button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Continue'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(ThemeData theme) {
    return RippleEffect(
      color: const Color(0xFF10B981),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: PremiumGradients.successButton,
          boxShadow: PremiumShadows.glow(const Color(0xFF10B981)),
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 60),
      ),
    );
  }

  Widget _buildTryAgainIcon(ThemeData theme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PremiumGradients.streakButton,
        boxShadow: PremiumShadows.glow(const Color(0xFFF59E0B)),
      ),
      child: const Icon(Icons.refresh, color: Colors.white, size: 60),
    );
  }

  String _getSuccessTitle(int percentage) {
    if (percentage == 100) return 'Perfect! 🎉';
    if (percentage >= 90) return 'Excellent! ✨';
    if (percentage >= 70) return 'Great Job! 👏';
    return 'Good Effort! 💪';
  }

  Gradient _getGradientForScore(int percentage) {
    if (percentage >= 90) return PremiumGradients.successButton;
    if (percentage >= 70) return PremiumGradients.premiumButton;
    return PremiumGradients.streakButton;
  }

  Color _getColorForScore(int percentage) {
    if (percentage >= 90) return const Color(0xFF10B981);
    if (percentage >= 70) return const Color(0xFFFBBF24);
    return const Color(0xFFF59E0B);
  }
}
