import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class VibrantContextMatchExercise extends StatefulWidget {
  const VibrantContextMatchExercise({super.key, required this.task, required this.handle});
  final ContextMatchTask task;
  final LessonExerciseHandle handle;
  @override
  State<VibrantContextMatchExercise> createState() => _VibrantContextMatchExerciseState();
}

class _VibrantContextMatchExerciseState extends State<VibrantContextMatchExercise> {
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
    return LessonCheckFeedback(correct: correct, message: correct ? 'Perfect match!' : 'Not quite!');
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
          Text('Choose the word that fits', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(widget.task.sentence, style: theme.textTheme.headlineSmall),
          if (widget.task.contextHint != null) ...[
            const SizedBox(height: 8),
            Text(widget.task.contextHint!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 24),
          ...widget.task.options.map((opt) {
            final isSelected = _selected == opt;
            final isCorrect = _checked && opt == widget.task.answer;
            final isWrong = _checked && isSelected && !isCorrect;
            return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: ElevatedButton(onPressed: _checked ? null : () => setState(() => _selected = opt), style: ElevatedButton.styleFrom(backgroundColor: isCorrect ? Colors.green : isWrong ? Colors.red : isSelected ? theme.colorScheme.primary : theme.colorScheme.surface), child: Text(opt)));
          }),
        ],
      ),
    );
  }
}
