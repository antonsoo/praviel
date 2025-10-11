import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class VibrantDeclensionExercise extends StatefulWidget {
  const VibrantDeclensionExercise({super.key, required this.task, required this.handle});
  final DeclensionTask task;
  final LessonExerciseHandle handle;
  @override
  State<VibrantDeclensionExercise> createState() => _VibrantDeclensionExerciseState();
}

class _VibrantDeclensionExerciseState extends State<VibrantDeclensionExercise> {
  final TextEditingController _controller = TextEditingController();
  bool _checked = false;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    widget.handle.attach(canCheck: () => _controller.text.trim().isNotEmpty, check: _check, reset: _reset);
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final answer = _controller.text.trim();
    final correct = answer == widget.task.answer;
    setState(() { _checked = true; _correct = correct; });
    return LessonCheckFeedback(correct: correct, message: correct ? 'Perfect!' : 'Correct: ${widget.task.answer}');
  }

  void _reset() => setState(() { _controller.clear(); _checked = false; _correct = null; });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Decline the word', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Word: ${widget.task.word}', style: theme.textTheme.titleMedium),
            Text('Meaning: ${widget.task.wordMeaning}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Case: ${widget.task.caseType}', style: theme.textTheme.bodyMedium),
            Text('Number: ${widget.task.number}', style: theme.textTheme.bodyMedium),
          ]))),
          const SizedBox(height: 24),
          TextField(controller: _controller, enabled: !_checked, decoration: InputDecoration(labelText: 'Your answer', border: const OutlineInputBorder(), suffixIcon: _checked ? Icon(_correct == true ? Icons.check_circle : Icons.cancel, color: _correct == true ? Colors.green : Colors.red) : null)),
        ],
      ),
    );
  }
}
