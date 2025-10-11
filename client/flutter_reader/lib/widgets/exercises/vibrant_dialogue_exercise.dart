import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class VibrantDialogueExercise extends StatefulWidget {
  const VibrantDialogueExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final DialogueTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantDialogueExercise> createState() => _VibrantDialogueExerciseState();
}

class _VibrantDialogueExerciseState extends State<VibrantDialogueExercise> {
  String? _selectedAnswer;
  bool _checked = false;

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
  void dispose() {
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    if (_selectedAnswer == null) {
      return const LessonCheckFeedback(correct: null, message: 'Select an answer');
    }

    final correct = _selectedAnswer == widget.task.answer;
    setState(() {
      _checked = true;
    });

    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'Perfect dialogue!' : 'Not quite. Try again!',
    );
  }

  void _reset() {
    setState(() {
      _selectedAnswer = null;
      _checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Complete the dialogue', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          ...widget.task.lines.asMap().entries.map((entry) {
            final idx = entry.key;
            final line = entry.value;
            final isMissing = idx == widget.task.missingIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${line.speaker}:',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isMissing
                        ? Text('___', style: theme.textTheme.bodyLarge)
                        : Text(line.text, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          ...widget.task.options.map((option) {
            final isSelected = _selectedAnswer == option;
            final isCorrect = _checked && option == widget.task.answer;
            final isWrong = _checked && isSelected && !isCorrect;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: OutlinedButton(
                onPressed: _checked ? null : () => setState(() => _selectedAnswer = option),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isCorrect
                      ? Colors.green.withValues(alpha: 0.1)
                      : isWrong
                          ? Colors.red.withValues(alpha: 0.1)
                          : isSelected
                              ? theme.colorScheme.primaryContainer
                              : null,
                  side: BorderSide(
                    color: isCorrect
                        ? Colors.green
                        : isWrong
                            ? Colors.red
                            : isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(option),
              ),
            );
          }),
        ],
      ),
    );
  }
}
