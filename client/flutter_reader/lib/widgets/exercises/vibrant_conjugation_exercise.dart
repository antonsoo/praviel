import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import 'exercise_control.dart';

/// Verb conjugation exercise with grammatical context
class VibrantConjugationExercise extends StatefulWidget {
  const VibrantConjugationExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final ConjugationTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantConjugationExercise> createState() =>
      _VibrantConjugationExerciseState();
}

class _VibrantConjugationExerciseState extends State<VibrantConjugationExercise>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _checked = false;
  bool? _correct;
  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    widget.handle.attach(
      canCheck: () => _controller.text.trim().isNotEmpty,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _feedbackController.dispose();
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Enter your answer',
      );
    }

    final correct = answer == widget.task.answer;
    if (correct) {
      _feedbackController.forward(from: 0);
    }
    setState(() {
      _checked = true;
      _correct = correct;
    });

    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Excellent conjugation! 📝'
          : 'Correct answer: ${widget.task.answer}',
    );
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _checked = false;
      _correct = null;
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
            // Title with grammar icon
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
                    Icons.edit_note,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    'Conjugate the verb',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Verb info card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Verb header
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(VibrantRadius.lg - 2),
                        topRight: Radius.circular(VibrantRadius.lg - 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INFINITIVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: VibrantSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.task.verbInfinitive,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VibrantSpacing.xs),
                        Text(
                          widget.task.verbMeaning,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grammatical parameters
                  Padding(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildParamChip(
                            'Person',
                            widget.task.person,
                            Icons.person,
                            colorScheme,
                            theme,
                          ),
                        ),
                        const SizedBox(width: VibrantSpacing.md),
                        Expanded(
                          child: _buildParamChip(
                            'Tense',
                            widget.task.tense,
                            Icons.access_time,
                            colorScheme,
                            theme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Answer input field
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                boxShadow: [
                  if (_checked && _correct == true)
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  else if (_checked && _correct == false)
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: TextField(
                controller: _controller,
                enabled: !_checked,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _checked
                      ? (_correct == true ? Colors.green[800] : Colors.red[800])
                      : colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Your answer',
                  hintText: 'Type the conjugated form...',
                  labelStyle: TextStyle(
                    color: _checked
                        ? (_correct == true ? Colors.green : Colors.red)
                        : colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: _correct == true ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: _checked
                      ? (_correct == true
                            ? Colors.green.withValues(alpha: 0.05)
                            : Colors.red.withValues(alpha: 0.05))
                      : colorScheme.surfaceContainerHighest,
                  suffixIcon: _checked
                      ? Icon(
                          _correct == true ? Icons.check_circle : Icons.cancel,
                          color: _correct == true ? Colors.green : Colors.red,
                          size: 32,
                        )
                      : null,
                  contentPadding: const EdgeInsets.all(VibrantSpacing.lg),
                ),
              ),
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

  Widget _buildParamChip(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: VibrantSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.xxs),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback(ThemeData theme, ColorScheme colorScheme) {
    return ScaleIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          color: _correct == true
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: _correct == true ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _correct == true ? Icons.check_circle : Icons.info_outline,
                  color: _correct == true ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    _correct == true
                        ? 'Excellent conjugation! 📝'
                        : 'Incorrect conjugation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _correct == true
                          ? Colors.green[800]
                          : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            if (_correct == false) ...[
              const SizedBox(height: VibrantSpacing.md),
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Row(
                  children: [
                    Text(
                      'Correct answer: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.task.answer,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
