import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import 'exercise_control.dart';

/// Reorder sentence fragments with smooth drag-and-drop
class VibrantReorderExercise extends StatefulWidget {
  const VibrantReorderExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final ReorderTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantReorderExercise> createState() => _VibrantReorderExerciseState();
}

class _VibrantReorderExerciseState extends State<VibrantReorderExercise>
    with SingleTickerProviderStateMixin {
  late List<String> _currentOrder;
  bool _checked = false;
  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _currentOrder = List.from(widget.task.fragments);
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    widget.handle.attach(
      canCheck: () => _currentOrder.join() != widget.task.fragments.join(),
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
    final userOrder = _currentOrder
        .map((frag) => widget.task.fragments.indexOf(frag))
        .toList();
    final correct = userOrder.toString() == widget.task.correctOrder.toString();

    if (correct) {
      _feedbackController.forward(from: 0);
    }

    setState(() {
      _checked = true;
    });

    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Perfect word order! 🎯'
          : 'Try again. Translation: ${widget.task.translation}',
    );
  }

  void _reset() {
    setState(() {
      _currentOrder = List.from(widget.task.fragments);
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
            // Title
            Text(
              'Put the words in order',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: VibrantSpacing.sm),

            // Instruction
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.md,
                vertical: VibrantSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, size: 18, color: colorScheme.primary),
                  const SizedBox(width: VibrantSpacing.sm),
                  Expanded(
                    child: Text(
                      'Drag to reorder • ${widget.task.translation}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Reorderable list
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: _checked
                  ? (int old, int newIdx) {}
                  : (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _currentOrder.removeAt(oldIndex);
                        _currentOrder.insert(newIndex, item);
                      });
                    },
              children: _currentOrder.asMap().entries.map((entry) {
                final index = entry.key;
                final fragment = entry.value;
                final isCorrectPosition =
                    _checked &&
                    widget.task.correctOrder[index] ==
                        widget.task.fragments.indexOf(fragment);

                return _buildFragmentCard(
                  fragment,
                  index,
                  isCorrectPosition,
                  theme,
                  colorScheme,
                );
              }).toList(),
            ),

            if (_checked) ...[
              const SizedBox(height: VibrantSpacing.xl),
              _buildFeedback(theme, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFragmentCard(
    String fragment,
    int index,
    bool isCorrectPosition,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AnimatedContainer(
      key: ValueKey(fragment),
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
      decoration: BoxDecoration(
        color: _checked
            ? (isCorrectPosition
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1))
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: _checked
              ? (isCorrectPosition ? Colors.green : Colors.red)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: _checked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _checked
                ? (isCorrectPosition
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2))
                : colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: VibrantSpacing.lg,
            vertical: VibrantSpacing.sm,
          ),
          leading: CircleAvatar(
            backgroundColor: _checked
                ? (isCorrectPosition
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2))
                : colorScheme.primaryContainer,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _checked
                    ? (isCorrectPosition ? Colors.green[800] : Colors.red[800])
                    : colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            fragment,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _checked
                  ? (isCorrectPosition ? Colors.green[800] : Colors.red[800])
                  : colorScheme.onSurface,
            ),
          ),
          trailing: _checked
              ? Icon(
                  isCorrectPosition ? Icons.check_circle : Icons.cancel,
                  color: isCorrectPosition ? Colors.green : Colors.red,
                )
              : Icon(Icons.drag_indicator, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildFeedback(ThemeData theme, ColorScheme colorScheme) {
    final userOrder = _currentOrder
        .map((frag) => widget.task.fragments.indexOf(frag))
        .toList();
    final correct = userOrder.toString() == widget.task.correctOrder.toString();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.info_outline,
                  color: correct ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Text(
                  correct ? 'Correct!' : 'Keep trying!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: correct ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            if (!correct) ...[
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'Expected translation: ${widget.task.translation}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
