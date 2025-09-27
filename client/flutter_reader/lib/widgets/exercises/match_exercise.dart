import "package:flutter/material.dart";

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';
import '../../theme/app_theme.dart';
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
    _rightOptions = widget.task.pairs.map((pair) => pair.en).toList(growable: false);
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
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final colors = theme.colorScheme;

    final leftItems = widget.task.pairs.map((pair) => pair.grc).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Match the pairs', style: typography.uiTitle.copyWith(color: colors.onSurface)),
        SizedBox(height: spacing.xs),
        Text(
          'Tap a Greek term, then its English partner.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: spacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            final listHeight = (MediaQuery.of(context).size.height * 0.38).clamp(240.0, 460.0).toDouble();

            final leftList = _buildLeftList(context, leftItems, isNarrow ? null : listHeight);
            final rightList = _buildRightList(context, isNarrow ? null : listHeight);

            if (isNarrow) {
              return Column(
                children: [
                  leftList,
                  SizedBox(height: spacing.sm),
                  rightList,
                ],
              );
            }

            return SizedBox(
              height: listHeight,
              child: Row(
                children: [
                  Expanded(child: leftList),
                  SizedBox(width: spacing.sm),
                  Expanded(child: rightList),
                ],
              ),
            );
          },
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Text(
              'Pairs: ${_pairs.length}/${widget.task.pairs.length}',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.shuffle),
              label: const Text(L10nLessons.shuffle),
            ),
          ],
        ),
        if (_checked)
          Padding(
            padding: EdgeInsets.only(top: spacing.xs),
            child: Text(
              _correct ? 'Matched!' : 'Keep pairing to find the matches.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _correct ? colors.primary : colors.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeftList(BuildContext context, List<String> items, double? height) {
    final typography = ReaderTheme.typographyOf(context);
    final colors = Theme.of(context).colorScheme;

    final list = ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final assigned = _pairs[index];
        final selected = _leftSelection == index;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: selected ? colors.secondaryContainer : colors.surface,
          elevation: selected ? 0 : 0,
          child: ListTile(
            dense: true,
            title: Text(
              assigned == null ? items[index] : '•',
              style: typography.greekBody,
            ),
            trailing: assigned != null
                ? Icon(Icons.check_circle, size: 16, color: colors.primary.withValues(alpha: 0.7))
                : null,
            selected: selected,
            onTap: () => setState(() => _leftSelection = index),
          ),
        );
      },
    );

    if (height == null) {
      return list;
    }
    return SizedBox(height: height, child: list);
  }

  Widget _buildRightList(BuildContext context, double? height) {
    final theme = Theme.of(context);
    final typography = ReaderTheme.typographyOf(context);
    final colors = theme.colorScheme;

    final list = ListView.builder(
      itemCount: _rightOptions.length,
      itemBuilder: (context, index) {
        final selected = _pairs.values.contains(index);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: selected ? colors.primaryContainer : colors.surface,
          child: ListTile(
            dense: true,
            title: Text(
              _rightOptions[index],
              style: typography.uiBody,
            ),
            enabled: !selected,
            onTap: _leftSelection == null
                ? null
                : () {
                    setState(() => _pairs[_leftSelection!] = index);
                  },
          ),
        );
      },
    );

    if (height == null) {
      return list;
    }
    return SizedBox(height: height, child: list);
  }
}
