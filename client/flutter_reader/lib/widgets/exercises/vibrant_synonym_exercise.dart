import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import 'exercise_control.dart';

/// Find synonyms or antonyms with elegant visual feedback
class VibrantSynonymExercise extends StatefulWidget {
  const VibrantSynonymExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final SynonymTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantSynonymExercise> createState() => _VibrantSynonymExerciseState();
}

class _VibrantSynonymExerciseState extends State<VibrantSynonymExercise>
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
          ? 'Perfect match! 🎯'
          : 'Not quite. The correct ${widget.task.taskType} is "${widget.task.answer}"',
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
            // Title with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Icon(
                    widget.task.taskType == 'synonym'
                        ? Icons.compare_arrows
                        : Icons.swap_horiz,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    'Find the ${widget.task.taskType}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Word card
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                    colorScheme.secondaryContainer.withValues(alpha: 0.3),
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
              child: Column(
                children: [
                  Text(
                    'WORD',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.sm),
                  Text(
                    widget.task.word,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Options
            ...widget.task.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selected == option;
              final isCorrect = _checked && option == widget.task.answer;
              final isWrong = _checked && isSelected && !isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                child: _buildOptionCard(
                  option,
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
          onTap: _checked ? null : () => setState(() => _selected = option),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.lg,
            ),
            child: Row(
              children: [
                // Option letter
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withValues(alpha: 0.2)
                        : isWrong
                        ? Colors.red.withValues(alpha: 0.2)
                        : isSelected
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCorrect
                          ? Colors.green[800]
                          : isWrong
                          ? Colors.red[800]
                          : isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
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
                    ? 'Perfect match! 🎯'
                    : 'The correct ${widget.task.taskType} is "${widget.task.answer}"',
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
