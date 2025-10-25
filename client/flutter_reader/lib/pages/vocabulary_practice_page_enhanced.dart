import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_api.dart';
import '../services/byok_controller.dart';
import '../services/language_preferences.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/layout/vibrant_background.dart';
import '../widgets/error/provider_error_widgets.dart';

/// Enhanced vocabulary practice page with premium animations and error handling
class VocabularyPracticePageEnhanced extends ConsumerStatefulWidget {
  const VocabularyPracticePageEnhanced({super.key, required this.vocabularyApi});

  final VocabularyApi vocabularyApi;

  @override
  ConsumerState<VocabularyPracticePageEnhanced> createState() =>
      _VocabularyPracticePageEnhancedState();
}

enum _PracticeStatus { idle, loading, ready, practicing, complete, error }

class _VocabularyPracticePageEnhancedState
    extends ConsumerState<VocabularyPracticePageEnhanced>
    with SingleTickerProviderStateMixin {
  _PracticeStatus _status = _PracticeStatus.idle;
  List<VocabularyWord> _words = [];
  int _currentIndex = 0;
  String? _error;
  final ProficiencyLevel _proficiencyLevel = ProficiencyLevel.beginner;
  VocabularyDifficulty? _difficulty;
  int _correct = 0;
  int _totalAttempts = 0;
  String _userAnswer = '';
  bool? _lastAnswerCorrect;
  final TextEditingController _answerController = TextEditingController();
  final List<bool> _results = [];
  int _currentStreak = 0;
  int _bestStreak = 0;

  late AnimationController _cardAnimationController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _cardSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOut),
    );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generate();
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _status = _PracticeStatus.loading;
      _error = null;
    });

    try {
      final settings = await ref.read(byokControllerProvider.future);
      final selectedLanguage = ref.read(selectedLanguageProvider);

      String? apiKey;
      final provider = settings.lessonProvider.trim().isEmpty
          ? 'echo'
          : settings.lessonProvider.trim();
      if (provider != 'echo' && settings.hasKey) {
        apiKey = settings.apiKey;
      }

      final request = VocabularyGenerationRequest(
        languageCode: selectedLanguage,
        proficiencyLevel: _proficiencyLevel,
        difficulty: _difficulty,
        count: 10,
        provider: provider != 'echo' ? provider : null,
        model: settings.lessonModel,
      );

      final response = await widget.vocabularyApi.generate(
        request,
        apiKey: apiKey,
      );

      if (!mounted) return;

      setState(() {
        _words = response.words;
        _currentIndex = 0;
        _correct = 0;
        _totalAttempts = 0;
        _results.clear();
        _currentStreak = 0;
        _bestStreak = 0;
        _status = _PracticeStatus.ready;
      });

      _cardAnimationController.forward(from: 0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _PracticeStatus.error;
        _error = error.toString();
      });
    }
  }

  void _checkAnswer() {
    if (_userAnswer.trim().isEmpty || _words.isEmpty) return;

    final currentWord = _words[_currentIndex];
    final correctTranslation = currentWord.translation.toLowerCase().trim();
    final userTranslation = _userAnswer.toLowerCase().trim();

    final isCorrect = correctTranslation.contains(userTranslation) ||
        userTranslation.contains(correctTranslation);

    setState(() {
      _lastAnswerCorrect = isCorrect;
      if (isCorrect) {
        _correct++;
        _currentStreak++;
        if (_currentStreak > _bestStreak) {
          _bestStreak = _currentStreak;
        }
      } else {
        _currentStreak = 0;
      }
      _totalAttempts++;
      _results.add(isCorrect);
    });

    // Enhanced haptic feedback
    if (isCorrect) {
      if (_currentStreak >= 5) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    } else {
      HapticFeedback.lightImpact();
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex >= _words.length - 1) {
      setState(() {
        _status = _PracticeStatus.complete;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _currentIndex++;
      _userAnswer = '';
      _lastAnswerCorrect = null;
      _answerController.clear();
    });

    _cardAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vocabulary Practice',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          if (_status == _PracticeStatus.ready || _status == _PracticeStatus.practicing) ...[
            if (_currentStreak >= 3)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1.05),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade700,
                                Colors.deepOrange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_currentStreak',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      // Loop the animation
                      setState(() {});
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_correct / $_totalAttempts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: VibrantBackground(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_status) {
      case _PracticeStatus.idle:
      case _PracticeStatus.loading:
        return _buildLoadingState(context);
      case _PracticeStatus.error:
        return _buildErrorState(context);
      case _PracticeStatus.ready:
      case _PracticeStatus.practicing:
        return _buildPracticeState(context);
      case _PracticeStatus.complete:
        return _buildCompleteState(context);
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 6.28,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              );
            },
            onEnd: () {
              if (_status == _PracticeStatus.loading && mounted) {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: VibrantSpacing.xl),
          Text(
            'Generating vocabulary...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            'Preparing your personalized practice',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline_rounded,
      title: 'Generation Failed',
      message: _error ?? 'Unknown error occurred',
      action: RetryButton(
        onRetry: () async {
          HapticService.medium();
          await _generate();
        },
        label: 'Try Again',
      ),
    );
  }

  Widget _buildPracticeState(BuildContext context) {
    if (_words.isEmpty) return const SizedBox();

    final currentWord = _words[_currentIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (_currentIndex + 1) / _words.length;

    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value),
          child: Opacity(
            opacity: _cardFadeAnimation.value,
            child: child,
          ),
        );
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress bar with animation
              Row(
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of ${_words.length}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.sm),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  );
                },
              ),
              const SizedBox(height: VibrantSpacing.xxl),

              // Word card with gradient
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.xxl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(VibrantRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 48,
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    Text(
                      currentWord.word,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (currentWord.exampleSentence != null && currentWord.exampleSentence!.isNotEmpty) ...[
                      const SizedBox(height: VibrantSpacing.md),
                      Text(
                        currentWord.exampleSentence!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: VibrantSpacing.xxl),

              // Answer field
              TextField(
                controller: _answerController,
                enabled: _lastAnswerCorrect == null,
                decoration: InputDecoration(
                  labelText: 'Your Translation',
                  hintText: 'Enter the translation...',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
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
                ),
                onChanged: (value) {
                  setState(() {
                    _userAnswer = value;
                  });
                },
                onSubmitted: (_) => _checkAnswer(),
              ),
              const SizedBox(height: VibrantSpacing.lg),

              // Submit button
              FilledButton.icon(
                onPressed: _userAnswer.trim().isEmpty || _lastAnswerCorrect != null
                    ? null
                    : () {
                        HapticService.medium();
                        _checkAnswer();
                      },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Check Answer'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  ),
                ),
              ),

              // Feedback
              if (_lastAnswerCorrect != null) ...[
                const SizedBox(height: VibrantSpacing.xl),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: _lastAnswerCorrect!
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    border: Border.all(
                      color: _lastAnswerCorrect! ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _lastAnswerCorrect!
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _lastAnswerCorrect! ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: VibrantSpacing.sm),
                          Text(
                            _lastAnswerCorrect! ? 'Correct!' : 'Incorrect',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: _lastAnswerCorrect! ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (!_lastAnswerCorrect!) ...[
                        const SizedBox(height: VibrantSpacing.md),
                        Text(
                          'Correct answer: ${currentWord.translation}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accuracy = _totalAttempts > 0 ? (_correct / _totalAttempts * 100).toInt() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(VibrantSpacing.xxl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: VibrantSpacing.xxl),
            Text(
              'Practice Complete!',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xl),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Score', '$_correct/$_totalAttempts', Icons.check_circle, colorScheme),
                _buildStatCard('Accuracy', '$accuracy%', Icons.percent, colorScheme),
                _buildStatCard('Best Streak', '$_bestStreak', Icons.local_fire_department, colorScheme),
              ],
            ),
            const SizedBox(height: VibrantSpacing.xxl),
            // Actions
            FilledButton.icon(
              onPressed: () {
                HapticService.medium();
                _generate();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Practice Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.xxl,
                  vertical: VibrantSpacing.lg,
                ),
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.xxl,
                  vertical: VibrantSpacing.lg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: VibrantSpacing.xs),
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: VibrantSpacing.xxs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
