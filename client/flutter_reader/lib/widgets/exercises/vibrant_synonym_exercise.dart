import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class VibrantSynonymExercise extends StatefulWidget {
  const VibrantSynonymExercise({super.key, required this.task, required this.handle});
  final SynonymTask task;
  final LessonExerciseHandle handle;
  @override
  State<VibrantSynonymExercise> createState() => _VibrantSynonymExerciseState();
}

class _VibrantSynonymExerciseState extends State<VibrantSynonymExercise> {
  String? _selected;
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
    final correct = _selected == widget.task.answer;
    setState(() { _checked = true; });
    return LessonCheckFeedback(correct: correct, message: correct ? 'Great!' : 'Try again!');
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
          Text('Find the ${widget.task.taskType}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Word: ${widget.task.word}', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          ...widget.task.options.map((opt) {
            final isSelected = _selected == opt;
            final isCorrect = _checked && opt == widget.task.answer;
            final isWrong = _checked && isSelected && !isCorrect;
            return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: OutlinedButton(onPressed: _checked ? null : () => setState(() => _selected = opt), style: OutlinedButton.styleFrom(backgroundColor: isCorrect ? Colors.green.withValues(alpha: 0.1) : isWrong ? Colors.red.withValues(alpha: 0.1) : isSelected ? theme.colorScheme.primaryContainer : null), child: Text(opt)));
          }),
        ],
      ),
    );
  }
}
