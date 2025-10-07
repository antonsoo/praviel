import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/professional_theme.dart';
import 'exercise_control.dart';

/// PROFESSIONAL match exercise - clean, minimal, purposeful
/// Inspired by Apple's design language and Stripe's polish
class ProMatchExercise extends StatefulWidget {
  const ProMatchExercise({super.key, required this.task, required this.handle});

  final MatchTask task;
  final LessonExerciseHandle handle;

  @override
  State<ProMatchExercise> createState() => _ProMatchExerciseState();
}

class _ProMatchExerciseState extends State<ProMatchExercise> {
  int? _leftSelection;
  late final List<String> _rightOptions;
  final Map<int, int> _pairs = <int, int>{};
  bool _checked = false;

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
  void didUpdateWidget(covariant ProMatchExercise oldWidget) {
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
        message: 'Match all pairs to continue',
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
    });

    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'Perfect!' : 'Not quite right, try again',
    );
  }

  void _reset() {
    setState(() {
      _pairs.clear();
      _leftSelection = null;
      _rightOptions.shuffle();
      _checked = false;
    });
    widget.handle.notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leftItems = widget.task.pairs
        .map((pair) => pair.grc)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions
        Text(
          'Match each Greek word with its English translation',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: ProSpacing.xxl),

        // Matching pairs
        ...List.generate(leftItems.length, (index) {
          return _buildPairRow(
            context,
            theme,
            colorScheme,
            index,
            leftItems[index],
          );
        }),

        const SizedBox(height: ProSpacing.xl),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_pairs.length}/${widget.task.pairs.length} matched',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(onPressed: _reset, child: const Text('Reset')),
          ],
        ),
      ],
    );
  }

  Widget _buildPairRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int leftIndex,
    String leftText,
  ) {
    final assigned = _pairs[leftIndex];
    final matched = assigned != null;
    final selected = _leftSelection == leftIndex;

    // Show result if checked
    bool? isCorrect;
    if (_checked && matched) {
      final expected = widget.task.pairs[leftIndex].en;
      final got = _rightOptions[assigned];
      isCorrect = expected == got;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: ProSpacing.md),
      child: Row(
        children: [
          // Left side (Greek)
          Expanded(
            flex: 5,
            child: _buildLeftCard(
              context,
              theme,
              colorScheme,
              leftIndex,
              leftText,
              selected,
              matched,
              isCorrect,
            ),
          ),

          // Connector line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ProSpacing.md),
            child: Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: matched
                    ? (isCorrect == true
                          ? colorScheme.tertiary
                          : (isCorrect == false
                                ? colorScheme.error
                                : colorScheme.primary))
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

          // Right side (English)
          Expanded(
            flex: 5,
            child: matched
                ? _buildRightCard(
                    context,
                    theme,
                    colorScheme,
                    _rightOptions[assigned],
                    isCorrect,
                  )
                : _buildDropdown(context, theme, colorScheme, leftIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
    String text,
    bool selected,
    bool matched,
    bool? isCorrect,
  ) {
    Color borderColor = colorScheme.outline;
    Color? backgroundColor;

    if (selected) {
      borderColor = colorScheme.primary;
      backgroundColor = colorScheme.primaryContainer;
    } else if (matched) {
      if (isCorrect == true) {
        borderColor = colorScheme.tertiary;
        backgroundColor = colorScheme.tertiaryContainer;
      } else if (isCorrect == false) {
        borderColor = colorScheme.error;
        backgroundColor = colorScheme.errorContainer;
      }
    }

    return GestureDetector(
      onTap: () {
        if (!matched) {
          setState(() {
            _leftSelection = _leftSelection == index ? null : index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(ProSpacing.lg),
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(ProRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (matched && isCorrect != null)
              Icon(
                isCorrect ? Icons.check : Icons.close,
                size: 18,
                color: isCorrect ? colorScheme.tertiary : colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String text,
    bool? isCorrect,
  ) {
    Color borderColor = colorScheme.outline;
    Color? backgroundColor;

    if (isCorrect == true) {
      borderColor = colorScheme.tertiary;
      backgroundColor = colorScheme.tertiaryContainer;
    } else if (isCorrect == false) {
      borderColor = colorScheme.error;
      backgroundColor = colorScheme.errorContainer;
    }

    return Container(
      padding: const EdgeInsets.all(ProSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(ProRadius.md),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int leftIndex,
  ) {
    final unusedOptions = List<int>.generate(
      _rightOptions.length,
      (i) => i,
    ).where((i) => !_pairs.values.contains(i)).toList();

    if (_leftSelection != leftIndex) {
      return Container(
        padding: const EdgeInsets.all(ProSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(ProRadius.md),
        ),
        child: Text(
          'Select',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: null,
      hint: Text('Choose translation', style: theme.textTheme.bodyMedium),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ProSpacing.lg,
          vertical: ProSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      items: unusedOptions.map((optionIndex) {
        return DropdownMenuItem<int>(
          value: optionIndex,
          child: Text(
            _rightOptions[optionIndex],
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null && _leftSelection != null) {
          setState(() {
            _pairs[_leftSelection!] = value;
            _leftSelection = null;
            _checked = false;
          });
          widget.handle.notify();
        }
      },
    );
  }
}
