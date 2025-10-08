import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import '../effects/particle_effects.dart';
import 'exercise_control.dart';

/// Enhanced cloze exercise with drag-and-drop word chips
class VibrantClozeExercise extends StatefulWidget {
  const VibrantClozeExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final ClozeTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantClozeExercise> createState() => _VibrantClozeExerciseState();
}

class _VibrantClozeExerciseState extends State<VibrantClozeExercise> {
  String? _selectedAnswer;
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
  void didUpdateWidget(covariant VibrantClozeExercise oldWidget) {
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

    final blanks = widget.task.blanks;
    if (blanks.isEmpty) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'No blanks to check',
      );
    }

    final expected = blanks.first.surface.trim().toLowerCase();
    final got = _selectedAnswer!.toLowerCase();
    final correct = got == expected;

    setState(() {
      _checked = true;
      _correct = correct;
    });

    if (!correct) {
      _shakeKey.currentState?.shake();
      HapticService.error();
      SoundService.instance.error();
    } else {
      HapticService.success();
      SoundService.instance.success();

      // Show sparkles on correct answer
      _showSparkles();
    }

    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Perfect! That\'s the right word.'
          : 'Expected: ${blanks.first.surface}',
    );
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

  void _showSparkles() {
    // Add sparkle burst at center
    final sparkle = Positioned(
      left: 0,
      right: 0,
      top: 100,
      child: Center(
        child: StarBurst(
          color: const Color(0xFFFBBF24),
          particleCount: 12,
          size: 100,
        ),
      ),
    );

    setState(() {
      _sparkles.add(sparkle);
    });

    // Remove after animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _sparkles.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get word choices (in real app would come from backend)
    final correctWord = widget.task.blanks.isNotEmpty
        ? widget.task.blanks.first.surface
        : '';
    final wordChoices = [
      correctWord,
      'θεά',
      'μῆνιν',
      'Πηληϊάδεω',
    ]..shuffle(); // Would get distractors from API

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
                    Icons.text_fields_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    'Fill in the blank',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Cloze text with blank
          SlideInFromBottom(
            delay: const Duration(milliseconds: 200),
            child: PulseCard(
              color: colorScheme.surfaceContainerLow,
              child: _buildClozeText(theme, colorScheme),
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Word choices
          SlideInFromBottom(
            delay: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to select the correct word:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.md),
                Wrap(
                  spacing: VibrantSpacing.md,
                  runSpacing: VibrantSpacing.md,
                  children: wordChoices
                      .map((word) => _buildWordChip(word, theme, colorScheme))
                      .toList(),
                ),
              ],
            ),
          ),

          // Feedback
          if (_checked && _correct != null) ...[
            const SizedBox(height: VibrantSpacing.xl),
            ScaleIn(
              child: InlineFeedback(
                isCorrect: _correct!,
                message: _correct!
                    ? 'Excellent! You chose the right word.'
                    : 'Not quite. The correct word is "$correctWord"',
              ),
            ),
            ],
          ],
        ),
      ),

      // Sparkles overlay
      ..._sparkles,
    ],
  );
}

  Widget _buildClozeText(ThemeData theme, ColorScheme colorScheme) {
    final parts = widget.task.text.split('___');
    final before = parts.isNotEmpty ? parts[0] : '';
    final after = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 2.0,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
            children: [
              TextSpan(text: before),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.md,
                    vertical: VibrantSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedAnswer != null
                        ? (_checked
                            ? (_correct == true
                                ? colorScheme.tertiaryContainer
                                : colorScheme.errorContainer)
                            : colorScheme.primaryContainer)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    border: Border.all(
                      color: _selectedAnswer != null
                          ? (_checked
                              ? (_correct == true
                                  ? colorScheme.tertiary
                                  : colorScheme.error)
                              : colorScheme.primary)
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _selectedAnswer ?? '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _selectedAnswer != null
                            ? (_checked
                                ? (_correct == true
                                    ? colorScheme.tertiary
                                    : colorScheme.error)
                                : colorScheme.primary)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              TextSpan(text: after),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWordChip(String word, ThemeData theme, ColorScheme colorScheme) {
    final isSelected = _selectedAnswer == word;
    final isDisabled = _checked && !isSelected;
    final correctWord = widget.task.blanks.isNotEmpty
        ? widget.task.blanks.first.surface
        : '';
    final isCorrectAnswer = word == correctWord;

    // Use FlipCard to reveal if this is the correct answer after checking
    if (_checked && isCorrectAnswer && !isSelected) {
      return FlipCard(
        isFlipped: true,
        front: _buildChipContainer(
          word,
          theme,
          colorScheme,
          isSelected,
          isDisabled,
          showAsCorrect: false,
        ),
        back: _buildChipContainer(
          word,
          theme,
          colorScheme,
          isSelected,
          isDisabled,
          showAsCorrect: true,
        ),
      );
    }

    return AnimatedScaleButton(
      onTap: _checked
          ? () {}
          : () {
              HapticService.light();
              SoundService.instance.tap();
              setState(() {
                _selectedAnswer = word;
              });
              widget.handle.notify();
            },
      child: _buildChipContainer(
        word,
        theme,
        colorScheme,
        isSelected,
        isDisabled,
        showAsCorrect: false,
      ),
    );
  }

  Widget _buildChipContainer(
    String word,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSelected,
    bool isDisabled, {
    bool showAsCorrect = false,
  }) {
    return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: (isSelected && !_checked) || showAsCorrect
              ? (showAsCorrect
                  ? VibrantTheme.successGradient
                  : VibrantTheme.heroGradient)
              : null,
          color: isSelected && !showAsCorrect
              ? (_checked
                  ? (_correct == true
                      ? colorScheme.tertiaryContainer
                      : colorScheme.errorContainer)
                  : null)
              : (isDisabled && !showAsCorrect
                  ? colorScheme.surfaceContainerHighest
                  : (showAsCorrect ? null : colorScheme.surface)),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAsCorrect)
              const Padding(
                padding: EdgeInsets.only(right: VibrantSpacing.xs),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            Text(
              word,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: (isSelected && !_checked) || showAsCorrect
                    ? Colors.white
                    : (isDisabled && !showAsCorrect
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : colorScheme.onSurface),
              ),
            ),
          ],
        ),
    );
  }
}
