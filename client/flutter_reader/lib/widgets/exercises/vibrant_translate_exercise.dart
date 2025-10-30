import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Enhanced translate exercise with hints and word-by-word help
class VibrantTranslateExercise extends StatefulWidget {
  const VibrantTranslateExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final TranslateTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantTranslateExercise> createState() =>
      _VibrantTranslateExerciseState();
}

class _VibrantTranslateExerciseState extends State<VibrantTranslateExercise> {
  late final TextEditingController _controller;
  bool _checked = false;
  bool? _correct;
  bool _showHints = false;
  final GlobalKey<ErrorShakeWrapperState> _shakeKey = GlobalKey();
  final List<Widget> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    widget.handle.attach(
      canCheck: () => _controller.text.trim().isNotEmpty,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantTranslateExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _controller.text.trim().isNotEmpty,
        check: _check,
        reset: _reset,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Enter your translation',
      );
    }

    // Simple check - use sampleSolution if available, otherwise rubric
    final expected = (widget.task.sampleSolution ?? widget.task.rubric)
        .toLowerCase();
    final got = answer.toLowerCase();

    // Check for exact match or close match
    final correct = got == expected || _isSimilar(got, expected);

    setState(() {
      _checked = true;
      _correct = correct;
    });

    if (!correct) {
      _shakeKey.currentState?.shake();
      SoundService.instance.error();
    } else {
      HapticService.success();
      SoundService.instance.success();
      _showSparkles();
    }

    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Excellent translation!'
          : 'Expected: ${widget.task.sampleSolution ?? widget.task.rubric}',
    );
  }

  bool _isSimilar(String a, String b) {
    // Simple similarity check - could be enhanced with Levenshtein distance
    final wordsA = a.split(' ');
    final wordsB = b.split(' ');

    if (wordsA.length != wordsB.length) return false;

    int matches = 0;
    for (int i = 0; i < wordsA.length; i++) {
      if (wordsA[i] == wordsB[i] ||
          wordsA[i].contains(wordsB[i]) ||
          wordsB[i].contains(wordsA[i])) {
        matches++;
      }
    }

    return matches >= wordsA.length * 0.8; // 80% similarity
  }

  void _showSparkles() {
    final sparkle = Positioned(
      left: 0,
      right: 0,
      top: 150,
      child: Center(
        child: StarBurst(
          color: const Color(0xFFFBBF24),
          particleCount: 16,
          size: 120,
        ),
      ),
    );
    setState(() => _sparkles.add(sparkle));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _sparkles.clear());
    });
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _checked = false;
      _correct = null;
      _showHints = false;
      _sparkles.clear();
    });
    widget.handle.notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        ErrorShakeWrapper(
          key: _shakeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              ScaleIn(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: VibrantTheme.heroGradient,
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: Text(
                        'Translate to English',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Greek text to translate
              SlideInFromBottom(
                delay: const Duration(milliseconds: 200),
                child: PulseCard(
                  color: colorScheme.surfaceContainerLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.text,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: VibrantSpacing.md),
                      Row(
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: VibrantSpacing.xs),
                          Text(
                            'Tap to hear pronunciation',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: VibrantSpacing.lg),

              // Hint button
              if (!_checked)
                SlideInFromBottom(
                  delay: const Duration(milliseconds: 300),
                  child: TextButton.icon(
                    onPressed: () {
                      HapticService.light();
                      setState(() {
                        _showHints = !_showHints;
                      });
                    },
                    icon: Icon(
                      _showHints
                          ? Icons.lightbulb_rounded
                          : Icons.lightbulb_outline_rounded,
                    ),
                    label: Text(_showHints ? 'Hide hints' : 'Show hints'),
                  ),
                ),

              // Hints panel
              if (_showHints && !_checked) ...[
                const SizedBox(height: VibrantSpacing.md),
                ScaleIn(
                  child: Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: VibrantSpacing.sm),
                            Text(
                              'Hint',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VibrantSpacing.sm),
                        Text(
                          'Word order: ${widget.task.text.split(' ').length} words',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: VibrantSpacing.xs),
                        Text(
                          'First word means: "${(widget.task.sampleSolution ?? widget.task.rubric).split(' ').first}"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: VibrantSpacing.xl),

              // Translation input
              SlideInFromBottom(
                delay: const Duration(milliseconds: 400),
                child: TextField(
                  controller: _controller,
                  enabled: !(_checked && _correct == true), // Only disable if correct
                  maxLines: 3,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Your translation',
                    hintText: 'Type your English translation here...',
                    alignLabelWithHint: true,
                    helperText: _checked && _correct == false
                        ? 'Try again! Edit your answer and click Check'
                        : 'Try to capture the meaning of the Greek text',
                    suffixIcon: _checked && _correct != null
                        ? Icon(
                            _correct!
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _correct!
                                ? colorScheme.tertiary
                                : colorScheme.error,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                  ),
                  onChanged: (text) {
                    // Reset checked state when user edits after wrong answer
                    if (_checked && _correct == false) {
                      setState(() {
                        _checked = false;
                        _correct = null;
                      });
                    }
                    widget.handle.notify();
                  },
                ),
              ),

              // Feedback
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.xl),
                ScaleIn(
                  child: InlineFeedback(
                    isCorrect: _correct!,
                    message: _correct!
                        ? 'Great translation! Your understanding is excellent.'
                        : 'The expected translation is: "${widget.task.sampleSolution ?? widget.task.rubric}"',
                  ),
                ),
                if (!_correct!) ...[
                  const SizedBox(height: VibrantSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: VibrantSpacing.sm),
                            Text(
                              'Explanation',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VibrantSpacing.sm),
                        Text(
                          'In Greek, word order can be flexible. Focus on the root meanings of each word.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        ..._sparkles,
      ],
    );
  }
}
