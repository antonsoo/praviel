import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import 'exercise_control.dart';

/// Context-based word matching exercise with sentence visualization
class VibrantContextMatchExercise extends StatefulWidget {
  const VibrantContextMatchExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final ContextMatchTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantContextMatchExercise> createState() =>
      _VibrantContextMatchExerciseState();
}

class _VibrantContextMatchExerciseState
    extends State<VibrantContextMatchExercise>
    with SingleTickerProviderStateMixin {
  String? _selected;
  bool _checked = false;
  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    widget.handle.attach(
      canCheck: () => _selected != null,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final correct = _selected == widget.task.answer;
    if (correct) {
      _feedbackController.forward(from: 0);
    }
    setState(() {
      _checked = true;
    });
    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Perfect contextual match! 🎯'
          : 'The correct word is "${widget.task.answer}"',
    );
  }

  void _reset() => setState(() {
    _selected = null;
    _checked = false;
    _feedbackController.reset();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideInFromBottom(
      delay: const Duration(milliseconds: 150),
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title with context icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.6),
                        colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Icon(
                    Icons.article,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    'Choose the word that fits',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Sentence card with blank
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.2),
                    colorScheme.secondaryContainer.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _buildSentenceWithBlank(theme, colorScheme),
            ),

            // Context hint (if available)
            if (widget.task.contextHint != null) ...[
              const SizedBox(height: VibrantSpacing.md),
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.task.contextHint!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: VibrantSpacing.xxl),

            // Options
            ...widget.task.options.asMap().entries.map((entry) {
              final index = entry.key;
              final opt = entry.value;
              final isSelected = _selected == opt;
              final isCorrect = _checked && opt == widget.task.answer;
              final isWrong = _checked && isSelected && !isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                child: _buildOptionCard(
                  opt,
                  index,
                  isSelected,
                  isCorrect,
                  isWrong,
                  theme,
                  colorScheme,
                ),
              );
            }),

            if (_checked) ...[
              const SizedBox(height: VibrantSpacing.xl),
              _buildFeedback(theme, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceWithBlank(ThemeData theme, ColorScheme colorScheme) {
    final parts = widget.task.sentence.split('___');
    if (parts.length != 2) {
      // If no blank marker, just show the sentence
      return Text(
        widget.task.sentence,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          parts[0],
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            height: 1.5,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: VibrantSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: VibrantSpacing.md,
            vertical: VibrantSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _checked
                ? (_selected == widget.task.answer
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2))
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(VibrantRadius.sm),
            border: Border.all(
              color: _checked
                  ? (_selected == widget.task.answer
                        ? Colors.green
                        : Colors.red)
                  : colorScheme.primary.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Text(
            _selected ?? '____',
            style: theme.textTheme.titleLarge?.copyWith(
              color: _checked
                  ? (_selected == widget.task.answer
                        ? Colors.green[800]
                        : Colors.red[800])
                  : colorScheme.primary,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),
        Text(
          parts[1],
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    String option,
    int index,
    bool isSelected,
    bool isCorrect,
    bool isWrong,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : isWrong
            ? Colors.red.withValues(alpha: 0.1)
            : isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: isCorrect
              ? Colors.green
              : isWrong
              ? Colors.red
              : isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isCorrect || isWrong || isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected && !_checked)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          if (isCorrect)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _checked
              ? null
              : () {
                  setState(() => _selected = option);
                  widget.handle.notify();
                },
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.lg,
            ),
            child: Row(
              children: [
                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected || isCorrect
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isCorrect
                          ? Colors.green[800]
                          : isWrong
                          ? Colors.red[800]
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                // Check/cross icon
                if (_checked)
                  Icon(
                    isCorrect
                        ? Icons.check_circle
                        : (isWrong ? Icons.cancel : null),
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(ThemeData theme, ColorScheme colorScheme) {
    final correct = _selected == widget.task.answer;

    return ScaleIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          color: correct
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: correct ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle : Icons.info_outline,
              color: correct ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: VibrantSpacing.md),
            Expanded(
              child: Text(
                correct
                    ? 'Perfect contextual match! 🎯'
                    : 'The correct word is "${widget.task.answer}"',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: correct ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
