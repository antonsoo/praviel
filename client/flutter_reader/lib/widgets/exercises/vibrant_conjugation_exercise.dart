import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class VibrantConjugationExercise extends StatefulWidget {
  const VibrantConjugationExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final ConjugationTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantConjugationExercise> createState() => _VibrantConjugationExerciseState();
}

class _VibrantConjugationExerciseState extends State<VibrantConjugationExercise> {
  final TextEditingController _controller = TextEditingController();
  bool _checked = false;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _controller.text.trim().isNotEmpty,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      return const LessonCheckFeedback(correct: null, message: 'Enter your answer');
    }

    final correct = answer == widget.task.answer;
    setState(() {
      _checked = true;
      _correct = correct;
    });

    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'Excellent conjugation!' : 'Correct answer: ${widget.task.answer}',
    );
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _checked = false;
      _correct = null;
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
          Text('Conjugate the verb', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verb: ${widget.task.verbInfinitive}', style: theme.textTheme.titleMedium),
                  Text('Meaning: ${widget.task.verbMeaning}', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Person: ${widget.task.person}', style: theme.textTheme.bodyMedium),
                  Text('Tense: ${widget.task.tense}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            enabled: !_checked,
            decoration: InputDecoration(
              labelText: 'Your answer',
              border: const OutlineInputBorder(),
              suffixIcon: _checked
                  ? Icon(_correct == true ? Icons.check_circle : Icons.cancel, color: _correct == true ? Colors.green : Colors.red)
                  : null,
            ),
          ),
          if (_checked && _correct == false) ...[
            const SizedBox(height: 16),
            Text('Correct answer: ${widget.task.answer}', style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
