import "package:flutter/material.dart";

import '../../models/lesson.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../tts_play_button.dart';
import 'exercise_control.dart';

class AlphabetExercise extends StatefulWidget {
  const AlphabetExercise({
    super.key,
    required this.task,
    required this.ttsEnabled,
    required this.handle,
  });

  final AlphabetTask task;
  final bool ttsEnabled;
  final LessonExerciseHandle handle;

  @override
  State<AlphabetExercise> createState() => _AlphabetExerciseState();
}

class _AlphabetExerciseState extends State<AlphabetExercise> {
  String? _chosen;
  bool _checked = false;
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _chosen != null,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant AlphabetExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _chosen != null,
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
    if (_chosen == null) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Select a letter first.',
      );
    }
    final correct = _chosen == widget.task.answer;
    setState(() {
      _checked = true;
      _correct = correct;
    });
    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'Correct!' : 'Try again.',
    );
  }

  void _reset() {
    setState(() {
      _chosen = null;
      _checked = false;
      _correct = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Prompt with TTS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                task.prompt,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.ttsEnabled) ...[
              SizedBox(width: AppSpacing.space8),
              TtsPlayButton(
                text: task.answer,
                enabled: true,
                semanticLabel: 'Play target letter',
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.space32),

        // Letter options in grid
        Center(
          child: Wrap(
            spacing: AppSpacing.space12,
            runSpacing: AppSpacing.space12,
            alignment: WrapAlignment.center,
            children: [
              for (final option in task.options)
                _LetterOption(
                  letter: option,
                  isSelected: option == _chosen,
                  isChecked: _checked,
                  isCorrect: _correct,
                  onTap: () => setState(() {
                    _chosen = option;
                    _checked = false;
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LetterOption extends StatefulWidget {
  const _LetterOption({
    required this.letter,
    required this.isSelected,
    required this.isChecked,
    required this.isCorrect,
    required this.onTap,
  });

  final String letter;
  final bool isSelected;
  final bool isChecked;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  State<_LetterOption> createState() => _LetterOptionState();
}

class _LetterOptionState extends State<_LetterOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDuration.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.smooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typography = ReaderTheme.typographyOf(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (widget.isSelected && widget.isChecked) {
      if (widget.isCorrect) {
        backgroundColor = isDark
            ? AppColors.successContainerDark
            : AppColors.successContainerLight;
        borderColor = isDark
            ? AppColors.successDark
            : AppColors.successLight;
        textColor = isDark
            ? AppColors.successDark
            : AppColors.successLight;
      } else {
        backgroundColor = colors.errorContainer;
        borderColor = colors.error;
        textColor = colors.error;
      }
    } else if (widget.isSelected) {
      backgroundColor = colors.primaryContainer;
      borderColor = colors.primary;
      textColor = colors.primary;
    } else {
      backgroundColor = colors.surface;
      borderColor = colors.outlineVariant;
      textColor = colors.onSurface;
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppDuration.normal,
          curve: AppCurves.smooth,
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.2),
                      blurRadius: AppElevation.medium,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.letter,
                  style: typography.greekDisplay.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.isSelected && widget.isChecked)
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: AppDuration.normal,
                    curve: AppCurves.bounce,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: widget.isCorrect
                            ? (isDark ? AppColors.successDark : AppColors.successLight)
                            : colors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isCorrect ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
