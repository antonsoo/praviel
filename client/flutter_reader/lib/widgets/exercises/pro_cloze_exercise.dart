import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/professional_theme.dart';
import 'exercise_control.dart';

/// PROFESSIONAL cloze exercise - clean input, clear feedback
/// No fancy animations - just clear, functional design
class ProClozeExercise extends StatefulWidget {
  const ProClozeExercise({super.key, required this.task, required this.handle});

  final ClozeTask task;
  final LessonExerciseHandle handle;

  @override
  State<ProClozeExercise> createState() => _ProClozeExerciseState();
}

class _ProClozeExerciseState extends State<ProClozeExercise> {
  late final TextEditingController _controller;
  bool _checked = false;
  bool? _correct;

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
  void didUpdateWidget(covariant ProClozeExercise oldWidget) {
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
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Enter your answer',
      );
    }

    // Get the first blank's expected answer
    final blanks = widget.task.blanks;
    if (blanks.isEmpty) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'No blanks to check',
      );
    }

    final expected = blanks.first.surface.trim().toLowerCase();
    final got = answer.toLowerCase();
    final correct = got == expected;

    setState(() {
      _checked = true;
      _correct = correct;
    });

    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'Correct!' : 'Expected: ${blanks.first.surface}',
    );
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _checked = false;
      _correct = null;
    });
    widget.handle.notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build text with blank
    final parts = widget.task.text.split('___');
    final before = parts.isNotEmpty ? parts[0] : '';
    final after = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions
        Text(
          'Fill in the blank',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: ProSpacing.xxl),

        // Cloze text
        Container(
          padding: const EdgeInsets.all(ProSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ProRadius.lg),
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                fontSize: 18,
              ),
              children: [
                TextSpan(text: before),
                WidgetSpan(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 100),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Text('     '), // Placeholder for blank
                  ),
                ),
                TextSpan(text: after),
              ],
            ),
          ),
        ),

        const SizedBox(height: ProSpacing.xl),

        // Input field
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Your answer',
            hintText: 'Enter the missing word',
            errorText:
                _checked && _correct == false && widget.task.blanks.isNotEmpty
                ? 'Expected: ${widget.task.blanks.first.surface}'
                : null,
            suffixIcon: _checked && _correct != null
                ? Icon(
                    _correct! ? Icons.check : Icons.close,
                    color: _correct! ? colorScheme.tertiary : colorScheme.error,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProRadius.md),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProRadius.md),
              borderSide: BorderSide(
                color: _checked && _correct != null
                    ? (_correct! ? colorScheme.tertiary : colorScheme.error)
                    : colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          enabled: !_checked,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_controller.text.trim().isNotEmpty) {
              _check();
            }
          },
        ),
      ],
    );
  }
}
