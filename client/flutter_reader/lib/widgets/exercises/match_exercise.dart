import "dart:math" as math;

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
  int? _hoveredLeft;
  int? _hoveredRight;

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
        message: "Match all pairs first.",
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
      message: correct ? "All pairs matched." : "Some pairs need another look.",
    );
  }

  void _reset() {
    setState(() {
      _pairs.clear();
      _leftSelection = null;
      _hoveredLeft = null;
      _hoveredRight = null;
      _rightOptions.shuffle();
      _checked = false;
      _correct = false;
    });
  }

  bool _isRightOptionUsed(int optionIndex) =>
      _pairs.values.contains(optionIndex);

  int _gridColumnsForWidth(double width, int itemCount) {
    final desired = width < 360
        ? 1
        : width < 720
        ? 2
        : 3;
    return math.max(1, math.min(desired, itemCount));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final colors = theme.colorScheme;
    final leftItems = widget.task.pairs
        .map((pair) => pair.grc)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Match the pairs",
          style: typography.uiTitle.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: spacing.xs),
        Text(
          "Tap a Greek term, then its English partner.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final isStacked = constraints.maxWidth < 720;
            final gutter = spacing.sm;
            final leftWidth = isStacked
                ? constraints.maxWidth
                : (constraints.maxWidth - gutter) / 2;
            final rightWidth = leftWidth;

            final leftGrid = _buildLeftGrid(context, leftItems, leftWidth);
            final rightGrid = _buildRightGrid(context, rightWidth);

            if (isStacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftGrid,
                  SizedBox(height: spacing.sm),
                  rightGrid,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftGrid),
                SizedBox(width: gutter),
                Expanded(child: rightGrid),
              ],
            );
          },
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Text(
              "Pairs: ${_pairs.length}/${widget.task.pairs.length}",
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
              _correct ? "Matched!" : "Keep pairing to find the matches.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _correct ? colors.primary : colors.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeftGrid(
    BuildContext context,
    List<String> items,
    double maxWidth,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final columnCount = _gridColumnsForWidth(maxWidth, items.length);
    final childAspectRatio = maxWidth < 520 ? 3.4 : 3.8;

    return GridView.builder(
      key: const ValueKey("match-left-grid"),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing.xs,
        mainAxisSpacing: spacing.xs,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final assigned = _pairs[index];
        final matched = assigned != null;
        final selected = _leftSelection == index;
        final hovered = _hoveredLeft == index;

        Color background = colors.surface;
        Color borderColor = colors.outlineVariant.withValues(alpha: 0.55);
        double borderWidth = 1;
        List<BoxShadow> shadows = const [];

        if (matched) {
          background = colors.primaryContainer;
          borderColor = colors.primary.withValues(alpha: 0.5);
        } else if (selected) {
          background = colors.secondaryContainer;
          borderColor = colors.secondary;
          borderWidth = 2;
          shadows = [
            BoxShadow(
              color: colors.secondary.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];
        } else if (hovered) {
          borderColor = colors.secondary.withValues(alpha: 0.35);
        }

        final subtitle = matched ? _rightOptions[assigned] : null;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredLeft = index),
          onExit: (_) => setState(() {
            if (_hoveredLeft == index) {
              _hoveredLeft = null;
            }
          }),
          child: AnimatedContainer(
            key: ValueKey("match-left-tile-$index"),
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    if (matched) {
                      _pairs.remove(index);
                      if (_leftSelection == index) {
                        _leftSelection = null;
                      }
                    } else {
                      _leftSelection = index;
                    }
                    _checked = false;
                    _correct = false;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm + spacing.xs,
                    vertical: spacing.xs + 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        items[index],
                        style: typography.greekBody.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: spacing.xs * 0.4),
                        Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                            SizedBox(width: spacing.xs * 0.5),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightGrid(BuildContext context, double maxWidth) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final columnCount = _gridColumnsForWidth(maxWidth, _rightOptions.length);
    final childAspectRatio = maxWidth < 520 ? 3.3 : 3.6;

    return GridView.builder(
      key: const ValueKey("match-right-grid"),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing.xs,
        mainAxisSpacing: spacing.xs,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _rightOptions.length,
      itemBuilder: (context, index) {
        final used = _isRightOptionUsed(index);
        final hovered = _hoveredRight == index;
        final canAssign = !used && _leftSelection != null;

        Color background = colors.surface;
        Color borderColor = colors.outlineVariant.withValues(alpha: 0.5);
        double borderWidth = 1;

        if (used) {
          background = colors.surfaceContainerHighest;
          borderColor = colors.outlineVariant.withValues(alpha: 0.35);
        } else if (hovered && _leftSelection != null) {
          borderColor = colors.primary;
          borderWidth = 2;
          background = colors.primaryContainer.withValues(alpha: 0.65);
        } else if (hovered) {
          borderColor = colors.outlineVariant.withValues(alpha: 0.7);
        }

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredRight = index),
          onExit: (_) => setState(() {
            if (_hoveredRight == index) {
              _hoveredRight = null;
            }
          }),
          child: AnimatedContainer(
            key: ValueKey("match-right-tile-$index"),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: canAssign
                    ? () {
                        final chosenLeft = _leftSelection!;
                        setState(() {
                          _pairs[chosenLeft] = index;
                          _leftSelection = null;
                          _checked = false;
                          _correct = false;
                        });
                      }
                    : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm + spacing.xs,
                    vertical: spacing.xs + 6,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _rightOptions[index],
                      style: typography.uiBody.copyWith(
                        color: used
                            ? colors.onSurfaceVariant.withValues(alpha: 0.7)
                            : colors.onSurface,
                        fontWeight: used ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
