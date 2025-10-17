import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Reading comprehension exercise with passage and multiple questions
class VibrantComprehensionExercise extends StatefulWidget {
  const VibrantComprehensionExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final ReadingComprehensionTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantComprehensionExercise> createState() =>
      _VibrantComprehensionExerciseState();
}

class _VibrantComprehensionExerciseState
    extends State<VibrantComprehensionExercise> {
  final Map<int, int?> _answers = {}; // question index -> selected answer index
  bool _checked = false;
  final Map<int, bool> _correctAnswers = {}; // question index -> correct?
  final GlobalKey<ErrorShakeWrapperState> _shakeKey = GlobalKey();
  final List<Widget> _sparkles = [];
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _answers.length == widget.task.questions.length &&
          _answers.values.every((v) => v != null),
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantComprehensionExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _answers.length == widget.task.questions.length &&
            _answers.values.every((v) => v != null),
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
    if (_answers.length != widget.task.questions.length ||
        _answers.values.any((v) => v == null)) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Please answer all questions',
      );
    }

    // Check all answers
    bool allCorrect = true;
    int correctCount = 0;
    for (int i = 0; i < widget.task.questions.length; i++) {
      final selectedIndex = _answers[i]!;
      final correctIndex = widget.task.questions[i].answerIndex;
      final isCorrect = selectedIndex == correctIndex;
      _correctAnswers[i] = isCorrect;
      if (isCorrect) {
        correctCount++;
      } else {
        allCorrect = false;
      }
    }

    setState(() {
      _checked = true;
    });

    if (!allCorrect) {
      _shakeKey.currentState?.shake();
      SoundService.instance.error();
    } else {
      HapticService.success();
      SoundService.instance.success();
      _showSparkles();
    }

    final message = allCorrect
        ? 'Perfect! All answers correct!'
        : '$correctCount/${widget.task.questions.length} correct. Review the passage and try again.';

    return LessonCheckFeedback(
      correct: allCorrect,
      message: message,
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
          particleCount: 24,
          size: 150,
        ),
      ),
    );
    setState(() => _sparkles.add(sparkle));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _sparkles.clear());
    });
  }

  void _reset() {
    setState(() {
      _answers.clear();
      _correctAnswers.clear();
      _checked = false;
      _sparkles.clear();
      _showTranslation = false;
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
          child: SingleChildScrollView(
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
                          borderRadius:
                              BorderRadius.circular(VibrantRadius.sm),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.md),
                      Expanded(
                        child: Text(
                          'Reading Comprehension',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.task.ref != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.sm,
                            vertical: VibrantSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius:
                                BorderRadius.circular(VibrantRadius.sm),
                          ),
                          child: Text(
                            widget.task.ref!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: VibrantSpacing.xl),

                // Passage
                SlideInFromBottom(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.passage,
                          style: theme.textTheme.titleMedium?.copyWith(
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.task.translation != null) ...[
                          const SizedBox(height: VibrantSpacing.md),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showTranslation = !_showTranslation;
                              });
                              HapticService.light();
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _showTranslation
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: VibrantSpacing.xs),
                                Text(
                                  _showTranslation
                                      ? 'Hide translation'
                                      : 'Show translation',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showTranslation) ...[
                            const SizedBox(height: VibrantSpacing.sm),
                            Text(
                              widget.task.translation!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: VibrantSpacing.xl * 1.5),

                // Questions
                ...widget.task.questions.asMap().entries.map((entry) {
                  final questionIndex = entry.key;
                  final question = entry.value;
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: VibrantSpacing.xl),
                    child: SlideInFromBottom(
                      delay: Duration(
                          milliseconds: (400 + (questionIndex * 100)).toInt()),
                      child: _buildQuestion(
                        context,
                        questionIndex: questionIndex,
                        question: question,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                  );
                }),

                // Overall feedback
                if (_checked) ...[
                  const SizedBox(height: VibrantSpacing.lg),
                  ScaleIn(
                    child: InlineFeedback(
                      isCorrect: _correctAnswers.values.every((v) => v),
                      message: _correctAnswers.values.every((v) => v)
                          ? 'Excellent comprehension! You understood the passage perfectly.'
                          : 'Review the incorrect answers and read the passage again.',
                    ),
                  ),
                ],

                const SizedBox(height: VibrantSpacing.xxl),
              ],
            ),
          ),
        ),
        ..._sparkles,
      ],
    );
  }

  Widget _buildQuestion(
    BuildContext context, {
    required int questionIndex,
    required ComprehensionQuestion question,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          'Question ${questionIndex + 1}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Text(
          question.question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),

        // Answer options
        ...question.options.asMap().entries.map((optEntry) {
          final optionIndex = optEntry.key;
          final option = optEntry.value;
          final isSelected = _answers[questionIndex] == optionIndex;
          final isCorrect = optionIndex == question.answerIndex;
          final isDisabled = _checked && !isSelected;
          final showAsCorrect = _checked && isCorrect;
          final showAsWrong = _checked && isSelected && !isCorrect;

          return Padding(
            padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
            child: AnimatedScaleButton(
              onTap: _checked
                  ? () {}
                  : () {
                      HapticService.light();
                      SoundService.instance.tap();
                      setState(() {
                        _answers[questionIndex] = optionIndex;
                      });
                      widget.handle.notify();
                    },
              child: Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  gradient: isSelected && !_checked
                      ? VibrantTheme.heroGradient
                      : null,
                  color: isSelected
                      ? (_checked
                            ? (showAsWrong
                                  ? colorScheme.errorContainer
                                  : colorScheme.tertiaryContainer)
                            : null)
                      : (isDisabled
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surface),
                  borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  border: Border.all(
                    color: showAsCorrect
                        ? colorScheme.tertiary
                        : (showAsWrong
                              ? colorScheme.error
                              : (isSelected && !_checked
                                    ? Colors.transparent
                                    : colorScheme.outline)),
                    width: showAsCorrect || showAsWrong ? 2 : 1,
                  ),
                  boxShadow: isSelected && !_checked
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : VibrantShadow.sm(colorScheme),
                ),
                child: Row(
                  children: [
                    // Radio indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected && !_checked
                            ? Colors.white.withValues(alpha: 0.3)
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected && !_checked
                              ? Colors.white
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isSelected && !_checked
                                      ? Colors.white
                                      : colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    // Option text
                    Expanded(
                      child: Text(
                        option,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected && !_checked
                              ? Colors.white
                              : (isDisabled
                                    ? colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5)
                                    : colorScheme.onSurface),
                        ),
                      ),
                    ),
                    // Checkmark for correct answer
                    if (showAsCorrect)
                      Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.tertiary,
                        size: 24,
                      ),
                    if (showAsWrong)
                      Icon(
                        Icons.cancel_rounded,
                        color: colorScheme.error,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
