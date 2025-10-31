import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../models/lesson.dart';
import '../models/language.dart';
import '../models/power_up.dart';
import '../services/byok_controller.dart';
import '../services/lesson_api.dart';
import '../services/gamification_coordinator.dart';
import '../services/adaptive_difficulty_service.dart';
import '../services/language_preferences.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../services/sound_service.dart';
import '../widgets/power_ups/power_up_widgets.dart';
import '../widgets/notifications/toast_notifications.dart';
import '../widgets/exercises/vibrant_cloze_exercise.dart';
import '../widgets/exercises/vibrant_match_exercise.dart';
import '../widgets/exercises/vibrant_alphabet_exercise.dart';
import '../widgets/exercises/vibrant_translate_exercise.dart';
import '../widgets/exercises/vibrant_grammar_exercise.dart';
import '../widgets/exercises/vibrant_listening_exercise.dart';
import '../widgets/exercises/vibrant_speaking_exercise.dart';
import '../widgets/exercises/vibrant_wordbank_exercise.dart';
import '../widgets/exercises/vibrant_truefalse_exercise.dart';
import '../widgets/exercises/vibrant_multiplechoice_exercise.dart';
import '../widgets/exercises/vibrant_dialogue_exercise.dart';
import '../widgets/exercises/vibrant_conjugation_exercise.dart';
import '../widgets/exercises/vibrant_declension_exercise.dart';
import '../widgets/exercises/vibrant_synonym_exercise.dart';
import '../widgets/exercises/vibrant_contextmatch_exercise.dart';
import '../widgets/exercises/vibrant_reorder_exercise.dart';
import '../widgets/exercises/vibrant_dictation_exercise.dart';
import '../widgets/exercises/vibrant_etymology_exercise.dart';
import '../widgets/exercises/vibrant_comprehension_exercise.dart';
import '../widgets/exercises/exercise_control.dart';
import '../widgets/retention_reward_modal.dart';
import '../widgets/lesson_loading_screen.dart';
import '../widgets/animations/level_up_celebration.dart';
import '../widgets/animations/perfect_score_celebration.dart';
import '../widgets/animations/streak_celebration.dart';
import '../widgets/celebrations/lesson_complete_celebration.dart';
import '../services/retention_loop_service.dart';
import '../services/haptic_service.dart';
import '../widgets/lessons/vibrant_lesson_header.dart';
import '../widgets/lessons/vibrant_lesson_action_bar.dart';
import '../widgets/glassmorphism_card.dart';

/// Vibrant lessons page with live XP tracking and engaging UI
class VibrantLessonsPage extends ConsumerStatefulWidget {
  const VibrantLessonsPage({super.key, required this.api});

  final LessonApi api;

  @override
  ConsumerState<VibrantLessonsPage> createState() => _VibrantLessonsPageState();
}

