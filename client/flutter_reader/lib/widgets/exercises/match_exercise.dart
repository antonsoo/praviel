import 'package:flutter/material.dart';

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';
import 'exercise_control.dart';

class MatchExercise extends StatefulWidget {
  const MatchExercise({super.key, required this.task, required this.handle});

  final MatchTask task;
  final LessonExerciseHandle handle;

  @override
  State<MatchExercise> createState() => _MatchExerciseState();
}

class _MatchExerciseState extends State<MatchExercise> {
  int? _leftSelection;
  late final List<String> _rightOptions;
  final Map<int, int> _pairs = <int, int>{};
  bool _checked = false;
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    _rightOptions = widget.task.pairs
        .map((pair) => pair.en)
        .toList(growable: false);
    _rightOptions.shuffle();
    widget.handle.attach(
      canCheck: () => _pairs.length == widget.task.pairs.length,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant MatchExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _pairs.length == widget.task.pairs.length,
        check: _check,
        reset: _reset,
      );
    }
  }

  @override
  void dispose() {
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    if (_pairs.length != widget.task.pairs.length) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Match all pairs first.',
      );
    }
    var correct = true;
    for (final entry in _pairs.entries) {
      final leftIndex = entry.key;
      final rightIndex = entry.value;
      final expected = widget.task.pairs[leftIndex].en;
      final got = _rightOptions[rightIndex];
      if (expected != got) {
        correct = false;
        break;
      }
    }
    setState(() {
      _checked = true;
      _correct = correct;
    });
    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'All pairs matched.' : 'Some pairs need another look.',
    );
  }

  void _reset() {
    setState(() {
      _pairs.clear();
      _leftSelection = null;
      _rightOptions.shuffle();
      _checked = false;
      _correct = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leftItems = widget.task.pairs
        .map((pair) => pair.grc)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Match the pairs', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: leftItems.length,
                  itemBuilder: (context, index) {
                    final assigned = _pairs[index];
                    final label = assigned == null ? leftItems[index] : '  →  ';
                    return ListTile(
                      title: Text(label, style: const TextStyle(fontSize: 18)),
                      selected: _leftSelection == index,
                      onTap: () => setState(() => _leftSelection = index),
                    );
                  },
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _rightOptions.length,
                  itemBuilder: (context, index) {
                    final selected = _pairs.values.contains(index);
                    return ListTile(
                      title: Text(_rightOptions[index]),
                      enabled: !selected,
                      onTap: _leftSelection == null
                          ? null
                          : () {
                              setState(() => _pairs[_leftSelection!] = index);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Pairs: ${_pairs.length}/${widget.task.pairs.length}',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                _reset();
              },
              child: const Text(L10nLessons.shuffle),
            ),
          ],
        ),
        if (_checked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _correct ? 'Matched!' : 'Keep pairing to find the matches.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _correct
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
