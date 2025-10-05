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
    widget.handle.notify();
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
                  onTap: () {
                    setState(() {
                      _chosen = option;
                      _checked = false;
                    });
                    widget.handle.notify();
                  },
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
    _controller = AnimationController(duration: AppDuration.fast, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.smooth));
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

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Gradient? gradient;
    List<BoxShadow> shadows = [];

    if (widget.isSelected && widget.isChecked) {
      if (widget.isCorrect) {
        backgroundColor = colors.successContainer;
        borderColor = colors.success;
        textColor = colors.success;
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.success.withValues(alpha: 0.2),
            colors.success.withValues(alpha: 0.08),
          ],
        );
        shadows = [
          BoxShadow(
            color: colors.success.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colors.success.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ];
      } else {
        backgroundColor = colors.errorContainer;
        borderColor = colors.error;
        textColor = colors.error;
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.error.withValues(alpha: 0.2),
            colors.error.withValues(alpha: 0.08),
          ],
        );
        shadows = [
          BoxShadow(
            color: colors.error.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      }
    } else if (widget.isSelected) {
      backgroundColor = colors.primaryContainer;
      borderColor = colors.primary;
      textColor = colors.primary;
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primary.withValues(alpha: 0.18),
          colors.primary.withValues(alpha: 0.06),
        ],
      );
      shadows = [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];
    } else {
      backgroundColor = colors.surface;
      borderColor = colors.outlineVariant;
      textColor = colors.onSurface;
      shadows = [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.02),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
    }

    // Responsive sizing: 88px on desktop, 72px on mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSize = screenWidth < 360
        ? 64.0
        : (screenWidth < 600 ? 72.0 : 88.0);
    final fontSize = screenWidth < 360
        ? 36.0
        : (screenWidth < 600 ? 42.0 : 48.0);

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
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? backgroundColor : null,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: shadows,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.letter,
                  style: typography.greekDisplay.copyWith(
                    fontSize: fontSize,
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
                        color: widget.isCorrect ? colors.success : colors.error,
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
