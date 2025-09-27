import "package:flutter/material.dart";

import '../../models/lesson.dart';
import '../../theme/app_theme.dart';
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
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                task.prompt,
                style: typography.uiTitle.copyWith(color: colors.onSurface),
              ),
            ),
            if (widget.ttsEnabled) ...[
              SizedBox(width: spacing.sm),
              TtsPlayButton(
                text: task.answer,
                enabled: true,
                semanticLabel: 'Play target letter',
              ),
            ],
          ],
        ),
        SizedBox(height: spacing.md),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (final option in task.options)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
                child: ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.xs,
                  ),
                  label: Text(
                    option,
                    style: typography.greekDisplay.copyWith(fontSize: 28),
                  ),
                  labelStyle: typography.greekDisplay,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: option == _chosen
                          ? colors.primary.withValues(alpha: 0.45)
                          : colors.outlineVariant,
                    ),
                  ),
                  backgroundColor: colors.surface,
                  selectedColor: colors.primaryContainer,
                  selected: option == _chosen,
                  avatar: option == _chosen && _checked
                      ? Icon(
                          _correct ? Icons.check_circle : Icons.cancel,
                          color: _correct ? colors.primary : colors.error,
                        )
                      : null,
                  onSelected: (_) => setState(() {
                    _chosen = option;
                    _checked = false;
                  }),
                ),
              ),
          ],
        ),
        if (_chosen != null && _checked) ...[
          SizedBox(height: spacing.sm),
          Text(
            _correct ? 'Correct!' : 'Try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _correct ? colors.primary : colors.error,
            ),
          ),
        ],
      ],
    );
  }
}
