import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  matching,
}

enum QuestionDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class QuizQuestion {
  final String id;
  final QuestionType type;
  final QuestionDifficulty difficulty;
  final String question;
  final List<String> options; // For multiple choice
  final String correctAnswer;
  final String? explanation;
  final String? hint;
  final int points;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.hint,
    this.points = 10,
  });
}

class QuizResult {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final Duration timeSpent;
  final Map<String, bool> answerResults; // questionId -> isCorrect

  const QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.answerResults,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;
}

/// Reading comprehension quiz with multiple question types
class ComprehensionQuiz extends StatefulWidget {
  const ComprehensionQuiz({
    super.key,
    required this.questions,
    required this.onComplete,
    this.passageTitle,
    this.passageReference,
    this.timeLimit,
  });

  final List<QuizQuestion> questions;
  final Function(QuizResult) onComplete;
  final String? passageTitle;
  final String? passageReference;
  final Duration? timeLimit;

  @override
  State<ComprehensionQuiz> createState() => _ComprehensionQuizState();
}

class _ComprehensionQuizState extends State<ComprehensionQuiz> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final Map<String, String> _userAnswers = {};
  final Map<String, bool> _answerResults = {};
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _showHint = false;
  late AnimationController _progressController;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);

      // Check time limit
      if (widget.timeLimit != null && _elapsedSeconds >= widget.timeLimit!.inSeconds) {
        _timer?.cancel();
        _finishQuiz();
      }
    });
  }

  void _answerQuestion(String answer) {
    final question = widget.questions[_currentQuestionIndex];
    final isCorrect = answer == question.correctAnswer;

    setState(() {
      _userAnswers[question.id] = answer;
      _answerResults[question.id] = isCorrect;
      _showHint = false;
    });

    HapticService.medium();
    if (isCorrect) {
      SoundService.instance.success();
    } else {
      SoundService.instance.error();
    }

    // Auto-advance after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_currentQuestionIndex < widget.questions.length - 1) {
          setState(() => _currentQuestionIndex++);
          _progressController.forward(from: 0);
        } else {
          _finishQuiz();
        }
      }
    });
  }

  void _finishQuiz() {
    _timer?.cancel();

    final totalCorrect = _answerResults.values.where((v) => v).length;
    final totalScore = widget.questions
        .where((q) => _answerResults[q.id] == true)
        .fold(0, (sum, q) => sum + q.points);

    final result = QuizResult(
      score: totalScore,
      totalQuestions: widget.questions.length,
      correctAnswers: totalCorrect,
      timeSpent: Duration(seconds: _elapsedSeconds),
      answerResults: _answerResults,
    );

    // Celebrate if passed
    if (result.percentage >= 70) {
      _celebrationController.forward();
      HapticService.success();
      SoundService.instance.celebration();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onComplete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final question = widget.questions[_currentQuestionIndex];
    final hasAnswered = _userAnswers.containsKey(question.id);
    final isCorrect = _answerResults[question.id] ?? false;

    return Column(
      children: [
        // Header with progress
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          decoration: BoxDecoration(
            gradient: VibrantTheme.heroGradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(VibrantRadius.xl),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Title and reference
                if (widget.passageTitle != null) ...[
                  Text(
                    widget.passageTitle!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.passageReference != null)
                    Text(
                      widget.passageReference!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  const SizedBox(height: VibrantSpacing.md),
                ],

                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(VibrantRadius.full),
                        child: LinearProgressIndicator(
                          value: (_currentQuestionIndex + 1) / widget.questions.length,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Text(
                      '${_currentQuestionIndex + 1}/${widget.questions.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: VibrantSpacing.sm),

                // Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: VibrantSpacing.xs),
                        Text(
                          _formatTime(_elapsedSeconds),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(question.difficulty),
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      ),
                      child: Text(
                        _getDifficultyLabel(question.difficulty),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    question.question,
                    style: theme.textTheme.titleLarge?.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: VibrantSpacing.xl),

                // Options
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _userAnswers[question.id] == option;
                  final showResult = hasAnswered;

                  Color? backgroundColor;
                  Color? borderColor;
                  if (showResult) {
                    if (option == question.correctAnswer) {
                      backgroundColor = Colors.green.withValues(alpha: 0.2);
                      borderColor = Colors.green;
                    } else if (isSelected) {
                      backgroundColor = Colors.red.withValues(alpha: 0.2);
                      borderColor = Colors.red;
                    }
                  } else if (isSelected) {
                    backgroundColor = colorScheme.primaryContainer.withValues(alpha: 0.5);
                    borderColor = colorScheme.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: hasAnswered ? null : () => _answerQuestion(option),
                        borderRadius: BorderRadius.circular(VibrantRadius.lg),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(VibrantSpacing.md),
                          decoration: BoxDecoration(
                            color: backgroundColor ?? colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(VibrantRadius.lg),
                            border: Border.all(
                              color: borderColor ?? colorScheme.outline.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: borderColor?.withValues(alpha: 0.2) ??
                                      colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: borderColor ?? colorScheme.outline,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index), // A, B, C, D
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: borderColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: VibrantSpacing.md),
                              Expanded(
                                child: Text(
                                  option,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (showResult && option == question.correctAnswer)
                                Icon(Icons.check_circle_rounded, color: Colors.green),
                              if (showResult && isSelected && !isCorrect)
                                Icon(Icons.cancel_rounded, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Hint button
                if (!hasAnswered && question.hint != null) ...[
                  const SizedBox(height: VibrantSpacing.md),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showHint = !_showHint);
                      HapticService.light();
                    },
                    icon: Icon(_showHint ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded),
                    label: Text(_showHint ? 'Hide Hint' : 'Show Hint'),
                  ),
                  if (_showHint)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: VibrantSpacing.sm),
                          Expanded(
                            child: Text(
                              question.hint!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Explanation (after answering)
                if (hasAnswered && question.explanation != null) ...[
                  const SizedBox(height: VibrantSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.blue,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: isCorrect ? Colors.green : Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: VibrantSpacing.sm),
                            Text(
                              'Explanation',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isCorrect ? Colors.green : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VibrantSpacing.sm),
                        Text(
                          question.explanation!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Next button (after answering)
        if (hasAnswered)
          Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentQuestionIndex < widget.questions.length - 1) {
                    setState(() => _currentQuestionIndex++);
                    _progressController.forward(from: 0);
                    HapticService.light();
                    SoundService.instance.tap();
                  } else {
                    _finishQuiz();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < widget.questions.length - 1
                      ? 'Next Question'
                      : 'Finish Quiz',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getDifficultyColor(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return Colors.green;
      case QuestionDifficulty.medium:
        return Colors.orange;
      case QuestionDifficulty.hard:
        return Colors.red;
      case QuestionDifficulty.expert:
        return Colors.purple;
    }
  }

  String _getDifficultyLabel(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
      case QuestionDifficulty.expert:
        return 'Expert';
    }
  }
}

/// Quiz results summary screen
class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onContinue,
  });

  final QuizResult result;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final passed = result.percentage >= 70;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          children: [
            // Result icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: passed
                    ? LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700])
                    : LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade700]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (passed ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Result text
            Text(
              passed ? 'Excellent Work!' : 'Keep Practicing!',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.md),

            // Score percentage
            Text(
              '${result.percentage.toInt()}%',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green : Colors.orange,
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Stats
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
              ),
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Correct Answers',
                    value: '${result.correctAnswers}/${result.totalQuestions}',
                    color: Colors.green,
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  _StatRow(
                    icon: Icons.stars_rounded,
                    label: 'Total Score',
                    value: '${result.score} pts',
                    color: Colors.amber,
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  _StatRow(
                    icon: Icons.timer_outlined,
                    label: 'Time Spent',
                    value: _formatDuration(result.timeSpent),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue Learning'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  ),
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Quiz'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: VibrantSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
