import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/professional_theme.dart';
import 'exercise_control.dart';

/// PROFESSIONAL translation exercise - clean, focused
class ProTranslateExercise extends StatefulWidget {
  const ProTranslateExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final TranslateTask task;
  final LessonExerciseHandle handle;

  @override
  State<ProTranslateExercise> createState() => _ProTranslateExerciseState();
}

class _ProTranslateExerciseState extends State<ProTranslateExercise> {
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
  void didUpdateWidget(covariant ProTranslateExercise oldWidget) {
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
        message: 'Enter your translation',
      );
    }

    // For translate tasks, we accept the answer and show sample solution
    setState(() {
      _checked = true;
      _correct = true;
    });

    final hasSample = widget.task.sampleSolution != null &&
                     widget.task.sampleSolution!.isNotEmpty;

    return LessonCheckFeedback(
      correct: true,
      message: hasSample
          ? 'Nice work—compare with the sample below.'
          : 'Good translation!',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions
        Text(
          'Translate to English',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: ProSpacing.xxl),

        // Greek text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ProSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ProRadius.lg),
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          child: Text(
            widget.task.text,
            style: theme.textTheme.headlineSmall?.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: ProSpacing.xl),

        // Translation input
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'English translation',
            hintText: 'Enter your translation',
            helperText: _checked && widget.task.sampleSolution != null
                ? 'Sample: ${widget.task.sampleSolution}'
                : null,
            helperMaxLines: 2,
            suffixIcon: _checked && _correct != null
                ? Icon(
                    Icons.check,
                    color: colorScheme.tertiary,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProRadius.md),
            ),
          ),
          enabled: !_checked,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_controller.text.trim().isNotEmpty) {
              _check();
            }
          },
        ),

        // Show rubric after checking
        if (_checked && widget.task.rubric.isNotEmpty) ...[
          const SizedBox(height: ProSpacing.lg),
          Container(
            padding: const EdgeInsets.all(ProSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(ProRadius.md),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: ProSpacing.sm),
                Expanded(
                  child: Text(
                    widget.task.rubric,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
