import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Grammar check exercise with interactive correct/incorrect buttons
class VibrantGrammarExercise extends StatefulWidget {
  const VibrantGrammarExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final GrammarTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantGrammarExercise> createState() => _VibrantGrammarExerciseState();
}

class _VibrantGrammarExerciseState extends State<VibrantGrammarExercise> {
  bool? _selectedAnswer;
  bool _checked = false;
  bool? _correct;
  final GlobalKey<ErrorShakeWrapperState> _shakeKey = GlobalKey();
  final List<Widget> _sparkles = [];

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _selectedAnswer != null,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantGrammarExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _selectedAnswer != null,
        check: _check,
        reset: _reset,
      );
    }
  }

  @override
  void dispose() {
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    if (_selectedAnswer == null) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Select Correct or Incorrect',
      );
    }

    final correct = _selectedAnswer == widget.task.isCorrect;

    setState(() {
      _checked = true;
      _correct = correct;
    });

    if (!correct) {
      _shakeKey.currentState?.shake();
      SoundService.instance.error();
    } else {
      HapticService.success();
      SoundService.instance.success();
      _showSparkles();
    }

    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Correct!'
          : 'The sentence is ${widget.task.isCorrect ? "correct" : "incorrect"}.',
    );
  }

  void _showSparkles() {
    final sparkle = Positioned(
      left: 0,
      right: 0,
      top: 200,
      child: Center(
        child: StarBurst(
          color: const Color(0xFFFBBF24),
          particleCount: 18,
          size: 130,
        ),
      ),
    );
    setState(() => _sparkles.add(sparkle));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _sparkles.clear());
    });
  }

  void _reset() {
    setState(() {
      _selectedAnswer = null;
      _checked = false;
      _correct = null;
      _sparkles.clear();
    });
    widget.handle.notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        ErrorShakeWrapper(
          key: _shakeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              ScaleIn(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: VibrantTheme.heroGradient,
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      ),
                      child: const Icon(
                        Icons.spellcheck_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: Text(
                        'Grammar Check',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VibrantSpacing.md),

              // Instructions
              SlideInFromBottom(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'Is this sentence grammatically correct?',
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: VibrantSpacing.lg),

              // Sentence display
              SlideInFromBottom(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Text(
                    widget.task.sentence,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'NotoSerif',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Correct/Incorrect buttons
              SlideInFromBottom(
                delay: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnswerButton(
                        context,
                        label: 'CORRECT',
                        value: true,
                        icon: Icons.check_circle_outline_rounded,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: _buildAnswerButton(
                        context,
                        label: 'INCORRECT',
                        value: false,
                        icon: Icons.cancel_outlined,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
              ),

              // Feedback and explanation
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.xl),
                ScaleIn(
                  child: InlineFeedback(
                    isCorrect: _correct!,
                    message: _correct!
                        ? 'Correct!'
                        : 'The sentence is ${widget.task.isCorrect ? "correct" : "incorrect"}',
                  ),
                ),
                if (widget.task.errorExplanation != null) ...[
                  const SizedBox(height: VibrantSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: VibrantSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.task.errorExplanation!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        ..._sparkles,
      ],
    );
  }

  Widget _buildAnswerButton(
    BuildContext context, {
    required String label,
    required bool value,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedAnswer == value;
    final isDisabled = _checked && !isSelected;

    return AnimatedScaleButton(
      onTap: _checked
          ? () {}
          : () {
              HapticService.light();
              SoundService.instance.tap();
              setState(() {
                _selectedAnswer = value;
              });
              widget.handle.notify();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: VibrantSpacing.lg,
          horizontal: VibrantSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: isSelected && !_checked ? VibrantTheme.heroGradient : null,
          color: isSelected
              ? (_checked
                    ? (_correct == true
                          ? colorScheme.tertiaryContainer
                          : colorScheme.errorContainer)
                    : null)
              : (isDisabled
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface),
          borderRadius: BorderRadius.circular(VibrantRadius.md),
          border: Border.all(
            color: isSelected
                ? (_checked
                      ? (_correct == true
                            ? colorScheme.tertiary
                            : colorScheme.error)
                      : Colors.transparent)
                : colorScheme.outline,
            width: 2,
          ),
          boxShadow: isSelected && !_checked
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : VibrantShadow.sm(colorScheme),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected && !_checked
                  ? Colors.white
                  : (isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : colorScheme.onSurface),
            ),
            const SizedBox(height: VibrantSpacing.xs),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected && !_checked
                    ? Colors.white
                    : (isDisabled
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                          : colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
