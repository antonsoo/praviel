import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../../theme/vibrant_colors.dart';

/// Interactive tutorial system - Learn by doing
/// Based on 2025 research: Interactive onboarding increases retention by 50%
/// Inspired by Temple Run 2's contextual instructions
class InteractiveTutorial extends StatefulWidget {
  const InteractiveTutorial({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  @override
  State<InteractiveTutorial> createState() => _InteractiveTutorialState();
}

class _InteractiveTutorialState extends State<InteractiveTutorial> {
  int _currentStep = 0;
  bool _canProceed = false;

  void _completeStep() {
    if (!_canProceed) return;

    setState(() {
      if (_currentStep < widget.steps.length - 1) {
        _currentStep++;
        _canProceed = false;
      } else {
        widget.onComplete();
      }
    });

    HapticService.medium();
    SoundService.instance.success();
  }

  void _enableProceed() {
    if (!_canProceed) {
      setState(() => _canProceed = true);
      HapticService.light();
      SoundService.instance.sparkle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];

    return Stack(
      children: [
        // User's actual content (interactive)
        step.content(context, _enableProceed),

        // Overlay with spotlight and instruction
        IgnorePointer(
          ignoring: step.allowInteraction,
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Stack(
              children: [
                // Spotlight cutout (if target provided)
                if (step.targetKey != null)
                  _buildSpotlight(step.targetKey!),

                // Instruction card
                SafeArea(
                  child: Align(
                    alignment: step.instructionAlignment,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildInstructionCard(step),
                    ),
                  ),
                ),

                // Progress indicator
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildProgressIndicator(),
                ),

                // Next button (if step completed)
                if (_canProceed)
                  Positioned(
                    bottom: 32,
                    left: 24,
                    right: 24,
                    child: _buildNextButton(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlight(GlobalKey targetKey) {
    // TODO: Implement spotlight cutout using CustomPainter
    // For now, just a placeholder
    return const SizedBox.shrink();
  }

  Widget _buildInstructionCard(TutorialStep step) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VibrantColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: VibrantColors.strongShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          if (step.icon != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: VibrantColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                step.icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          if (step.icon != null) const SizedBox(height: 16),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: VibrantColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: VibrantColors.textSecondary,
            ),
          ),

          // Gesture hint (animated)
          if (step.gestureHint != null) ...[
            const SizedBox(height: 16),
            _buildGestureHint(step.gestureHint!),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildGestureHint(GestureHint hint) {
    IconData icon;
    String text;

    switch (hint) {
      case GestureHint.tap:
        icon = Icons.touch_app;
        text = 'Tap to continue';
        break;
      case GestureHint.swipeLeft:
        icon = Icons.swipe_left;
        text = 'Swipe left';
        break;
      case GestureHint.swipeRight:
        icon = Icons.swipe_right;
        text = 'Swipe right';
        break;
      case GestureHint.swipeUp:
        icon = Icons.swipe_up;
        text = 'Swipe up';
        break;
      case GestureHint.drag:
        icon = Icons.pan_tool;
        text = 'Drag and drop';
        break;
    }

    return Row(
      children: [
        Icon(icon, color: VibrantColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: VibrantColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: const Duration(milliseconds: 500))
        .fadeOut(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 500),
        );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentStep + 1) / widget.steps.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: VibrantColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_currentStep + 1}/${widget.steps.length}',
            style: const TextStyle(
              color: VibrantColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: VibrantColors.textHint.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(VibrantColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _completeStep,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: VibrantColors.successGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: VibrantColors.glowShadow(VibrantColors.success),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.2, end: 0);
  }
}

/// Tutorial step definition
class TutorialStep {
  final String title;
  final String description;
  final IconData? icon;
  final GestureHint? gestureHint;
  final Alignment instructionAlignment;
  final GlobalKey? targetKey; // Key of widget to spotlight
  final bool allowInteraction; // Allow user to interact with content
  final Widget Function(BuildContext, VoidCallback) content;

  TutorialStep({
    required this.title,
    required this.description,
    required this.content,
    this.icon,
    this.gestureHint,
    this.instructionAlignment = Alignment.bottomCenter,
    this.targetKey,
    this.allowInteraction = true,
  });
}

enum GestureHint {
  tap,
  swipeLeft,
  swipeRight,
  swipeUp,
  drag,
}

/// Contextual tutorial - shows hints during actual use
/// Like Temple Run 2: "Swipe left!" appears just before obstacle
class ContextualHint extends StatefulWidget {
  const ContextualHint({
    super.key,
    required this.message,
    required this.gesture,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  final String message;
  final GestureHint gesture;
  final Duration duration;
  final VoidCallback? onDismiss;

  @override
  State<ContextualHint> createState() => _ContextualHintState();
}

class _ContextualHintState extends State<ContextualHint> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;

    switch (widget.gesture) {
      case GestureHint.tap:
        icon = Icons.touch_app;
        break;
      case GestureHint.swipeLeft:
        icon = Icons.swipe_left;
        break;
      case GestureHint.swipeRight:
        icon = Icons.swipe_right;
        break;
      case GestureHint.swipeUp:
        icon = Icons.swipe_up;
        break;
      case GestureHint.drag:
        icon = Icons.pan_tool;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: VibrantColors.primaryGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: VibrantColors.glowShadow(VibrantColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            widget.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.8, 0.8))
        .then()
        .shimmer(
          duration: const Duration(milliseconds: 1000),
          color: Colors.white.withValues(alpha: 0.5),
        );
  }
}

/// Progressive tutorial manager - reveals features gradually
class ProgressiveTutorialManager {
  static const String _completedKey = 'tutorial_completed_steps';

  final Set<String> _completedSteps = {};
  bool _loaded = false;

  /// Load completed steps
  Future<void> load() async {
    // TODO: Load from SharedPreferences
    _loaded = true;
  }

  /// Check if step is completed
  bool isCompleted(String stepId) {
    return _completedSteps.contains(stepId);
  }

  /// Mark step as completed
  Future<void> complete(String stepId) async {
    _completedSteps.add(stepId);
    // TODO: Save to SharedPreferences
  }

  /// Get next step to show
  String? getNextStep(List<String> allStepIds) {
    for (final stepId in allStepIds) {
      if (!isCompleted(stepId)) {
        return stepId;
      }
    }
    return null;
  }

  /// Reset all
  Future<void> reset() async {
    _completedSteps.clear();
    // TODO: Clear SharedPreferences
  }
}
