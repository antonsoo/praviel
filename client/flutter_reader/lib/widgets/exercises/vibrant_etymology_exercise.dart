import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import 'exercise_control.dart';

/// Etymology quiz with word history visualization
class VibrantEtymologyExercise extends StatefulWidget {
  const VibrantEtymologyExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final EtymologyTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantEtymologyExercise> createState() =>
      _VibrantEtymologyExerciseState();
}

class _VibrantEtymologyExerciseState extends State<VibrantEtymologyExercise>
    with SingleTickerProviderStateMixin {
  int? _selected;
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
    final correct = _selected == widget.task.answerIndex;
    if (correct) {
      _feedbackController.forward(from: 0);
    }
    setState(() {
      _checked = true;
    });
    return LessonCheckFeedback(
      correct: correct,
      message: widget.task.explanation,
    );
  }

  void _reset() {
    setState(() {
      _selected = null;
      _checked = false;
    });
    _feedbackController.reset();
  }

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
            // Title with etymology icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Icon(
                    Icons.account_tree,
                    color: colorScheme.tertiary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    'Etymology',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Question card
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.question,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        size: 20,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: VibrantSpacing.sm),
                      Text(
                        widget.task.word,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Options
            ...widget.task.options.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final isSelected = _selected == idx;
              final isCorrect = _checked && idx == widget.task.answerIndex;
              final isWrong = _checked && isSelected && !isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                child: _buildOptionCard(
                  opt,
                  idx,
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
              _buildExplanation(theme, colorScheme),
            ],
          ],
        ),
      ),
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
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: isCorrect
              ? Colors.green
              : isWrong
              ? Colors.red
              : isSelected
              ? colorScheme.tertiary
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isCorrect || isWrong || isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected && !_checked)
            BoxShadow(
              color: colorScheme.tertiary.withValues(alpha: 0.2),
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
          onTap: _checked ? null : () => setState(() => _selected = index),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.lg,
            ),
            child: Row(
              children: [
                // Option number
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withValues(alpha: 0.2)
                        : isWrong
                        ? Colors.red.withValues(alpha: 0.2)
                        : isSelected
                        ? colorScheme.tertiary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCorrect
                          ? Colors.green[800]
                          : isWrong
                          ? Colors.red[800]
                          : isSelected
                          ? colorScheme.tertiary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: theme.textTheme.bodyLarge?.copyWith(
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

  Widget _buildExplanation(ThemeData theme, ColorScheme colorScheme) {
    final correct = _selected == widget.task.answerIndex;

    return ScaleIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: correct
                ? [
                    Colors.green.withValues(alpha: 0.1),
                    Colors.green.withValues(alpha: 0.05),
                  ]
                : [
                    Colors.orange.withValues(alpha: 0.1),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: correct ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.lightbulb : Icons.school,
                  color: correct ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Text(
                  correct ? 'Excellent!' : 'Learn from this',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: correct ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VibrantSpacing.md),
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Text(
                widget.task.explanation,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
