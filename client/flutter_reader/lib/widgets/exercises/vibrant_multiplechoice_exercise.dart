import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Multiple choice exercise with interactive option selection
class VibrantMultipleChoiceExercise extends StatefulWidget {
  const VibrantMultipleChoiceExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final MultipleChoiceTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantMultipleChoiceExercise> createState() =>
      _VibrantMultipleChoiceExerciseState();
}

class _VibrantMultipleChoiceExerciseState extends State<VibrantMultipleChoiceExercise> {
  int? _selectedIndex;
  bool _checked = false;
  bool? _correct;
  final GlobalKey<ErrorShakeWrapperState> _shakeKey = GlobalKey();
  final List<Widget> _sparkles = [];

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _selectedIndex != null,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantMultipleChoiceExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _selectedIndex != null,
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
    if (_selectedIndex == null) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Select an answer',
      );
    }

    final correct = _selectedIndex == widget.task.answerIndex;

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
          : 'The correct answer is: ${widget.task.options[widget.task.answerIndex]}',
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
      _selectedIndex = null;
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
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: Text(
                        'Multiple Choice',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VibrantSpacing.lg),

              // Question
              SlideInFromBottom(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  widget.task.question,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Context (if present)
              if (widget.task.context != null) ...[
                const SizedBox(height: VibrantSpacing.sm),
                SlideInFromBottom(
                  delay: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    ),
                    child: Text(
                      widget.task.context!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: VibrantSpacing.xl),

              // Options
              ...widget.task.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                  child: SlideInFromBottom(
                    delay: Duration(milliseconds: 300 + (index * 50)),
                    child: _buildOptionButton(
                      context,
                      index: index,
                      option: option,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  ),
                );
              }),

              // Feedback
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.lg),
                ScaleIn(
                  child: InlineFeedback(
                    isCorrect: _correct!,
                    message: _correct!
                        ? 'Excellent!'
                        : 'The correct answer is: ${widget.task.options[widget.task.answerIndex]}',
                  ),
                ),
              ],
            ],
          ),
        ),
        ..._sparkles,
      ],
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required int index,
    required String option,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedIndex == index;
    final isCorrect = index == widget.task.answerIndex;
    final isDisabled = _checked && !isSelected;
    final letter = String.fromCharCode(65 + index); // A, B, C, D...

    return AnimatedScaleButton(
      onTap: _checked
          ? () {}
          : () {
              HapticService.light();
              SoundService.instance.tap();
              setState(() {
                _selectedIndex = index;
              });
              widget.handle.notify();
            },
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.md),
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
        child: Row(
          children: [
            // Letter badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected && !_checked
                    ? Colors.white.withValues(alpha: 0.3)
                    : colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected && !_checked
                        ? Colors.white
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            // Option text
            Expanded(
              child: Text(
                option,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected && !_checked
                      ? Colors.white
                      : (isDisabled
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                            : colorScheme.onSurface),
                ),
              ),
            ),
            // Checkmark for correct answer (after checked)
            if (_checked && isCorrect)
              Icon(
                Icons.check_circle_rounded,
                color: _correct == true
                    ? colorScheme.tertiary
                    : colorScheme.onTertiaryContainer,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
