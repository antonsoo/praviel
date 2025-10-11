import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class VibrantDictationExercise extends StatefulWidget {
  const VibrantDictationExercise({super.key, required this.task, required this.handle});
  final DictationTask task;
  final LessonExerciseHandle handle;
  @override
  State<VibrantDictationExercise> createState() => _VibrantDictationExerciseState();
}

class _VibrantDictationExerciseState extends State<VibrantDictationExercise> {
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
    final correct = _controller.text.trim() == widget.task.targetText;
    setState(() { _checked = true; _correct = correct; });
    return LessonCheckFeedback(correct: correct, message: correct ? 'Perfect spelling!' : 'Correct: ${widget.task.targetText}');
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
          Text('Write what you hear', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          if (widget.task.hint != null) Text('Hint: ${widget.task.hint}', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 24),
          TextField(controller: _controller, enabled: !_checked, decoration: InputDecoration(labelText: 'Type here', border: const OutlineInputBorder(), suffixIcon: _checked ? Icon(_correct == true ? Icons.check_circle : Icons.cancel, color: _correct == true ? Colors.green : Colors.red) : null)),
        ],
      ),
    );
  }
}
