import 'package:flutter/material.dart';

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';
import '../tts_play_button.dart';

typedef OpenReaderCallback = void Function();

class ClozeExercise extends StatefulWidget {
  const ClozeExercise({
    super.key,
    required this.task,
    required this.onOpenInReader,
    required this.ttsEnabled,
  });

  final ClozeTask task;
  final OpenReaderCallback onOpenInReader;
  final bool ttsEnabled;

  @override
  State<ClozeExercise> createState() => _ClozeExerciseState();
}

class _ClozeExerciseState extends State<ClozeExercise> {
  late final List<String> _options;
  final Map<int, String> _answers = <int, String>{};
  int? _activeBlank;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    final external = widget.task.options;
    if (external != null && external.isNotEmpty) {
      _options = List<String>.from(external);
    } else {
      final deduped = <String>{
        for (final blank in widget.task.blanks) blank.surface,
      };
      _options = deduped.toList(growable: false);
    }
    _options.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Complete the line', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.task.text,
                style: const TextStyle(fontSize: 20, height: 1.4),
              ),
            ),
            TtsPlayButton(
              text: widget.task.text,
              enabled: widget.ttsEnabled,
              semanticLabel: 'Play lesson line',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final blank in widget.task.blanks)
              InputChip(
                label: Text(_answers[blank.idx] ?? '—'),
                selected: _activeBlank == blank.idx,
                onPressed: () => setState(() => _activeBlank = blank.idx),
                onDeleted: _answers.containsKey(blank.idx)
                    ? () => setState(() {
                        _answers.remove(blank.idx);
                        _activeBlank = null;
                      })
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _options)
              FilterChip(
                label: Text(option, style: const TextStyle(fontSize: 18)),
                selected: _answers.values.contains(option),
                onSelected: (selected) {
                  if (!selected) {
                    setState(
                      () => _answers.removeWhere((_, value) => value == option),
                    );
                    return;
                  }
                  _assignOption(option);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.task.ref != null)
              TextButton(
                onPressed: widget.onOpenInReader,
                child: Text(L10nLessons.openReader),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _revealed = !_revealed),
              child: Text(_revealed ? 'Hide solution' : L10nLessons.reveal),
            ),
          ],
        ),
        if (_revealed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final blank in widget.task.blanks)
                  Chip(
                    label: Text(
                      blank.surface,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _assignOption(String option) {
    final target =
        _activeBlank ??
        widget.task.blanks
            .firstWhere(
              (blank) => !_answers.containsKey(blank.idx),
              orElse: () => widget.task.blanks.first,
            )
            .idx;
    setState(() {
      _answers[target] = option;
      _activeBlank = null;
    });
  }
}
