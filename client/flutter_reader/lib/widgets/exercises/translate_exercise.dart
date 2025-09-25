import 'package:flutter/material.dart';

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';
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
    final task = widget.task;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10nLessons.translateToEn, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                task.text,
                style: const TextStyle(fontSize: 20, height: 1.4),
              ),
            ),
            TtsPlayButton(
              text: task.text,
              enabled: widget.ttsEnabled,
              semanticLabel: 'Play translation prompt',
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: L10nLessons.writeNatural,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (task.sampleSolution != null)
          TextButton(
            onPressed: () => setState(() => _showSample = !_showSample),
            child: Text(
              _showSample ? 'Hide sample solution' : 'See one solution',
            ),
          ),
        if (_checked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Reflect on tone and accuracy, then iterate as needed.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (_showSample && task.sampleSolution != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(task.sampleSolution!),
          ),
      ],
    );
  }
}
