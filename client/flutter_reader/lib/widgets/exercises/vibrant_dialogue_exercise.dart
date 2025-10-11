import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import 'exercise_control.dart';

/// Interactive dialogue completion with chat-like UI
class VibrantDialogueExercise extends StatefulWidget {
  const VibrantDialogueExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final DialogueTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantDialogueExercise> createState() =>
      _VibrantDialogueExerciseState();
}

class _VibrantDialogueExerciseState extends State<VibrantDialogueExercise>
    with SingleTickerProviderStateMixin {
  String? _selectedAnswer;
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
      canCheck: () => _selectedAnswer != null,
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
    if (_selectedAnswer == null) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Select an answer',
      );
    }

    final correct = _selectedAnswer == widget.task.answer;
    if (correct) {
      _feedbackController.forward(from: 0);
    }
    setState(() {
      _checked = true;
    });

    return LessonCheckFeedback(
      correct: correct,
      message: correct ? 'Perfect dialogue! 💬' : 'Try again!',
    );
  }

  void _reset() {
    setState(() {
      _selectedAnswer = null;
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
            // Title with chat icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: colorScheme.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    'Complete the dialogue',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Dialogue bubbles
            ...widget.task.lines.asMap().entries.map((entry) {
              final idx = entry.key;
              final line = entry.value;
              final isMissing = idx == widget.task.missingIndex;
              final isEven = idx % 2 == 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                child: _buildDialogueBubble(
                  line,
                  isMissing,
                  isEven,
                  idx,
                  theme,
                  colorScheme,
                ),
              );
            }),

            const SizedBox(height: VibrantSpacing.xl),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: VibrantSpacing.md),
                  child: Text(
                    'Choose the missing line',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Options
            ...widget.task.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedAnswer == option;
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

  Widget _buildDialogueBubble(
    DialogueLine line,
    bool isMissing,
    bool isEven,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SlideInFromBottom(
      delay: Duration(milliseconds: 200 + (index * 100)),
      child: Row(
        mainAxisAlignment:
            isEven ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isEven) const Spacer(),
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.lg,
                vertical: VibrantSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: isMissing
                    ? LinearGradient(
                        colors: [
                          colorScheme.errorContainer.withValues(alpha: 0.3),
                          colorScheme.errorContainer.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: isEven
                            ? [
                                colorScheme.primaryContainer
                                    .withValues(alpha: 0.4),
                                colorScheme.primaryContainer
                                    .withValues(alpha: 0.2),
                              ]
                            : [
                                colorScheme.secondaryContainer
                                    .withValues(alpha: 0.4),
                                colorScheme.secondaryContainer
                                    .withValues(alpha: 0.2),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(VibrantRadius.lg),
                  topRight: Radius.circular(VibrantRadius.lg),
                  bottomLeft:
                      Radius.circular(isEven ? VibrantRadius.sm : VibrantRadius.lg),
                  bottomRight:
                      Radius.circular(isEven ? VibrantRadius.lg : VibrantRadius.sm),
                ),
                border: isMissing
                    ? Border.all(
                        color: colorScheme.error.withValues(alpha: 0.5),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.speaker,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEven
                          ? colorScheme.primary
                          : colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  isMissing
                      ? Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: VibrantSpacing.xs),
                            Text(
                              '[Missing line]',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          line.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                ],
              ),
            ),
          ),
          if (isEven) const Spacer(),
        ],
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
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: isCorrect
              ? Colors.green
              : isWrong
                  ? Colors.red
                  : isSelected
                      ? colorScheme.secondary
                      : colorScheme.outline.withValues(alpha: 0.3),
          width: isCorrect || isWrong || isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected && !_checked)
            BoxShadow(
              color: colorScheme.secondary.withValues(alpha: 0.2),
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
          onTap: _checked ? null : () => setState(() => _selectedAnswer = option),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.md,
            ),
            child: Row(
              children: [
                // Quote icon
                Icon(
                  Icons.format_quote,
                  color: isCorrect
                      ? Colors.green[700]
                      : isWrong
                          ? Colors.red[700]
                          : isSelected
                              ? colorScheme.secondary
                              : colorScheme.onSurfaceVariant,
                  size: 24,
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

  Widget _buildFeedback(ThemeData theme, ColorScheme colorScheme) {
    final correct = _selectedAnswer == widget.task.answer;

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
                    ? 'Perfect dialogue! 💬'
                    : 'Not quite right. The correct answer is "${widget.task.answer}"',
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
