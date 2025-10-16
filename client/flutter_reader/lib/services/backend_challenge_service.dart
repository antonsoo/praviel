import 'package:flutter/foundation.dart';
import 'challenges_api.dart';

/// Result of lesson completion containing completed challenges and special events
class LessonCompletionResult {
  final List<int> completedChallengeIds;
  final bool doubleOrNothingCompleted;
  final int? doubleOrNothingCoinsWon;

  const LessonCompletionResult({
    required this.completedChallengeIds,
    this.doubleOrNothingCompleted = false,
    this.doubleOrNothingCoinsWon,
  });
}

/// Service for managing daily and weekly challenges using backend API
/// This replaces the old local-only DailyChallengeService
class BackendChallengeService extends ChangeNotifier {
  BackendChallengeService(this._api);

  final ChallengesApi _api;

  List<DailyChallengeApiResponse> _dailyChallenges = [];
  List<WeeklyChallengeApiResponse> _weeklyChallenges = [];
  ChallengeStreakApiResponse? _streak;
  DoubleOrNothingStatusResponse? _doubleOrNothingStatus;
  int? _userCoins;
  int? _userStreakFreezes;
  bool _loaded = false;
  bool _loading = false;

  // Getters
  List<DailyChallengeApiResponse> get dailyChallenges =>
      List.unmodifiable(_dailyChallenges);
  List<WeeklyChallengeApiResponse> get weeklyChallenges =>
      List.unmodifiable(_weeklyChallenges);
  ChallengeStreakApiResponse? get streak => _streak;
  DoubleOrNothingStatusResponse? get doubleOrNothingStatus =>
      _doubleOrNothingStatus;

  /// Get current coin count from backend (source of truth)
  int get userCoins => _userCoins ?? 0;

  /// Get current streak freeze count from backend (source of truth)
  int get userStreakFreezes => _userStreakFreezes ?? 0;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;

  List<DailyChallengeApiResponse> get activeDailyChallenges =>
      _dailyChallenges.where((c) => !c.isCompleted).toList();

  List<WeeklyChallengeApiResponse> get activeWeeklyChallenges =>
      _weeklyChallenges.where((c) => !c.isCompleted).toList();

  int get completedDailyCount =>
      _dailyChallenges.where((c) => c.isCompleted).length;

  int get completedWeeklyCount =>
      _weeklyChallenges.where((c) => c.isCompleted).length;

  bool get allDailyChallengesCompleted =>
      _dailyChallenges.isNotEmpty &&
      _dailyChallenges.every((c) => c.isCompleted);

