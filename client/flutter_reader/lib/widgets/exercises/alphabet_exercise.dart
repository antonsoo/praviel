import 'package:flutter/material.dart';

import '../../models/lesson.dart';

class AlphabetExercise extends StatefulWidget {
  const AlphabetExercise({super.key, required this.task});

  final AlphabetTask task;

  @override
  State<AlphabetExercise> createState() => _AlphabetExerciseState();
}

class _AlphabetExerciseState extends State<AlphabetExercise> {
  String? _chosen;

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
                  onSelected: (_) => setState(() => _chosen = option),
                  avatar: option == _chosen
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
        if (_chosen != null) ...[
          const SizedBox(height: 12),
          Text(
            _chosen == task.answer ? 'Correct!' : 'Try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _chosen == task.answer
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
