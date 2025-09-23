import 'package:flutter/material.dart';

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';

class MatchExercise extends StatefulWidget {
  const MatchExercise({super.key, required this.task});

  final MatchTask task;

  @override
  State<MatchExercise> createState() => _MatchExerciseState();
}

class _MatchExerciseState extends State<MatchExercise> {
  int? _leftSelection;
  late final List<String> _rightOptions;
  final Map<int, int> _pairs = <int, int>{};

  @override
  void initState() {
    super.initState();
    _rightOptions = widget.task.pairs
        .map((pair) => pair.en)
        .toList(growable: false);
    _rightOptions.shuffle();
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
            Text('Pairs: /'),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _pairs.clear();
                  _leftSelection = null;
                  _rightOptions.shuffle();
                });
              },
              child: const Text(L10nLessons.shuffle),
            ),
          ],
        ),
      ],
    );
  }
}
