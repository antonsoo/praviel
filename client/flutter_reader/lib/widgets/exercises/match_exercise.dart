import "package:flutter/material.dart";
import "package:flutter/services.dart";

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/premium_gradients.dart';
import 'exercise_control.dart';

class MatchExercise extends StatefulWidget {
  const MatchExercise({super.key, required this.task, required this.handle});

  final MatchTask task;
  final LessonExerciseHandle handle;

  @override
  State<MatchExercise> createState() => _MatchExerciseState();
}

class _MatchExerciseState extends State<MatchExercise>
    with TickerProviderStateMixin {
  int? _leftSelection;
  late final List<String> _rightOptions;
  final Map<int, int> _pairs = <int, int>{};
  bool _checked = false;
  bool _correct = false;
  int? _hoveredLeft;
  int? _hoveredRight;
  late AnimationController _matchAnimationController;

  @override
  void initState() {
    super.initState();
    _matchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
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
    _matchAnimationController.dispose();
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

    // Haptic feedback for check result
    try {
      if (correct) {
        HapticFeedback.heavyImpact(); // Strong success feedback
      } else {
        HapticFeedback.mediumImpact(); // Gentle error feedback
      }
    } catch (_) {}

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
    widget.handle.notify();
  }

  bool _isRightOptionUsed(int optionIndex) =>
      _pairs.values.contains(optionIndex);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final colors = theme.colorScheme;
    final leftItems = widget.task.pairs
        .map((pair) => pair.native)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Match the pairs",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.xs),
        Text(
          "Tap a Greek term, then its English partner.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.md),
        // Always show side-by-side columns: Greek on left, English on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLeftColumn(context, leftItems)),
            SizedBox(width: spacing.sm),
            Expanded(child: _buildRightColumn(context)),
          ],
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

  Widget _buildLeftColumn(BuildContext context, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(items.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: ReaderTheme.spacingOf(context).sm),
          child: _buildLeftCard(context, index, items[index]),
        );
      }),
    );
  }

  Widget _buildLeftCard(BuildContext context, int index, String text) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);

    final assigned = _pairs[index];
    final matched = assigned != null;
    final selected = _leftSelection == index;
    final hovered = _hoveredLeft == index;

    Color background = colors.surface;
    Color borderColor = colors.outlineVariant.withValues(alpha: 0.55);
    double borderWidth = 1;
    List<BoxShadow> shadows = [];
    Gradient? gradient;

    if (matched) {
      background = colors.primaryContainer;
      borderColor = const Color(0xFF10B981);
      borderWidth = 2;
      gradient = PremiumGradients.successButton.scale(0.15);
      shadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (selected) {
      background = colors.secondaryContainer;
      borderColor = colors.secondary;
      borderWidth = 2;
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.secondary.withValues(alpha: 0.2),
          colors.secondary.withValues(alpha: 0.08),
        ],
      );
      shadows = [
        BoxShadow(
          color: colors.secondary.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: colors.secondary.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];
    } else if (hovered) {
      borderColor = colors.secondary.withValues(alpha: 0.35);
      shadows = [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }

    final subtitle = matched ? _rightOptions[assigned] : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredLeft = index),
      onExit: (_) => setState(() {
        if (_hoveredLeft == index) {
          _hoveredLeft = null;
        }
      }),
      child: TweenAnimationBuilder<double>(
        key: ValueKey("match-left-tile-$index"),
        duration: AppDuration.fast,
        curve: selected ? Curves.elasticOut : AppCurves.smooth,
        tween: Tween<double>(
          begin: 1.0,
          end: selected ? 1.05 : (matched ? 1.02 : 1.0),
        ),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: AppDuration.fast,
            curve: AppCurves.smooth,
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? background : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  // Haptic feedback for tactile response
                  if (matched) {
                    // Light impact for unmatch
                    try {
                      HapticFeedback.lightImpact();
                    } catch (_) {}
                  } else {
                    // Medium impact for selection
                    try {
                      HapticFeedback.mediumImpact();
                    } catch (_) {}
                  }

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
                  widget.handle.notify();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm + spacing.xs,
                    vertical: spacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: typography.greekBody.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: spacing.xs * 0.4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                                overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(_rightOptions.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: ReaderTheme.spacingOf(context).sm),
          child: _buildRightCard(context, index),
        );
      }),
    );
  }

  Widget _buildRightCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);

    final used = _isRightOptionUsed(index);
    final hovered = _hoveredRight == index;
    final canAssign = !used && _leftSelection != null;

    Color background = colors.surface;
    Color borderColor = colors.outlineVariant.withValues(alpha: 0.5);
    double borderWidth = 1;
    Gradient? gradient;
    List<BoxShadow> shadows = [];

    if (used) {
      background = colors.surfaceContainerHighest;
      borderColor = colors.outlineVariant.withValues(alpha: 0.35);
      shadows = [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    } else if (hovered && _leftSelection != null) {
      borderColor = colors.primary;
      borderWidth = 2;
      background = colors.primaryContainer.withValues(alpha: 0.65);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primary.withValues(alpha: 0.15),
          colors.primary.withValues(alpha: 0.05),
        ],
      );
      shadows = [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (hovered) {
      borderColor = colors.outlineVariant.withValues(alpha: 0.7);
      shadows = [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRight = index),
      onExit: (_) => setState(() {
        if (_hoveredRight == index) {
          _hoveredRight = null;
        }
      }),
      child: TweenAnimationBuilder<double>(
        duration: AppDuration.fast,
        curve: canAssign && hovered ? Curves.elasticOut : AppCurves.smooth,
        tween: Tween<double>(
          begin: 1.0,
          end: canAssign && hovered ? 1.05 : 1.0,
        ),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            key: ValueKey("match-right-tile-$index"),
            duration: AppDuration.fast,
            curve: AppCurves.smooth,
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? background : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: canAssign
                    ? () {
                        // Haptic feedback for successful pairing
                        try {
                          HapticFeedback.lightImpact();
                        } catch (_) {}

                        final chosenLeft = _leftSelection!;
                        setState(() {
                          _pairs[chosenLeft] = index;
                          _leftSelection = null;
                          _checked = false;
                          _correct = false;
                        });
                        widget.handle.notify();
                      }
                    : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm + spacing.xs,
                    vertical: spacing.sm,
                  ),
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
      ),
    );
  }
}
