import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

/// Overlay that shows feedback when user answers a question
/// Shows at bottom of screen with animation
class AnswerFeedbackOverlay extends StatefulWidget {
  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.message,
    this.explanation,
    required this.onContinue,
    this.xpGained,
  });

  final bool isCorrect;
  final String message;
  final String? explanation;
  final VoidCallback onContinue;
  final int? xpGained;

  static Future<void> show({
    required BuildContext context,
    required bool isCorrect,
    required String message,
    String? explanation,
    required VoidCallback onContinue,
    int? xpGained,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AnswerFeedbackOverlay(
        isCorrect: isCorrect,
        message: message,
        explanation: explanation,
        onContinue: onContinue,
        xpGained: xpGained,
      ),
    );
  }

  @override
  State<AnswerFeedbackOverlay> createState() => _AnswerFeedbackOverlayState();
}

class _AnswerFeedbackOverlayState extends State<AnswerFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Play haptic and sound
    if (widget.isCorrect) {
      HapticService.success();
      SoundService.instance.success();
    } else {
      HapticService.error();
      SoundService.instance.error();
    }

    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.spring,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleContinue() {
    _controller.reverse().then((_) {
      Navigator.of(context).pop();
      widget.onContinue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.isCorrect
                ? VibrantTheme.successGradient
                : LinearGradient(
                    colors: [
                      colorScheme.errorContainer,
                      colorScheme.surface,
                    ],
                  ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.xxl),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isCorrect
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : colorScheme.error.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon and message
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.isCorrect
                              ? Colors.white.withValues(alpha: 0.3)
                              : colorScheme.error.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: widget.isCorrect
                              ? Colors.white
                              : colorScheme.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isCorrect ? 'Correct!' : 'Not quite...',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: widget.isCorrect
                                    ? Colors.white
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.xpGained != null && widget.isCorrect) ...[
                              const SizedBox(height: VibrantSpacing.xxs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: VibrantSpacing.xxs),
                                  Text(
                                    '+${widget.xpGained} XP',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Message
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    widget.message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.isCorrect
                          ? Colors.white
                          : colorScheme.onSurface,
                    ),
                  ),

                  // Explanation
                  if (widget.explanation != null) ...[
                    const SizedBox(height: VibrantSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        color: widget.isCorrect
                            ? Colors.white.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            size: 20,
                            color: widget.isCorrect
                                ? Colors.white.withValues(alpha: 0.9)
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: VibrantSpacing.sm),
                          Expanded(
                            child: Text(
                              widget.explanation!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.isCorrect
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: VibrantSpacing.xl),

                  // Continue button
                  FilledButton(
                    onPressed: _handleContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.isCorrect
                          ? Colors.white
                          : colorScheme.primary,
                      foregroundColor: widget.isCorrect
                          ? const Color(0xFF10B981)
                          : Colors.white,
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact inline feedback for exercises
class InlineFeedback extends StatelessWidget {
  const InlineFeedback({
    super.key,
    required this.isCorrect,
    required this.message,
  });

  final bool isCorrect;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: isCorrect
            ? colorScheme.tertiaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        border: Border.all(
          color: isCorrect ? colorScheme.tertiary : colorScheme.error,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isCorrect ? colorScheme.tertiary : colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: VibrantSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCorrect
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success badge that pops in
class SuccessBadge extends StatefulWidget {
  const SuccessBadge({
    super.key,
    required this.xpGained,
  });

  final int xpGained;

  @override
  State<SuccessBadge> createState() => _SuccessBadgeState();
}

class _SuccessBadgeState extends State<SuccessBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: VibrantCurve.playful,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: VibrantTheme.successGradient,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              '+${widget.xpGained} XP',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error shake animation wrapper
class ErrorShakeWrapper extends StatefulWidget {
  const ErrorShakeWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ErrorShakeWrapper> createState() => ErrorShakeWrapperState();
}

class ErrorShakeWrapperState extends State<ErrorShakeWrapper> {
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey();

  void shake() {
    _shakeKey.currentState?.shake();
    HapticService.error();
  }

  @override
  Widget build(BuildContext context) {
    return ShakeWidget(
      key: _shakeKey,
      child: widget.child,
    );
  }
}
