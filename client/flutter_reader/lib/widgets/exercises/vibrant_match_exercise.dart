import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart';
import 'exercise_control.dart';

/// Enhanced match exercise with card flip animations
class VibrantMatchExercise extends StatefulWidget {
  const VibrantMatchExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final MatchTask task;
  final LessonExerciseHandle handle;

  @override
  State<VibrantMatchExercise> createState() => _VibrantMatchExerciseState();
}

class _VibrantMatchExerciseState extends State<VibrantMatchExercise> {
  final Map<int, int> _matches = {};
  int? _selectedLeft;
  int? _selectedRight;
  bool _checked = false;
  final Set<int> _correctMatches = {};
  final Set<int> _wrongMatches = {};
  final List<Widget> _sparkles = [];

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _matches.length == widget.task.pairs.length,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantMatchExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _matches.length == widget.task.pairs.length,
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
    if (_matches.length != widget.task.pairs.length) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Match all pairs first',
      );
    }

    int correctCount = 0;
    final Set<int> correct = {};
    final Set<int> wrong = {};

    for (int i = 0; i < widget.task.pairs.length; i++) {
      final pair = widget.task.pairs[i];
      final matchedRightIndex = _matches[i];
      if (matchedRightIndex != null) {
        final matchedPair = widget.task.pairs[matchedRightIndex];
        if (pair.en == matchedPair.en) {
          correctCount++;
          correct.add(i);
        } else {
          wrong.add(i);
        }
      }
    }

    setState(() {
      _checked = true;
      _correctMatches.addAll(correct);
      _wrongMatches.addAll(wrong);
    });

    final allCorrect = correctCount == widget.task.pairs.length;
    if (allCorrect) {
      HapticService.success();
      SoundService.instance.success();
      _showSparkles();
    } else {
      HapticService.error();
      SoundService.instance.error();
    }

    return LessonCheckFeedback(
      correct: allCorrect,
      message: allCorrect
          ? 'Perfect! All matches are correct.'
          : 'You got $correctCount out of ${widget.task.pairs.length} correct.',
    );
  }

  void _showSparkles() {
    final sparkle = Positioned(
      left: 0,
      right: 0,
      top: 100,
      child: Center(
        child: StarBurst(
          color: const Color(0xFFFBBF24),
          particleCount: 20,
          size: 150,
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
      _matches.clear();
      _selectedLeft = null;
      _selectedRight = null;
      _checked = false;
      _correctMatches.clear();
      _wrongMatches.clear();
      _sparkles.clear();
    });
    widget.handle.notify();
  }

  void _handleLeftTap(int index) {
    if (_checked) return;

    HapticService.light();
    SoundService.instance.tap();
    setState(() {
      if (_selectedLeft == index) {
        _selectedLeft = null;
      } else {
        _selectedLeft = index;
        if (_selectedRight != null) {
          _matches[index] = _selectedRight!;
          _selectedLeft = null;
          _selectedRight = null;
          HapticService.medium();
          widget.handle.notify();
        }
      }
    });
  }

  void _handleRightTap(int index) {
    if (_checked) return;

    HapticService.light();
    SoundService.instance.tap();
    setState(() {
      if (_selectedRight == index) {
        _selectedRight = null;
      } else {
        _selectedRight = index;
        if (_selectedLeft != null) {
          _matches[_selectedLeft!] = index;
          _selectedLeft = null;
          _selectedRight = null;
          HapticService.medium();
          widget.handle.notify();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final leftItems = List.generate(
      widget.task.pairs.length,
      (i) => widget.task.pairs[i],
    );
    final rightItems = List.generate(
      widget.task.pairs.length,
      (i) => widget.task.pairs[i],
    )..shuffle();

    return Stack(
      children: [
        Column(
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
                      Icons.connect_without_contact_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.md),
                  Expanded(
                    child: Text(
                      'Match the pairs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VibrantSpacing.xs),

            SlideInFromBottom(
              delay: const Duration(milliseconds: 150),
              child: Text(
                'Tap one card from each column to match them',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Match grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    children: List.generate(
                      leftItems.length,
                      (i) => SlideInFromBottom(
                        delay: Duration(milliseconds: 200 + i * 50),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: VibrantSpacing.md,
                          ),
                          child: _MatchCard(
                            text: leftItems[i].grc,
                            isSelected: _selectedLeft == i,
                            isMatched: _matches.containsKey(i),
                            isCorrect: _correctMatches.contains(i),
                            isWrong: _wrongMatches.contains(i),
                            isChecked: _checked,
                            onTap: () => _handleLeftTap(i),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: VibrantSpacing.lg),

                // Right column
                Expanded(
                  child: Column(
                    children: List.generate(rightItems.length, (i) {
                      final rightIndex = widget.task.pairs.indexOf(
                        rightItems[i],
                      );
                      final isMatched = _matches.values.contains(rightIndex);
                      final matchedLeftIndex = _matches.entries
                          .where((e) => e.value == rightIndex)
                          .map((e) => e.key)
                          .firstOrNull;

                      return SlideInFromBottom(
                        delay: Duration(milliseconds: 200 + i * 50),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: VibrantSpacing.md,
                          ),
                          child: _MatchCard(
                            text: rightItems[i].en,
                            isSelected: _selectedRight == rightIndex,
                            isMatched: isMatched,
                            isCorrect:
                                matchedLeftIndex != null &&
                                _correctMatches.contains(matchedLeftIndex),
                            isWrong:
                                matchedLeftIndex != null &&
                                _wrongMatches.contains(matchedLeftIndex),
                            isChecked: _checked,
                            onTap: () => _handleRightTap(rightIndex),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            // Progress indicator
            if (!_checked) ...[
              const SizedBox(height: VibrantSpacing.md),
              Center(
                child: Text(
                  '${_matches.length} / ${widget.task.pairs.length} matched',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            // Feedback
            if (_checked) ...[
              const SizedBox(height: VibrantSpacing.xl),
              ScaleIn(
                child: InlineFeedback(
                  isCorrect: _wrongMatches.isEmpty,
                  message: _wrongMatches.isEmpty
                      ? 'Perfect! All matches are correct.'
                      : 'Some matches are incorrect. Try again!',
                ),
              ),
            ],
          ],
        ),
        ..._sparkles,
      ],
    );
  }
}

class _MatchCard extends StatefulWidget {
  const _MatchCard({
    required this.text,
    required this.isSelected,
    required this.isMatched,
    required this.isCorrect,
    required this.isWrong,
    required this.isChecked,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isMatched;
  final bool isCorrect;
  final bool isWrong;
  final bool isChecked;
  final VoidCallback onTap;

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: VibrantCurve.smooth),
    );
  }

  @override
  void didUpdateWidget(_MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMatched != widget.isMatched && widget.isMatched) {
      _flipController.forward();
    }
    if (oldWidget.isChecked != widget.isChecked && widget.isChecked) {
      if (widget.isWrong) {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getBackgroundColor() {
      if (widget.isChecked) {
        if (widget.isCorrect) return colorScheme.tertiaryContainer;
        if (widget.isWrong) return colorScheme.errorContainer;
      }
      if (widget.isSelected) return colorScheme.primaryContainer;
      if (widget.isMatched) return colorScheme.surfaceContainerHigh;
      return colorScheme.surface;
    }

    Color getBorderColor() {
      if (widget.isChecked) {
        if (widget.isCorrect) return colorScheme.tertiary;
        if (widget.isWrong) return colorScheme.error;
      }
      if (widget.isSelected) return colorScheme.primary;
      return colorScheme.outline;
    }

    return AnimatedScaleButton(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value;
          final isFront = angle < math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              height: 72,
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                color: getBackgroundColor(),
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                border: Border.all(color: getBorderColor(), width: 2),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : VibrantShadow.sm(colorScheme),
              ),
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(isFront ? 0 : math.pi),
                  child: Text(
                    widget.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.isChecked
                          ? (widget.isCorrect
                                ? colorScheme.onTertiaryContainer
                                : (widget.isWrong
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onSurface))
                          : colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
