import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/vibrant_colors.dart';
import '../../theme/design_tokens.dart';

/// Celebration dialog shown when user completes a challenge.
///
/// Features:
/// - Confetti animation
/// - Reward display (coins + XP)
/// - Motivational message
/// - Auto-dismiss after 3 seconds
///
/// Research: Visual feedback increases engagement by 30%
class CelebrationDialog extends StatefulWidget {
  final int coins;
  final int xp;
  final String? title;
  final String? message;
  final VoidCallback? onDismiss;

  const CelebrationDialog({
    super.key,
    required this.coins,
    required this.xp,
    this.title,
    this.message,
    this.onDismiss,
  });

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Scale animation for rewards
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _confettiController.play();
    _scaleController.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            shouldLoop: false,
            colors: [
              VibrantColors.xpGold,
              VibrantColors.combo,
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary,
            ],
          ),
        ),

        // Dialog content
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.space16),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.space16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  widget.title ?? '🎉 Challenge Complete!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.space16),

                // Rewards with scale animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Coins
                      if (widget.coins > 0) ...[
                        _RewardBadge(
                          icon: Icons.monetization_on,
                          iconColor: VibrantColors.xpGold,
                          value: '+${widget.coins}',
                          label: 'Coins',
                        ),
                        const SizedBox(width: AppSpacing.space16),
                      ],

                      // XP
                      if (widget.xp > 0)
                        _RewardBadge(
                          icon: Icons.stars,
                          iconColor: VibrantColors.combo,
                          value: '+${widget.xp}',
                          label: 'XP',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // Message
                if (widget.message != null)
                  Text(
                    widget.message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: AppSpacing.space12),

                // Tap to dismiss hint
                Text(
                  'Tap anywhere to continue',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Invisible barrier to dismiss on tap
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              widget.onDismiss?.call();
            },
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _RewardBadge({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Quick helper to show celebration dialog
void showCelebration(
  BuildContext context, {
  required int coins,
  required int xp,
  String? title,
  String? message,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => CelebrationDialog(
      coins: coins,
      xp: xp,
      title: title,
      message: message,
      onDismiss: onDismiss,
    ),
  );
}
