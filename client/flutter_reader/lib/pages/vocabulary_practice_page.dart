import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_api.dart';
import '../services/byok_controller.dart';
import '../services/language_preferences.dart';
import '../widgets/layout/vibrant_background.dart';
import '../widgets/surface.dart';

class VocabularyPracticePage extends ConsumerStatefulWidget {
  const VocabularyPracticePage({super.key, required this.vocabularyApi});

  final VocabularyApi vocabularyApi;

  @override
  ConsumerState<VocabularyPracticePage> createState() =>
      _VocabularyPracticePageState();
}

enum _PracticeStatus { idle, loading, ready, practicing, complete, error }

class _VocabularyPracticePageState
    extends ConsumerState<VocabularyPracticePage> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generate();
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
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
        _status = _PracticeStatus.ready;
      });
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

    // Simple match check - in production you might want fuzzy matching
    final isCorrect = correctTranslation.contains(userTranslation) ||
        userTranslation.contains(correctTranslation);

    setState(() {
      _lastAnswerCorrect = isCorrect;
      if (isCorrect) _correct++;
      _totalAttempts++;
      _results.add(isCorrect);
    });

    HapticFeedback.mediumImpact();

    // Auto-advance after showing feedback
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Practice'),
        actions: [
          if (_status == _PracticeStatus.ready || _status == _PracticeStatus.practicing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_correct / $_totalAttempts correct',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
        return const Center(child: CircularProgressIndicator());
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating vocabulary...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to generate vocabulary',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeState(BuildContext context) {
    if (_words.isEmpty) return const SizedBox();

    final currentWord = _words[_currentIndex];
    final theme = Theme.of(context);
    final progress = (_currentIndex + 1) / _words.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            Row(
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_words.length}',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '${(_currentIndex / _words.length * 100).toInt()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 32),

            // Word card
            Surface(
              backgroundColor: _lastAnswerCorrect == null
                  ? null
                  : _lastAnswerCorrect!
                      ? theme.colorScheme.primaryContainer.withAlpha(100)
                      : theme.colorScheme.errorContainer.withAlpha(100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Word
                  Text(
                    currentWord.word,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (currentWord.transliteration != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentWord.transliteration!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (currentWord.partOfSpeech != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentWord.partOfSpeech!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Answer input
                  TextField(
                    controller: _answerController,
                    enabled: _lastAnswerCorrect == null,
                    onChanged: (value) {
                      setState(() {
                        _userAnswer = value;
                      });
                    },
                    onSubmitted: (_) => _checkAnswer(),
                    decoration: InputDecoration(
                      labelText: 'Translation',
                      hintText: 'Enter the English translation',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _lastAnswerCorrect == null
                          ? null
                          : Icon(
                              _lastAnswerCorrect!
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _lastAnswerCorrect!
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                    ),
                    autofocus: true,
                  ),

                  // Feedback
                  if (_lastAnswerCorrect != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lastAnswerCorrect!
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _lastAnswerCorrect!
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _lastAnswerCorrect!
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _lastAnswerCorrect! ? 'Correct!' : 'Incorrect',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _lastAnswerCorrect!
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Correct answer: ${currentWord.translation}',
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (currentWord.exampleSentence != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Example:',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentWord.exampleSentence!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (currentWord.exampleTranslation != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                currentWord.exampleTranslation!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Check button
                  if (_lastAnswerCorrect == null) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _userAnswer.trim().isEmpty ? null : _checkAnswer,
                      icon: const Icon(Icons.check),
                      label: const Text('Check Answer'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteState(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = _totalAttempts > 0 ? (_correct / _totalAttempts) : 0.0;
    final accuracyPercent = (accuracy * 100).toInt();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Celebration icon
            Icon(
              accuracyPercent >= 80
                  ? Icons.emoji_events
                  : accuracyPercent >= 60
                      ? Icons.thumb_up
                      : Icons.lightbulb_outline,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              accuracyPercent >= 80
                  ? 'Excellent Work!'
                  : accuracyPercent >= 60
                      ? 'Good Job!'
                      : 'Keep Practicing!',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Stats card
            Surface(
              child: Column(
                children: [
                  _buildStatRow(
                    context,
                    'Score',
                    '$_correct / $_totalAttempts',
                    Icons.check_circle_outline,
                  ),
                  const Divider(),
                  _buildStatRow(
                    context,
                    'Accuracy',
                    '$accuracyPercent%',
                    Icons.analytics_outlined,
                  ),
                  const Divider(),
                  _buildStatRow(
                    context,
                    'Words Learned',
                    '${_words.length}',
                    Icons.auto_stories_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Practice Again'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
