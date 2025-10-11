import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class VibrantEtymologyExercise extends StatefulWidget {
  const VibrantEtymologyExercise({super.key, required this.task, required this.handle});
  final EtymologyTask task;
  final LessonExerciseHandle handle;
  @override
  State<VibrantEtymologyExercise> createState() => _VibrantEtymologyExerciseState();
}

class _VibrantEtymologyExerciseState extends State<VibrantEtymologyExercise> {
  int? _selected;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    widget.handle.attach(canCheck: () => _selected != null, check: _check, reset: _reset);
  }

  @override
  void dispose() {
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final correct = _selected == widget.task.answerIndex;
    setState(() { _checked = true; });
    return LessonCheckFeedback(correct: correct, message: correct ? widget.task.explanation : 'Explanation: ${widget.task.explanation}');
  }

  void _reset() => setState(() { _selected = null; _checked = false; });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Etymology', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(widget.task.question, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Word: ${widget.task.word}', style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          ...widget.task.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = _selected == idx;
            final isCorrect = _checked && idx == widget.task.answerIndex;
            final isWrong = _checked && isSelected && !isCorrect;
            return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: OutlinedButton(onPressed: _checked ? null : () => setState(() => _selected = idx), style: OutlinedButton.styleFrom(backgroundColor: isCorrect ? Colors.green.withValues(alpha: 0.1) : isWrong ? Colors.red.withValues(alpha: 0.1) : isSelected ? theme.colorScheme.primaryContainer : null), child: Text(opt)));
          }),
        ],
      ),
    );
  }
}
