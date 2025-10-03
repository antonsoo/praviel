import "package:flutter/material.dart";

import '../../localization/strings_lessons_en.dart';
import '../../models/lesson.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../tts_play_button.dart';
import 'exercise_control.dart';

typedef OpenReaderCallback = void Function();

class ClozeExercise extends StatefulWidget {
  const ClozeExercise({
    super.key,
    required this.task,
    required this.onOpenInReader,
    required this.ttsEnabled,
    required this.handle,
  });

  final ClozeTask task;
  final OpenReaderCallback onOpenInReader;
  final bool ttsEnabled;
  final LessonExerciseHandle handle;

  @override
  State<ClozeExercise> createState() => _ClozeExerciseState();
}

class _ClozeExerciseState extends State<ClozeExercise> {
  late final List<String> _options;
  final Map<int, String> _answers = <int, String>{};
  int? _activeBlank;
  bool _revealed = false;
  bool _checked = false;

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
    widget.handle.attach(
      canCheck: () => _answers.length == widget.task.blanks.length,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant ClozeExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _answers.length == widget.task.blanks.length,
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
    if (_answers.length != widget.task.blanks.length) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Fill all blanks first.',
      );
    }
    var correct = true;
    for (final blank in widget.task.blanks) {
      if (_answers[blank.idx] != blank.surface) {
        correct = false;
        break;
      }
    }
    setState(() {
      _checked = true;
    });
    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'Well done.' : 'Check the highlighted blanks.',
    );
  }

  void _reset() {
    setState(() {
      _answers.clear();
      _activeBlank = null;
      _revealed = false;
      _checked = false;
      _options.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final colors = theme.colorScheme;

    final promptStyle = typography.greekBody.copyWith(color: colors.onSurface);
    final optionStyle = typography.greekBody.copyWith(
      fontSize: 19,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete the line',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.space16),
        // Greek text in elevated card
        Container(
          padding: EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'greek-text-${widget.task.text}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      widget.task.text,
                      style: promptStyle.copyWith(fontSize: 20),
                    ),
                  ),
                ),
              ),
              if (widget.ttsEnabled) ...[
                SizedBox(width: spacing.sm),
                TtsPlayButton(
                  text: widget.task.text,
                  enabled: true,
                  semanticLabel: 'Play lesson line',
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: spacing.md),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (final blank in widget.task.blanks)
              _blankChip(
                context,
                index: blank.idx,
                label: _answers[blank.idx] ?? '',
                correct: _checked ? _answers[blank.idx] == blank.surface : null,
                selected: _activeBlank == blank.idx,
                onTap: () => setState(() {
                  _activeBlank = blank.idx;
                  _checked = false;
                }),
                onClear: _answers.containsKey(blank.idx)
                    ? () => setState(() {
                        _answers.remove(blank.idx);
                        _activeBlank = null;
                        _checked = false;
                      })
                    : null,
              ),
          ],
        ),
        SizedBox(height: spacing.md),
        Text(
          'Word bank',
          style: typography.label.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: spacing.xs),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (var i = 0; i < _options.length; i++)
              FilterChip(
                key: ValueKey('cloze-option-$i'),
                label: Text(_options[i], style: optionStyle.copyWith(fontSize: 16)),
                labelPadding: EdgeInsets.symmetric(
                  horizontal: spacing.lg,
                  vertical: spacing.md,
                ),
                selected: _answers.values.contains(_options[i]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.comfortable,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (selected) {
                  final option = _options[i];
                  if (!selected) {
                    setState(() {
                      _answers.removeWhere((_, value) => value == option);
                      _checked = false;
                    });
                    return;
                  }
                  _assignOption(option);
                },
              ),
          ],
        ),
        SizedBox(height: spacing.md),
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
            padding: EdgeInsets.only(top: spacing.xs),
            child: Wrap(
              spacing: spacing.xs,
              runSpacing: spacing.xs,
              children: [
                for (final blank in widget.task.blanks)
                  Chip(
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: spacing.sm,
                      vertical: spacing.xs * 0.6,
                    ),
                    label: Text(blank.surface, style: optionStyle),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _blankChip(
    BuildContext context, {
    required int index,
    required String label,
    required bool? correct,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final colors = theme.colorScheme;
    final typography = ReaderTheme.typographyOf(context);

    Color? background;
    Color borderColor = colors.outlineVariant;
    double borderWidth = 1.2;

    final isDark = theme.brightness == Brightness.dark;

    if (correct != null) {
      if (correct) {
        background = isDark
            ? AppColors.successContainerDark
            : AppColors.successContainerLight;
        borderColor = isDark
            ? AppColors.successDark
            : AppColors.successLight;
      } else {
        background = colors.errorContainer;
        borderColor = colors.error;
      }
      borderWidth = 2;
    } else if (selected) {
      background = colors.secondaryContainer;
      borderColor = colors.secondary;
      borderWidth = 2;
    }

    final hasValue = label.trim().isNotEmpty;

    return InputChip(
      key: ValueKey('cloze-blank-$index'),
      label: Text(
        hasValue ? label : '____',
        style: typography.greekBody.copyWith(
          fontSize: 20,
          color: hasValue ? colors.onSurface : colors.onSurfaceVariant,
        ),
      ),
      labelPadding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs * 0.75,
      ),
      showCheckmark: false,
      selected: selected,
      onPressed: onTap,
      onDeleted: onClear,
      deleteIcon: onClear != null
          ? const Icon(Icons.close_rounded, size: 18)
          : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.comfortable,
      backgroundColor: background ?? colors.surface,
      selectedColor: background ?? colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
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
