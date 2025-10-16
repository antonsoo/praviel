import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Word bank exercise with drag-and-drop word ordering
class VibrantWordBankExercise extends StatefulWidget {
  const VibrantWordBankExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final WordBankTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantWordBankExercise> createState() =>
      _VibrantWordBankExerciseState();
}

class _VibrantWordBankExerciseState extends State<VibrantWordBankExercise> {
  late List<String> _orderedWords;
  late List<String> _availableWords;
  bool _checked = false;
  bool? _correct;
  final GlobalKey<ErrorShakeWrapperState> _shakeKey = GlobalKey();
  final List<Widget> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _orderedWords = [];
    _availableWords = List.from(widget.task.words)..shuffle();
    widget.handle.attach(
      canCheck: () => _orderedWords.length == widget.task.words.length,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantWordBankExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _orderedWords.length == widget.task.words.length,
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
    if (_orderedWords.length != widget.task.words.length) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Arrange all words first',
      );
    }

    // Check if the order matches the correct order
    final correctIndices = widget.task.correctOrder;
    final expectedWords = correctIndices
        .map((i) => widget.task.words[i])
        .toList();
    final correct = _orderedWords.join(' ') == expectedWords.join(' ');

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
          ? 'Perfect word order!'
          : 'The correct order is: ${expectedWords.join(" ")}',
    );
  }

  void _showSparkles() {
    final sparkle = Positioned(
      left: 0,
      right: 0,
      top: 200,
      child: Center(
        child: StarBurst(
          color: const Color(0xFFFBBF24),
          particleCount: 18,
          size: 130,
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
      _orderedWords = [];
      _availableWords = List.from(widget.task.words)..shuffle();
      _checked = false;
      _correct = null;
      _sparkles.clear();
    });
    widget.handle.notify();
  }

  void _moveWordToOrdered(String word) {
    if (_checked) return;
    HapticService.light();
    SoundService.instance.tap();
    setState(() {
      _availableWords.remove(word);
      _orderedWords.add(word);
    });
    widget.handle.notify();
  }

  void _moveWordToAvailable(String word) {
    if (_checked) return;
    HapticService.light();
    SoundService.instance.tap();
    setState(() {
      _orderedWords.remove(word);
      _availableWords.add(word);
    });
    widget.handle.notify();
  }

  void _reorderWord(int oldIndex, int newIndex) {
    if (_checked) return;
    HapticService.light();
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final word = _orderedWords.removeAt(oldIndex);
      _orderedWords.insert(newIndex, word);
    });
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
              // Title
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
                        Icons.reorder_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: Text(
                        'Word Bank',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VibrantSpacing.md),

              // Instructions
              SlideInFromBottom(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'Arrange these words in the correct order:',
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: VibrantSpacing.md),

              // Translation
              SlideInFromBottom(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  child: Text(
                    widget.task.translation,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Ordered words area (drop target)
              SlideInFromBottom(
                delay: const Duration(milliseconds: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your answer:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Container(
                      constraints: const BoxConstraints(minHeight: 80),
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                        border: Border.all(
                          color: colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: _orderedWords.isEmpty
                          ? Center(
                              child: Text(
                                'Tap words below to add them here',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              onReorder: _reorderWord,
                              children: _orderedWords.map((word) {
                                return Padding(
                                  key: ValueKey(word),
                                  padding: const EdgeInsets.only(
                                    bottom: VibrantSpacing.sm,
                                  ),
                                  child: AnimatedScaleButton(
                                    onTap: () => _moveWordToAvailable(word),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: VibrantSpacing.md,
                                        vertical: VibrantSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: VibrantTheme.heroGradient,
                                        borderRadius: BorderRadius.circular(
                                          VibrantRadius.sm,
                                        ),
                                        boxShadow: VibrantShadow.sm(
                                          colorScheme,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          if (!_checked)
                                            Icon(
                                              Icons.drag_indicator_rounded,
                                              size: 20,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          if (!_checked)
                                            const SizedBox(
                                              width: VibrantSpacing.xs,
                                            ),
                                          Expanded(
                                            child: Text(
                                              word,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'NotoSerif',
                                                  ),
                                            ),
                                          ),
                                          if (!_checked)
                                            Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Available words
              if (_availableWords.isNotEmpty) ...[
                SlideInFromBottom(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'Available words:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                SlideInFromBottom(
                  delay: const Duration(milliseconds: 350),
                  child: Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    children: _availableWords.map((word) {
                      return AnimatedScaleButton(
                        onTap: () => _moveWordToOrdered(word),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.md,
                            vertical: VibrantSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              VibrantRadius.sm,
                            ),
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 1.5,
                            ),
                            boxShadow: VibrantShadow.sm(colorScheme),
                          ),
                          child: Text(
                            word,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontFamily: 'NotoSerif',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Feedback
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.xl),
                ScaleIn(
                  child: InlineFeedback(
                    isCorrect: _correct!,
                    message: _correct!
                        ? 'Perfect word order!'
                        : 'Correct order: ${widget.task.correctOrder.map((i) => widget.task.words[i]).join(" ")}',
                  ),
                ),
              ],
            ],
          ),
        ),
        ..._sparkles,
      ],
    );
  }
}
