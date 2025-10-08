import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Enhanced alphabet exercise with pronunciation and visual learning
class VibrantAlphabetExercise extends StatefulWidget {
  const VibrantAlphabetExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final AlphabetTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantAlphabetExercise> createState() =>
      _VibrantAlphabetExerciseState();
}

class _VibrantAlphabetExerciseState extends State<VibrantAlphabetExercise> {
  String? _selectedAnswer;
  bool _checked = false;
  bool? _correct;
  bool _showFlashcard = false;
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
  void didUpdateWidget(covariant VibrantAlphabetExercise oldWidget) {
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
        message: 'Select an answer',
      );
    }

    final expected = widget.task.answer.toLowerCase();
    final got = _selectedAnswer!.toLowerCase();
    final correct = got == expected;

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
          ? 'Perfect! You know this letter.'
          : 'Expected: ${widget.task.answer}',
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
      _showFlashcard = false;
      _sparkles.clear();
    });
    widget.handle.notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use provided options or generate letter choices
    final choices =
        widget.task.options.isNotEmpty
              ? widget.task.options
              : [widget.task.answer, 'β', 'γ', 'δ']
          ..shuffle();

    return Stack(
      children: [
        ErrorShakeWrapper(
          key: _shakeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
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
                        'Identify the letter',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Flashcard toggle
                    IconButton(
                      onPressed: () {
                        HapticService.light();
                        SoundService.instance.tap();
                        setState(() {
                          _showFlashcard = !_showFlashcard;
                        });
                      },
                      icon: Icon(
                        _showFlashcard
                            ? Icons.flip_to_back_rounded
                            : Icons.flip_to_front_rounded,
                      ),
                      tooltip: 'Toggle flashcard view',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Letter display or flashcard
              if (!_showFlashcard)
                SlideInFromBottom(
                  delay: const Duration(milliseconds: 200),
                  child: _buildLetterDisplay(theme, colorScheme),
                )
              else
                ScaleIn(child: _buildFlashcard(theme, colorScheme)),

              const SizedBox(height: VibrantSpacing.xl),

              // Question
              SlideInFromBottom(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  widget.task.prompt,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Letter choices
              SlideInFromBottom(
                delay: const Duration(milliseconds: 400),
                child: Wrap(
                  spacing: VibrantSpacing.md,
                  runSpacing: VibrantSpacing.md,
                  alignment: WrapAlignment.center,
                  children: choices
                      .map(
                        (letter) =>
                            _buildLetterChoice(letter, theme, colorScheme),
                      )
                      .toList(),
                ),
              ),

              // Feedback
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.xl),
                ScaleIn(
                  child: InlineFeedback(
                    isCorrect: _correct!,
                    message: _correct!
                        ? 'Correct! This is the letter ${widget.task.answer}'
                        : 'The correct answer is ${widget.task.answer}',
                  ),
                ),
                const SizedBox(height: VibrantSpacing.md),
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: VibrantSpacing.sm),
                      Expanded(
                        child: Text(
                          'Pronunciation: "${widget.task.answer}" sounds like...',
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
          ),
        ),
        ..._sparkles,
      ],
    );
  }

  Widget _buildLetterDisplay(ThemeData theme, ColorScheme colorScheme) {
    return PulseCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primaryContainer,
          colorScheme.surfaceContainerHigh,
        ],
      ),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Text(
            widget.task.answer,
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 120,
              fontWeight: FontWeight.w300,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcard(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedSwitcher(
      duration: VibrantDuration.moderate,
      child: Container(
        key: ValueKey(_showFlashcard),
        height: 200,
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        decoration: BoxDecoration(
          gradient: VibrantTheme.heroGradient,
          borderRadius: BorderRadius.circular(VibrantRadius.xl),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.task.answer,
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 80,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.lg,
                vertical: VibrantSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: VibrantSpacing.xs),
                  Text(
                    'Tap to hear',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterChoice(
    String letter,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedAnswer == letter;
    final isDisabled = _checked && !isSelected;

    return AnimatedScaleButton(
      onTap: _checked
          ? () {}
          : () {
              HapticService.light();
              SoundService.instance.tap();
              setState(() {
                _selectedAnswer = letter;
              });
              widget.handle.notify();
            },
      child: Container(
        width: 80,
        height: 80,
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
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
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
        child: Center(
          child: Text(
            letter,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w600,
              color: isSelected && !_checked
                  ? Colors.white
                  : (isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