  /// Load all challenge data from backend
  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    try {
      // Load all data in parallel with individual error handling
      final results = await Future.wait([
        _api.getDailyChallenges().catchError((e) {
          debugPrint(
            '[BackendChallengeService] Failed to load daily challenges: $e',
          );
          return <DailyChallengeApiResponse>[];
        }),
        _api.getWeeklyChallenges().catchError((e) {
          debugPrint(
            '[BackendChallengeService] Failed to load weekly challenges: $e',
          );
          return <WeeklyChallengeApiResponse>[];
        }),
        _api.getStreak().catchError((e) {
          debugPrint('[BackendChallengeService] Failed to load streak: $e');
          return ChallengeStreakApiResponse(
            currentStreak: 0,
            longestStreak: 0,
            totalDaysCompleted: 0,
            lastCompletionDate: DateTime.now(),
            isActiveToday: false,
          );
        }),
        _api.getDoubleOrNothingStatus().catchError((e) {
          debugPrint(
            '[BackendChallengeService] Failed to load double-or-nothing: $e',
          );
          return DoubleOrNothingStatusResponse(hasActiveChallenge: false);
        }),
        _api.getUserProgress().catchError((e) {
          debugPrint(
            '[BackendChallengeService] Failed to load user progress: $e',
          );
          return UserProgressApiResponse(coins: 0, streakFreezes: 0);
        }),
      ]);

      _dailyChallenges = results[0] as List<DailyChallengeApiResponse>;
      _weeklyChallenges = results[1] as List<WeeklyChallengeApiResponse>;
      _streak = results[2] as ChallengeStreakApiResponse;
      _doubleOrNothingStatus = results[3] as DoubleOrNothingStatusResponse;

      // Initialize coins and streak_freezes from user progress
      final userProgress = results[4] as UserProgressApiResponse;
      _userCoins = userProgress.coins;
      _userStreakFreezes = userProgress.streakFreezes;

      _loaded = true;
      _loading = false;
      notifyListeners();

      debugPrint(
        '[BackendChallengeService] Loaded: ${_dailyChallenges.length} daily, '
        '${_weeklyChallenges.length} weekly challenges, '
        'Coins: $_userCoins, Freezes: $_userStreakFreezes',
      );
    } catch (e) {
      debugPrint('[BackendChallengeService] Unexpected error during load: $e');
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  /// Refresh challenges from backend
  Future<void> refresh() async {
    await load();
  }

  /// Update progress on a daily challenge
  /// This is called automatically by progress hooks
  Future<bool> updateDailyChallengeProgress({
    required int challengeId,
    required int increment,
  }) async {
    try {
      final result = await _api.updateChallengeProgress(
        challengeId: challengeId,
        increment: increment,
      );

      final completed = result['completed'] as bool? ?? false;

      // Update coins from response (backend now returns coins_remaining)
      if (result.containsKey('coins_remaining')) {
        _userCoins = result['coins_remaining'] as int?;
      }

      // Reload challenges to get updated state
      await load();

      if (completed) {
        debugPrint(
          '[BackendChallengeService] Challenge $challengeId completed! Coins: $_userCoins',
        );
      }

      return completed;
    } catch (e) {
      debugPrint(
        '[BackendChallengeService] Failed to update challenge progress: $e',
      );
      return false;
    }
  }

  /// Update progress on a weekly challenge
  Future<bool> updateWeeklyChallengeProgress({
    required int challengeId,
    required int increment,
  }) async {
    try {
      final result = await _api.updateWeeklyChallengeProgress(
        challengeId: challengeId,
        increment: increment,
      );

      final completed = result['completed'] as bool? ?? false;

      // Update coins from response (backend now returns coins_remaining)
      if (result.containsKey('coins_remaining')) {
        _userCoins = result['coins_remaining'] as int?;
      }

      // Reload challenges to get updated state
      await load();

      if (completed) {
        debugPrint(
          '[BackendChallengeService] Weekly challenge $challengeId completed! Coins: $_userCoins',
        );
      }

      return completed;
    } catch (e) {
      debugPrint(
        '[BackendChallengeService] Failed to update weekly challenge progress: $e',
      );
      return false;
    }
  }

  /// Called when user completes a lesson
  /// Automatically updates all relevant challenges (both daily AND weekly)
  Future<LessonCompletionResult> onLessonCompleted({
    required int xpEarned,
    required bool isPerfect,
    required int wordsLearned,
    required int timeSpentMinutes,
    required int comboAchieved,
  }) async {
    final completedChallengeIds = <int>[];
    bool doubleOrNothingCompleted = false;
    int? doubleOrNothingCoinsWon;

    // Update DAILY challenges
    for (final challenge in _dailyChallenges) {
      if (challenge.isCompleted) continue;

      bool shouldUpdate = false;
      int increment = 0;

      switch (challenge.challengeType) {
        case 'lessons_completed':
          shouldUpdate = true;
          increment = 1;
          break;
        case 'xp_earned':
          shouldUpdate = true;
          increment = xpEarned;
          break;
        case 'perfect_score':
          shouldUpdate = isPerfect;
          increment = 1;
          break;
        case 'words_learned':
          shouldUpdate = true;
          increment = wordsLearned;
          break;
        case 'time_spent':
          shouldUpdate = true;
          increment = timeSpentMinutes;
          break;
        case 'combo_achieved':
          shouldUpdate = comboAchieved >= challenge.targetValue;
          increment = comboAchieved;
          break;
        case 'streak_maintain':
          shouldUpdate = true;
          increment = 1;
          break;
      }

      if (shouldUpdate) {
        final completed = await updateDailyChallengeProgress(
          challengeId: challenge.id,
          increment: increment,
        );
        if (completed) {
          completedChallengeIds.add(challenge.id);
        }
      }
    }

    // Update WEEKLY challenges (same logic, different endpoint)
    for (final challenge in _weeklyChallenges) {
      if (challenge.isCompleted) continue;

      bool shouldUpdate = false;
      int increment = 0;

      switch (challenge.challengeType) {
        case 'lessons_completed':
          shouldUpdate = true;
          increment = 1;
          break;
        case 'xp_earned':
          shouldUpdate = true;
          increment = xpEarned;
          break;
        case 'perfect_score':
          shouldUpdate = isPerfect;
          increment = 1;
          break;
        case 'words_learned':
          shouldUpdate = true;
          increment = wordsLearned;
          break;
        case 'time_spent':
          shouldUpdate = true;
          increment = timeSpentMinutes;
          break;
        case 'combo_achieved':
          shouldUpdate = comboAchieved >= challenge.targetValue;
          increment = comboAchieved;
          break;
        case 'streak_maintain':
          shouldUpdate = true;
          increment = 1;
          break;
      }

      if (shouldUpdate) {
        final completed = await updateWeeklyChallengeProgress(
          challengeId: challenge.id,
          increment: increment,
        );
        if (completed) {
          completedChallengeIds.add(challenge.id);
          debugPrint(
            '[BackendChallengeService] Weekly challenge ${challenge.id} completed! 🎉',
          );
        }
      }
    }

    // Check if ALL daily challenges are completed
    final allDailiesComplete = _dailyChallenges.every((c) => c.isCompleted);

    // If all daily challenges completed AND we have an active double-or-nothing, complete the day
    if (allDailiesComplete &&
        _doubleOrNothingStatus?.hasActiveChallenge == true) {
      try {
        final result = await _api.completeDoubleOrNothingDay();
        final dayCompleted = result['success'] as bool? ?? false;
        final challengeComplete =
            result['challenge_completed'] as bool? ?? false;

        if (dayCompleted) {
          debugPrint(
            '[BackendChallengeService] Double-or-nothing day completed!',
          );

          if (challengeComplete) {
            final coinsAwarded = result['coins_awarded'] as int? ?? 0;
            debugPrint(
              '[BackendChallengeService] Double-or-nothing challenge COMPLETE! Won $coinsAwarded coins! 🎉🎉',
            );
            doubleOrNothingCompleted = true;
            doubleOrNothingCoinsWon = coinsAwarded;
          }

          // Update coins from response
          if (result.containsKey('coins_remaining')) {
            _userCoins = result['coins_remaining'] as int?;
          }

          // Reload to get updated status
          await load();
        }
      } catch (e) {
        debugPrint(
          '[BackendChallengeService] Failed to complete double-or-nothing day: $e',
        );
      }
    }

    return LessonCompletionResult(
      completedChallengeIds: completedChallengeIds,
      doubleOrNothingCompleted: doubleOrNothingCompleted,
      doubleOrNothingCoinsWon: doubleOrNothingCoinsWon,
    );
  }

  /// Purchase a streak freeze
  Future<bool> purchaseStreakFreeze() async {
    try {
      final result = await _api.purchaseStreakFreeze();

      // Update local state from response
      _userCoins = result['coins_remaining'] as int?;
      _userStreakFreezes = result['streak_freezes_owned'] as int?;

      notifyListeners();
      debugPrint(
        '[BackendChallengeService] Streak freeze purchased! Coins: $_userCoins, Freezes: $_userStreakFreezes',
      );
      return true;
    } catch (e) {
      debugPrint(
        '[BackendChallengeService] Failed to purchase streak freeze: $e',
      );
      return false;
    }
  }

  /// Start a double or nothing challenge
  Future<bool> startDoubleOrNothing({required int wager, int days = 7}) async {
    try {
      final result = await _api.startDoubleOrNothing(wager: wager, days: days);

      // Update coins from response
      _userCoins = result['coins_remaining'] as int?;

      await load(); // Reload to get updated status
      notifyListeners();
      debugPrint(
        '[BackendChallengeService] Double or nothing started: ${result['message']}',
      );
      return true;
    } catch (e) {
      debugPrint(
        '[BackendChallengeService] Failed to start double or nothing: $e',
      );
      return false;
    }
  }
}