class _VibrantLessonsPageState extends ConsumerState<VibrantLessonsPage>
    with TickerProviderStateMixin {
  static const Set<int> _streakMilestones = {
    3,
    5,
    7,
    10,
    14,
    21,
    30,
    45,
    60,
    90,
    120,
    180,
    365,
  };

  LessonResponse? _lesson;
  int _currentIndex = 0;
  _Status _status = _Status.idle;
  String? _error;
  bool _canFallbackToEcho = false;
  String? _lastProviderNote;
  List<bool?> _taskResults = [];
  int _xpEarned = 0;
  int _correctCount = 0;
  late AnimationController _xpAnimationController;
  GamificationCoordinator? _coordinator;
  DateTime? _lessonStartTime;
  DateTime? _exerciseStartTime; // Track time per exercise
  bool _isShowingCompletion =
      false; // Flag to prevent rendering new tasks during completion
  Timer? _elapsedTimer;
  Duration _focusedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _xpAnimationController = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );
    _initializeGamification();
  }

  Future<void> _initializeGamification() async {
    try {
      final progress = await ref.read(progressServiceProvider.future);
      final dailyGoal = await ref.read(dailyGoalServiceProvider.future);
      final dailyChallenge = await ref.read(
        dailyChallengeServiceProvider.future,
      );
      final combo = ref.read(comboServiceProvider);
      final powerUps = await ref.read(powerUpServiceProvider.future);
      final badges = await ref.read(badgeServiceProvider.future);
      final achievements = ref.read(achievementServiceProvider);
      final backendChallenge = await ref.read(
        backendChallengeServiceProvider.future,
      );

      if (mounted) {
        setState(() {
          _coordinator = GamificationCoordinator(
            progressService: progress,
            dailyGoalService: dailyGoal,
            dailyChallengeService: dailyChallenge,
            comboService: combo,
            powerUpService: powerUps,
            badgeService: badges,
            achievementService: achievements,
            backendChallengeService: backendChallenge,
          );
        });
      }
    } catch (e) {
      debugPrint('[VibrantLessonsPage] Failed to initialize gamification: $e');
    }
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateLesson({int retryAttempt = 0}) async {
    _stopElapsedTimer();
    setState(() {
      _status = _Status.loading;
      _error = null;
      _canFallbackToEcho = false;
      _lastProviderNote = null;
      _xpEarned = 0;
      _correctCount = 0;
      _lessonStartTime = DateTime.now();
      _focusedDuration = Duration.zero;
      _exerciseHandles.clear();
      _isShowingCompletion = false;
    });

    try {
      final settings = await ref.read(byokControllerProvider.future);
      final provider = settings.lessonProvider.trim().isEmpty
          ? 'echo'
          : settings.lessonProvider.trim();

      // Get selected language
      final selectedLanguage = ref.read(selectedLanguageProvider);

      final params = GeneratorParams(
        language: selectedLanguage,
        profile: 'beginner',
        sources: ['daily', 'canon'],
        exerciseTypes: [
          'alphabet',
          'match',
          'cloze',
          'translate',
          'grammar',
          'listening',
          'speaking',
          'wordbank',
          'truefalse',
          'multiplechoice',
          'dialogue',
          'conjugation',
          'declension',
          'synonym',
          'contextmatch',
          'reorder',
          'dictation',
          'etymology',
          'comprehension', // Reading comprehension exercises
        ],
        kCanon: 2,
        includeAudio:
            true, // Enable audio generation for listening/dictation tasks
        provider: provider,
        model: settings.lessonModel,
      );

      final response = await widget.api.generate(params, settings);

      if (!mounted) return;
      final tasks = response.tasks;
      setState(() {
        _lesson = tasks.isEmpty ? null : response;
        _taskResults = tasks.isEmpty
            ? []
            : List<bool?>.filled(tasks.length, null, growable: false);
        _currentIndex = 0;
        _exerciseStartTime = DateTime.now(); // Start timer for first exercise
        _status = tasks.isEmpty ? _Status.error : _Status.ready;
        if (tasks.isEmpty) {
          _error = 'No exercises generated. Try different settings.';
        }
      });
      if (tasks.isNotEmpty) {
        _startElapsedTimer();
      }
    } catch (error) {
      if (!mounted) return;

      final errorMessage = error.toString();
      final previousNote = _lastProviderNote;

      // Check if it's a network/timeout error and we can retry
      final isRetryable =
          errorMessage.contains('timeout') ||
          errorMessage.contains('SocketException') ||
          errorMessage.contains('Connection') ||
          errorMessage.contains('429'); // Rate limit

      if (isRetryable && retryAttempt < 2) {
        // Exponential backoff: 2s, 4s
        final delaySeconds = 2 * (retryAttempt + 1);
        setState(() {
          _status = _Status.error;
          _error = 'Connection issue. Retrying in $delaySeconds seconds...';
        });

        await Future.delayed(Duration(seconds: delaySeconds));
        if (mounted) {
          return _generateLesson(retryAttempt: retryAttempt + 1);
        }
      }

      // Check for specific errors and provide helpful messages
      String friendlyError = errorMessage;
      bool canFallbackToEcho = false;
      String? providerNote;
      String? providerNoteDisplay;

      final noteMatch =
          RegExp(r'provider failed:\s*([^|]+)').firstMatch(errorMessage);
      final candidateNote = noteMatch?.group(1)?.trim();
      if (candidateNote != null &&
          candidateNote.isNotEmpty &&
          candidateNote != 'unknown_error') {
        providerNote = candidateNote;
        final normalised = candidateNote.replaceAll('_', ' ').trim();
        if (normalised.isNotEmpty) {
          providerNoteDisplay = normalised
              .split(RegExp(r'\s+'))
              .where((segment) => segment.isNotEmpty)
              .map(
                (segment) => segment[0].toUpperCase() +
                    (segment.length > 1 ? segment.substring(1) : ''),
              )
              .join(' ');
        }
      }

      if (errorMessage.contains('401') || errorMessage.contains('403')) {
        friendlyError =
            'API key invalid or expired. Please check your settings.';
      } else if (errorMessage.contains('429')) {
        friendlyError =
            'Rate limit exceeded. Please wait a moment and try again.';
        canFallbackToEcho = true;
      } else if (errorMessage.contains('timeout')) {
        friendlyError = 'Request timed out. Please check your connection.';
        canFallbackToEcho = true;
      } else if (errorMessage.contains('SocketException')) {
        friendlyError =
            'Network connection failed. Please check your internet.';
        canFallbackToEcho = true;
      } else if (errorMessage.contains('API key')) {
        friendlyError =
            'No API key configured. Use Echo mode or add an API key in settings.';
        canFallbackToEcho = true;
      } else if (errorMessage.contains('openai_bad_payload')) {
        friendlyError =
            'OpenAI returned an unexpected response. We captured diagnostics—please try again or switch to Echo for now.';
        canFallbackToEcho = true;
      } else if (errorMessage.contains('google_bad_payload')) {
        friendlyError =
            'Gemini returned an unexpected response. We logged the issue; retry in a moment or use Echo temporarily.';
        canFallbackToEcho = true;
      }

      setState(() {
        _status = _Status.error;
        _error = friendlyError;
        _canFallbackToEcho = canFallbackToEcho;
        _lastProviderNote = providerNote;
      });

      if (providerNoteDisplay != null &&
          mounted &&
          providerNote != null &&
          providerNote != previousNote) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Provider note: $providerNoteDisplay'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleCheck() async {
    final lesson = _lesson;
    if (lesson == null || _currentIndex >= lesson.tasks.length) return;

    final feedback = _exerciseHandles[_currentIndex]?.check();

    if (feedback == null || feedback.correct == null) return;

    final isCorrect = feedback.correct!;

    // Calculate time spent on this exercise
    final timeSpent = _exerciseStartTime != null
        ? DateTime.now().difference(_exerciseStartTime!).inSeconds.toDouble()
        : 0.0;

    // Record performance for adaptive difficulty (fire-and-forget, don't block UI)
    final task = lesson.tasks[_currentIndex];
    _recordPerformanceAsync(isCorrect, timeSpent, task);

    // Use gamification coordinator if available
    int xpGained = 0;
    if (_coordinator != null && mounted) {
      final result = await _coordinator!.processExercise(
        context: context,
        isCorrect: isCorrect,
        baseXP: 25,
        wordsLearned: isCorrect ? 1 : 0,
      );
      xpGained = result.xpEarned;

      setState(() {
        _taskResults[_currentIndex] = isCorrect;
        if (isCorrect) {
          _xpEarned += xpGained;
          _correctCount++;
        }
      });

      // Show XP animation
      if (isCorrect) {
        _showFloatingXP(xpGained);
      }
    } else {
      // Fallback: basic XP without gamification
      xpGained = isCorrect ? 25 : 0;
      setState(() {
        _taskResults[_currentIndex] = isCorrect;
        if (isCorrect) {
          _xpEarned += xpGained;
          _correctCount++;
        }
      });

      if (isCorrect) {
        _showFloatingXP(xpGained);
      }
    }

    // Add sound effect and haptic feedback
    if (isCorrect) {
      SoundService.instance.xpGain();
      HapticService.success(); // Haptic feedback for correct answer
    } else {
      HapticService.error(); // Haptic feedback for incorrect answer
      // Reset exercise so user can retry
      _exerciseHandles[_currentIndex]?.reset();
      // Force UI update to ensure Check button state refreshes
      if (mounted) {
        setState(() {
          // Trigger rebuild to update button state
        });
      }
    }

    // Check if this was the last question
    final isLastQuestion = _currentIndex >= lesson.tasks.length - 1;

    // Auto-advance after 1 second if correct
    if (isCorrect) {
      // For the last question, show completion immediately to avoid rendering glitch
      if (isLastQuestion) {
        // Set flag BEFORE any delays to prevent race conditions
        setState(() => _isShowingCompletion = true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          await _showCompletionModal();
        }
      } else {
        // For non-last questions, advance normally
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted && !_isShowingCompletion) {
          _handleNext();
        }
      }
    }
  }

  void _handleNext() async {
    final lesson = _lesson;
    if (lesson == null || _isShowingCompletion) return;

    if (_currentIndex >= lesson.tasks.length - 1) {
      // Lesson complete!
      setState(() {
        _isShowingCompletion = true; // Prevent rendering new tasks
      });
      await _showCompletionModal();
    } else {
      setState(() {
        _currentIndex++;
        _exerciseStartTime = DateTime.now(); // Start timer for next exercise
      });
    }
  }

  /// Map task type to skill category for adaptive difficulty
  SkillCategory _mapTaskToSkillCategory(Task task) {
    if (task is ClozeTask) {
      return SkillCategory.vocabulary; // Cloze tests vocabulary
    } else if (task is MatchTask) {
      return SkillCategory.translation; // Match tests translation
    } else {
      return SkillCategory.comprehension; // Default
    }
  }

  /// Record performance in adaptive difficulty service (async, non-blocking)
  Future<void> _recordPerformanceAsync(
    bool correct,
    double timeSpent,
    Task task,
  ) async {
    try {
      // Use .future to properly await the FutureProvider
      final adaptiveDifficulty = await ref.read(
        adaptiveDifficultyServiceProvider.future,
      );
      await adaptiveDifficulty.recordPerformance(
        correct: correct,
        timeSpent: timeSpent,
        category: _mapTaskToSkillCategory(task),
        exerciseType: task.runtimeType.toString(),
      );
    } catch (e) {
      debugPrint('[VibrantLessonsPage] Failed to record performance: $e');
    }
  }

  Future<void> _showCompletionModal() async {
    final lesson = _lesson;
    if (lesson == null) return;

    _stopElapsedTimer();
    final progressService = await ref.read(progressServiceProvider.future);

    final currentLevel = progressService.currentLevel;
    final previousStreak = progressService.streakDays;
    final previousMaxStreak = progressService.maxStreak;
    final lessonDuration = _lessonStartTime != null
        ? DateTime.now().difference(_lessonStartTime!)
        : const Duration(minutes: 5);
    setState(() {
      _focusedDuration = lessonDuration;
    });

    // Check retention loops for additional rewards
    List<RetentionReward> retentionRewards = [];
    try {
      // Use .future to properly await the FutureProvider
      final retentionLoop = await ref.read(retentionLoopServiceProvider.future);
      retentionRewards = await retentionLoop.checkIn(
        xpEarned: _xpEarned,
        lessonsCompleted: 1,
      );

      // Add bonus XP from retention rewards
      for (final reward in retentionRewards) {
        _xpEarned += reward.xpBonus;
      }
    } catch (e) {
      debugPrint('[VibrantLessonsPage] Failed to check retention loops: $e');
    }

    // Use coordinator if available for complete gamification flow
    if (_coordinator != null && mounted) {
      final rewards = await _coordinator!.processLessonCompletion(
        context: context,
        totalXP: _xpEarned,
        correctCount: _correctCount,
        totalQuestions: lesson.tasks.length,
        wordsLearned: _correctCount,
        lessonDuration: lessonDuration,
      );

      if (!mounted) return;

      final newLevel = progressService.currentLevel;
      final isLevelUp = newLevel > currentLevel;
      final isPerfectScore = _correctCount == lesson.tasks.length;
      final updatedStreak = progressService.streakDays;
      final streakIncreased = updatedStreak > previousStreak;
      final streakMilestoneReached = _streakMilestones.contains(updatedStreak);
      final isNewStreakRecord = progressService.maxStreak > previousMaxStreak;

      // Show perfect score celebration first if applicable
      if (isPerfectScore) {
        HapticService.celebrate(); // Epic haptic for perfect score
        showPerfectScoreCelebration(context, xpBonus: 50);
        await Future.delayed(const Duration(seconds: 4));
      }

      if (!mounted) return;

      if (streakIncreased) {
        await showStreakCelebration(
          context,
          streakDays: updatedStreak,
          isMilestone: streakMilestoneReached,
          isNewRecord: isNewStreakRecord,
        );
      }

      if (!mounted) return;

      // Show level up celebration if applicable
      if (isLevelUp) {
        HapticService.celebrate(); // Epic haptic for level up
        final unlocks = <String>[];
        if (newLevel == 5) unlocks.add('Unlocked: Harder exercises');
        if (newLevel == 10) {
          unlocks.add('Unlocked: Chat with historical figures');
        }
        if (newLevel == 15) unlocks.add('Unlocked: Story mode');
        if (newLevel == 20) unlocks.add('Unlocked: Advanced texts');

        showLevelUpCelebration(context, newLevel: newLevel, unlocks: unlocks);
        await Future.delayed(const Duration(seconds: 4));
      }

      if (!mounted) return;

      // Show rewards (badges, achievements)
      await _coordinator!.showRewards(context: context, rewards: rewards);

      if (!mounted) return;

      // Show retention rewards if any
      if (retentionRewards.isNotEmpty) {
        await RetentionRewardModal.show(context, retentionRewards);
      }

      if (!mounted) return;

      // Get language name for celebration
      final selectedLanguage = ref.read(selectedLanguageProvider);
      final languageInfo = availableLanguages.firstWhere(
        (lang) => lang.code == selectedLanguage,
        orElse: () => availableLanguages.first,
      );

      // Show premium lesson completion celebration!
      await LessonCompleteCelebration.show(
        context: context,
        xpEarned: _xpEarned,
        accuracy: _correctCount / lesson.tasks.length,
        wordsLearned: _correctCount,
        languageName: languageInfo.name,
        levelUp: isLevelUp,
        newLevel: newLevel,
        achievementsUnlocked: rewards.newBadges
            .map((b) => b.badge.name)
            .toList(),
      );

      if (!mounted) return;

      // Reset lesson state
      setState(() {
        _lesson = null;
        _status = _Status.idle;
      });
    } else {
      // Fallback: basic completion without gamification
      final currentXP = progressService.xpTotal;
      final newXP = currentXP + _xpEarned;
      final newLevel = (newXP / 100).floor();
      final isLevelUp = newLevel > currentLevel;
      final isPerfectScore = _correctCount == lesson.tasks.length;
      final previousStreak = progressService.streakDays;
      final previousMaxStreak = progressService.maxStreak;

      // Update progress
      await progressService.updateProgress(
        xpGained: _xpEarned,
        timestamp: DateTime.now(),
        isPerfect: isPerfectScore,
      );

      if (!mounted) return;

      final updatedStreak = progressService.streakDays;
      final streakIncreased = updatedStreak > previousStreak;
      final streakMilestoneReached = _streakMilestones.contains(updatedStreak);
      final isNewStreakRecord = progressService.maxStreak > previousMaxStreak;

      // Show perfect score celebration first if applicable
      if (isPerfectScore) {
        HapticService.celebrate();
        showPerfectScoreCelebration(context, xpBonus: 50);
        await Future.delayed(const Duration(seconds: 4));
      }

      if (!mounted) return;

      if (streakIncreased) {
        await showStreakCelebration(
          context,
          streakDays: updatedStreak,
          isMilestone: streakMilestoneReached,
          isNewRecord: isNewStreakRecord,
        );
      }

      if (!mounted) return;

      // Show level up celebration if applicable
      if (isLevelUp) {
        HapticService.celebrate();
        final unlocks = <String>[];
        if (newLevel == 5) unlocks.add('Unlocked: Harder exercises');
        if (newLevel == 10) {
          unlocks.add('Unlocked: Chat with historical figures');
        }
        if (newLevel == 15) unlocks.add('Unlocked: Story mode');
        if (newLevel == 20) unlocks.add('Unlocked: Advanced texts');

        showLevelUpCelebration(context, newLevel: newLevel, unlocks: unlocks);
        await Future.delayed(const Duration(seconds: 4));
      }

      if (!mounted) return;

      // Get language name for celebration (fallback path)
      final selectedLanguage = ref.read(selectedLanguageProvider);
      final languageInfo = availableLanguages.firstWhere(
        (lang) => lang.code == selectedLanguage,
        orElse: () => availableLanguages.first,
      );

      // Show premium lesson completion celebration (fallback without gamification)
      await LessonCompleteCelebration.show(
        context: context,
        xpEarned: _xpEarned,
        accuracy: _correctCount / lesson.tasks.length,
        wordsLearned: _correctCount,
        languageName: languageInfo.name,
        levelUp: isLevelUp,
        newLevel: newLevel,
        achievementsUnlocked: [],
      );

      if (!mounted) return;

      // Reset lesson state
      setState(() {
        _lesson = null;
        _status = _Status.idle;
      });
    }
  }

  void _showFloatingXP(int xp) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => FloatingXP(
        xp: xp,
        startPosition: Offset(size.width / 2 - 50, size.height * 0.3),
        onComplete: () {
          if (mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _startElapsedTimer() {
    if (_lessonStartTime == null) return;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _lessonStartTime == null) return;
      setState(() {
        _focusedDuration = DateTime.now().difference(_lessonStartTime!);
      });
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  void _resetLessonState() {
    _stopElapsedTimer();
    setState(() {
      _lesson = null;
      _status = _Status.idle;
      _currentIndex = 0;
      _taskResults = [];
      _exerciseHandles.clear();
      _xpEarned = 0;
      _correctCount = 0;
      _isShowingCompletion = false;
      _focusedDuration = Duration.zero;
      _lessonStartTime = null;
      _exerciseStartTime = null;
    });
  }

  final Map<int, LessonExerciseHandle> _exerciseHandles = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    switch (_status) {
      case _Status.loading:
        return _buildLoadingState(theme, colorScheme);
      case _Status.error:
        return _buildErrorState(theme, colorScheme);
      case _Status.ready:
        return _buildLessonView(theme, colorScheme);
      case _Status.idle:
        return _buildEmptyState(theme, colorScheme);
    }
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    // Get the selected language to pass to the loading screen
    final selectedLanguage = ref.watch(selectedLanguageProvider);

    return LessonLoadingScreen(languageCode: selectedLanguage);
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: VibrantSpacing.xl),
            Text(
              'Unable to generate lesson',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: VibrantSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: VibrantSpacing.xl),
            FilledButton.icon(
              onPressed: _generateLesson,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
            if (_canFallbackToEcho) ...[
              const SizedBox(height: VibrantSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  // Fallback to echo provider
                  final controller = ref.read(byokControllerProvider.notifier);
                  final settings = await ref.read(
                    byokControllerProvider.future,
                  );
                  await controller.saveSettings(
                    settings.copyWith(lessonProvider: 'echo'),
                  );
                  if (mounted) {
                    _generateLesson();
                  }
                },
                icon: const Icon(Icons.offline_bolt_rounded),
                label: const Text('Use Offline Mode (Echo)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleIn(
              child: Container(
                padding: const EdgeInsets.all(VibrantSpacing.xxl),
                decoration: BoxDecoration(
                  gradient: VibrantTheme.heroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: VibrantSpacing.xxl),
            Text(
              'Ready to learn?',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xl),
            Text(
              'Start a new lesson and earn XP!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xxl),
            FilledButton.icon(
              onPressed: _generateLesson,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Lesson'),
              style: FilledButton.styleFrom(
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

  Widget _buildLessonView(ThemeData theme, ColorScheme colorScheme) {
    final lesson = _lesson;
    if (lesson == null || lesson.tasks.isEmpty) {
      return _buildErrorState(theme, colorScheme);
    }

    // Don't render new tasks if lesson completion is in progress
    if (_isShowingCompletion || _currentIndex >= lesson.tasks.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final task = lesson.tasks[_currentIndex];
    final totalTasks = lesson.tasks.length;
    final progress = (_currentIndex + 1) / totalTasks;

    // Create or get exercise handle
    if (!_exerciseHandles.containsKey(_currentIndex)) {
      _exerciseHandles[_currentIndex] = LessonExerciseHandle();
    }
    final handle = _exerciseHandles[_currentIndex]!;

    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final languageInfo = availableLanguages.firstWhere(
      (lang) => lang.code == selectedLanguage,
      orElse: () => availableLanguages.first,
    );
    final combo = _coordinator?.comboService.currentCombo ?? 0;
    final showCombo =
        _coordinator != null && _coordinator!.comboService.currentCombo >= 3;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: VibrantDuration.moderate,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: VibrantLessonHeader(
            key: ValueKey('lesson-header-${_currentIndex}_$combo'),
            language: languageInfo,
            currentQuestion: _currentIndex + 1,
            totalQuestions: totalTasks,
            correctAnswers: _correctCount,
            progress: progress,
            xpEarned: _xpEarned,
            combo: combo,
            showCombo: showCombo,
            elapsed: _focusedDuration,
            onClose: _resetLessonState,
          ),
        ),

        // Power-up quick bar (if coordinator available)
        if (_coordinator != null &&
            _coordinator!.powerUpService.inventory.isNotEmpty)
          SlideInFromBottom(
            delay: const Duration(milliseconds: 120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                VibrantSpacing.lg,
                VibrantSpacing.md,
                VibrantSpacing.lg,
                VibrantSpacing.sm,
              ),
              child: GlassmorphismCard(
                blur: 18,
                opacity: 0.16,
                borderOpacity: 0.28,
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.lg,
                  vertical: VibrantSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: VibrantSpacing.sm),
                        Text(
                          'Power-ups ready',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_coordinator!.powerUpService.inventory.values.fold<int>(0, (a, b) => a + b)} in inventory',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    PowerUpQuickBar(
                      inventory: _coordinator!.powerUpService.inventory,
                      activePowerUps:
                          _coordinator!.powerUpService.activePowerUps,
                      onActivate: (powerUp) async {
                        await _coordinator!.powerUpService.activate(powerUp);
                        if (mounted) setState(() {});
                        // Apply power-up effects to current exercise
                        _applyPowerUpEffects(powerUp);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Exercise content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: _buildExercise(task, handle, theme),
          ),
        ),

        // Bottom action bar
        _buildActionBar(theme, colorScheme, handle, totalTasks),
      ],
    );
  }

  Widget _buildExercise(
    Task task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    Widget exercise;

    if (task is AlphabetTask) {
      exercise = VibrantAlphabetExercise(task: task, handle: handle);
    } else if (task is MatchTask) {
      exercise = VibrantMatchExercise(task: task, handle: handle);
    } else if (task is ClozeTask) {
      exercise = VibrantClozeExercise(task: task, handle: handle);
    } else if (task is TranslateTask) {
      exercise = VibrantTranslateExercise(task: task, handle: handle);
    } else if (task is GrammarTask) {
      exercise = _buildGrammarExercise(task, handle, theme);
    } else if (task is ListeningTask) {
      exercise = _buildListeningExercise(task, handle, theme);
    } else if (task is SpeakingTask) {
      exercise = _buildSpeakingExercise(task, handle, theme);
    } else if (task is WordBankTask) {
      exercise = _buildWordBankExercise(task, handle, theme);
    } else if (task is TrueFalseTask) {
      exercise = _buildTrueFalseExercise(task, handle, theme);
    } else if (task is MultipleChoiceTask) {
      exercise = _buildMultipleChoiceExercise(task, handle, theme);
    } else if (task is DialogueTask) {
      exercise = _buildDialogueExercise(task, handle, theme);
    } else if (task is ConjugationTask) {
      exercise = _buildConjugationExercise(task, handle, theme);
    } else if (task is DeclensionTask) {
      exercise = _buildDeclensionExercise(task, handle, theme);
    } else if (task is SynonymTask) {
      exercise = _buildSynonymExercise(task, handle, theme);
    } else if (task is ContextMatchTask) {
      exercise = _buildContextMatchExercise(task, handle, theme);
    } else if (task is ReorderTask) {
      exercise = _buildReorderExercise(task, handle, theme);
    } else if (task is DictationTask) {
      exercise = _buildDictationExercise(task, handle, theme);
    } else if (task is EtymologyTask) {
      exercise = _buildEtymologyExercise(task, handle, theme);
    } else if (task is ReadingComprehensionTask) {
      exercise = _buildComprehensionExercise(task, handle, theme);
    } else {
      exercise = Center(
        child: Text(
          'Exercise type not yet implemented: ${task.type}',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return SlideInFromBottom(
      delay: const Duration(milliseconds: 200),
      child: exercise,
    );
  }

  Widget _buildActionBar(
    ThemeData theme,
    ColorScheme colorScheme,
    LessonExerciseHandle handle,
    int totalTasks,
  ) {
    return ListenableBuilder(
      listenable: handle,
      builder: (context, _) {
        final canCheck = handle.canCheck;
        final isLastQuestion = _currentIndex >= totalTasks - 1;

        return VibrantLessonActionBar(
          key: ValueKey('lesson-action-${_currentIndex}_$canCheck'),
          canCheck: canCheck,
          isLastQuestion: isLastQuestion,
          onCheck: _handleCheck,
          onSkip: _handleNext,
        );
      },
    );
  }

  /// Apply power-up effects to the current exercise
  void _applyPowerUpEffects(PowerUp powerUp) {
    if (_lesson == null || _status != _Status.ready) return;

    switch (powerUp.type) {
      case PowerUpType.skipQuestion:
        // Automatically mark as correct and move to next
        if (_currentIndex < _lesson!.tasks.length) {
          _taskResults[_currentIndex] = true;
          _correctCount++;
          _xpEarned += 10; // Award XP for skipped question
          _coordinator?.awardXP(10);
          _handleNext();

          ToastNotification.show(
            context: context,
            message: 'Question skipped!',
            icon: Icons.skip_next_rounded,
            type: ToastType.success,
            duration: const Duration(seconds: 1),
          );
        }
        break;

      case PowerUpType.hint:
        // Show a hint for the current exercise
        final task = _lesson!.tasks[_currentIndex];
        String hint = 'Try to think about the context...';

        if (task is ClozeTask) {
          hint =
              'Look at the surrounding words for clues about the missing word.';
        } else if (task is MatchTask) {
          hint = 'Start with the pairs you\'re most confident about.';
        }

        ToastNotification.show(
          context: context,
          message: hint,
          title: 'Hint',
          type: ToastType.info,
          duration: const Duration(seconds: 4),
        );
        break;

      case PowerUpType.autoComplete:
        // Auto-complete the current exercise
        if (_currentIndex < _lesson!.tasks.length) {
          _taskResults[_currentIndex] = true;
          _correctCount++;
          final xp = 20; // Award bonus XP
          _xpEarned += xp;
          _coordinator?.awardXP(xp);
          _xpAnimationController.forward(from: 0);

          ToastNotification.show(
            context: context,
            message: 'Exercise auto-completed!',
            icon: Icons.bolt_rounded,
            type: ToastType.success,
            duration: const Duration(seconds: 1),
          );

          // Move to next after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _handleNext();
          });
        }
        break;

      case PowerUpType.xpBoost:
        // Show notification that 2x XP is active
        ToastNotification.show(
          context: context,
          message: '2x XP boost active for this lesson!',
          title: 'XP Boost',
          type: ToastType.success,
          duration: const Duration(seconds: 2),
        );
        break;

      case PowerUpType.slowTime:
        // Show notification for timed exercises
        ToastNotification.show(
          context: context,
          message: 'Time extended by 50% for timed exercises!',
          title: 'Slow Time',
          type: ToastType.info,
          duration: const Duration(seconds: 2),
        );
        break;

      case PowerUpType.freezeStreak:
        // Show notification
        ToastNotification.show(
          context: context,
          message: 'Streak freeze activated for 24 hours!',
          title: 'Streak Protected',
          type: ToastType.success,
          duration: const Duration(seconds: 2),
        );
        break;
    }
  }

  // New exercise builders for additional task types

  Widget _buildGrammarExercise(
    GrammarTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantGrammarExercise(task: task, handle: handle);
  }

  Widget _buildListeningExercise(
    ListeningTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantListeningExercise(task: task, handle: handle);
  }

  Widget _buildSpeakingExercise(
    SpeakingTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantSpeakingExercise(task: task, handle: handle);
  }

  Widget _buildWordBankExercise(
    WordBankTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantWordBankExercise(task: task, handle: handle);
  }

  Widget _buildTrueFalseExercise(
    TrueFalseTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantTrueFalseExercise(task: task, handle: handle);
  }

  Widget _buildMultipleChoiceExercise(
    MultipleChoiceTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantMultipleChoiceExercise(task: task, handle: handle);
  }

  Widget _buildDialogueExercise(
    DialogueTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantDialogueExercise(task: task, handle: handle);
  }

  Widget _buildConjugationExercise(
    ConjugationTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantConjugationExercise(task: task, handle: handle);
  }

  Widget _buildDeclensionExercise(
    DeclensionTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantDeclensionExercise(task: task, handle: handle);
  }

  Widget _buildSynonymExercise(
    SynonymTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantSynonymExercise(task: task, handle: handle);
  }

  Widget _buildContextMatchExercise(
    ContextMatchTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantContextMatchExercise(task: task, handle: handle);
  }

  Widget _buildReorderExercise(
    ReorderTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantReorderExercise(task: task, handle: handle);
  }

  Widget _buildDictationExercise(
    DictationTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantDictationExercise(task: task, handle: handle);
  }

  Widget _buildEtymologyExercise(
    EtymologyTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantEtymologyExercise(task: task, handle: handle);
  }

  Widget _buildComprehensionExercise(
    ReadingComprehensionTask task,
    LessonExerciseHandle handle,
    ThemeData theme,
  ) {
    return VibrantComprehensionExercise(task: task, handle: handle);
  }
}

enum _Status { idle, loading, ready, error }
