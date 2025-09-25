import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import 'exercise_control.dart';

class AlphabetExercise extends StatefulWidget {
  const AlphabetExercise({super.key, required this.task, required this.handle});

  final AlphabetTask task;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.prompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in task.options)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                child: ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  label: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: option == _chosen,
                  onSelected: (_) => setState(() {
                    _chosen = option;
                    _checked = false;
                  }),
                  avatar: option == _chosen && _checked
                      ? Icon(
                          option == task.answer ? Icons.check : Icons.close,
                          color: option == task.answer
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onError,
                        )
                      : null,
                ),
              ),
          ],
        ),
        if (_chosen != null && _checked) ...[
          const SizedBox(height: 12),
          Text(
            _correct ? 'Correct!' : 'Try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _correct
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
