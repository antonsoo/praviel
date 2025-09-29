import "package:flutter/material.dart";

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';
import '../../theme/app_theme.dart';
import '../surface.dart';
import '../tts_play_button.dart';
import 'exercise_control.dart';

class TranslateExercise extends StatefulWidget {
  const TranslateExercise({
    super.key,
    required this.task,
    required this.ttsEnabled,
    required this.handle,
  });

  final TranslateTask task;
  final bool ttsEnabled;
  final LessonExerciseHandle handle;

  @override
  State<TranslateExercise> createState() => _TranslateExerciseState();
}

class _TranslateExerciseState extends State<TranslateExercise> {
  late final TextEditingController _controller;
  bool _showSample = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    widget.handle.attach(
      canCheck: () => _controller.text.trim().isNotEmpty,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant TranslateExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _controller.text.trim().isNotEmpty,
        check: _check,
        reset: _reset,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Write a draft translation first.',
      );
    }
    setState(() {
      _checked = true;
      if (widget.task.sampleSolution != null) {
        _showSample = true;
      }
    });
    return const LessonCheckFeedback(
      correct: true,
      message: 'Nice work—compare with the sample below.',
    );
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _showSample = false;
      _checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final colors = theme.colorScheme;
    final task = widget.task;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10nLessons.translateToEn,
          style: typography.uiTitle.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: spacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.text,
                style: typography.greekBody.copyWith(color: colors.onSurface),
              ),
            ),
            if (widget.ttsEnabled) ...[
              SizedBox(width: spacing.sm),
              TtsPlayButton(
                text: task.text,
                enabled: true,
                semanticLabel: 'Play translation prompt',
              ),
            ],
          ],
        ),
        SizedBox(height: spacing.md),
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 6,
          style: typography.uiBody,
          decoration: const InputDecoration(hintText: L10nLessons.writeNatural),
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            TextButton(onPressed: _reset, child: const Text('Clear')),
            const Spacer(),
            if (task.sampleSolution != null)
              TextButton(
                onPressed: () => setState(() => _showSample = !_showSample),
                child: Text(
                  _showSample ? 'Hide sample solution' : 'See one solution',
                ),
              ),
          ],
        ),
        if (_checked)
          Padding(
            padding: EdgeInsets.only(top: spacing.xs),
            child: Text(
              'Reflect on tone and accuracy, then iterate as needed.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.primary,
              ),
            ),
          ),
        if (_showSample && task.sampleSolution != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.sm),
            child: Surface(
              padding: EdgeInsets.all(spacing.sm),
              backgroundColor: colors.surfaceContainerHighest,
              child: Text(
                task.sampleSolution!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}
