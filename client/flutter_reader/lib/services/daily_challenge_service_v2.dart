import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_challenge.dart';
import '../models/challenge_streak.dart';
import '../utils/error_messages.dart';
import 'backend_challenge_service.dart';
import 'challenges_api.dart';
import 'progress_service.dart';
import 'power_up_service.dart';

/// Service for managing daily challenges using BACKEND API
/// This replaces the old local-generation service while maintaining the same interface
class DailyChallengeServiceV2 extends ChangeNotifier {
  DailyChallengeServiceV2(
    this._progressService,
    this._powerUpService,
    this._backendService,
  );

  final ProgressService _progressService;
  final PowerUpService _powerUpService;
  final BackendChallengeService _backendService;

  static const String _cacheKey = 'cached_daily_challenges';
  static const String _streakCacheKey = 'cached_streak';

  List<DailyChallenge> _challenges = [];
  ChallengeStreak _streak = ChallengeStreak.initial();
  bool _loaded = false;
  String? _lastError;

  List<DailyChallenge> get challenges => List.unmodifiable(_challenges);
  bool get isLoaded => _loaded;
  String? get lastError => _lastError;

  List<DailyChallenge> get activeChallenges =>
      _challenges.where((c) => !c.isCompleted && !c.isExpired).toList();

  List<DailyChallenge> get completedChallenges =>
      _challenges.where((c) => c.isCompleted).toList();

  int get completedCount => completedChallenges.length;
  int get totalRewardsEarned =>
      completedChallenges.fold(0, (sum, c) => sum + c.coinReward);

  ChallengeStreak get streak => _streak;
  int get currentStreak => _streak.currentStreak;
  int get longestStreak => _streak.longestStreak;
  bool get hasCompletedAllToday => _streak.isActiveToday;

  bool get allChallengesCompletedToday {
    if (_challenges.isEmpty) return false;
    return _challenges.where((c) => !c.isExpired).every((c) => c.isCompleted);
  }

  /// Load challenges from backend API
  Future<void> load() async {
    try {
      // Try to load from backend
      await _backendService.load();

      // Convert backend challenges to local model
      _challenges = _backendService.dailyChallenges
          .map(_convertFromBackend)
          .toList();

      // Convert streak
      final backendStreak = _backendService.streak;
      if (backendStreak != null) {
        _streak = ChallengeStreak(
          currentStreak: backendStreak.currentStreak,
          longestStreak: backendStreak.longestStreak,
          totalDaysCompleted: backendStreak.totalDaysCompleted,
          lastCompletionDate: backendStreak.lastCompletionDate,
          isActiveToday: backendStreak.isActiveToday,
        );
      }

      // Cache for offline use
      await _cacheData();

      _loaded = true;
      notifyListeners();

      _lastError = null;
      debugPrint('[DailyChallengeServiceV2] Loaded ${_challenges.length} challenges from backend');
    } catch (e) {
      _lastError = ErrorMessages.forChallengeLoad(e);
      debugPrint('[DailyChallengeServiceV2] Failed to load from backend: $e');
      // Try to load from cache
      await _loadFromCache();
      _loaded = true;
      notifyListeners();
    }
  }

  /// Convert backend API response to local model
  DailyChallenge _convertFromBackend(DailyChallengeApiResponse api) {
    return DailyChallenge(
      id: api.id.toString(),
      type: _parseChallengeType(api.challengeType),
      difficulty: _parseDifficulty(api.difficulty),
      title: api.title,
      description: api.description,
      targetValue: api.targetValue,
      currentProgress: api.currentProgress,
      coinReward: api.coinReward,
      xpReward: api.xpReward,
      expiresAt: api.expiresAt,
      isCompleted: api.isCompleted,
      completedAt: api.completedAt,
      isWeekendBonus: api.isWeekendBonus,
    );
  }

  DailyChallengeType _parseChallengeType(String type) {
    switch (type) {
      case 'lessons_completed':
        return DailyChallengeType.lessonsCompleted;
      case 'xp_earned':
        return DailyChallengeType.xpEarned;
      case 'perfect_score':
        return DailyChallengeType.perfectScore;
      case 'streak_maintain':
        return DailyChallengeType.streakMaintain;
      case 'words_learned':
        return DailyChallengeType.wordsLearned;
      case 'time_spent':
        return DailyChallengeType.timeSpent;
      case 'combo_achieved':
        return DailyChallengeType.comboAchieved;
      default:
        return DailyChallengeType.lessonsCompleted;
    }
  }

  ChallengeDifficulty _parseDifficulty(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return ChallengeDifficulty.easy;
      case 'medium':
        return ChallengeDifficulty.medium;
      case 'hard':
        return ChallengeDifficulty.hard;
      case 'epic':
      case 'expert':
        return ChallengeDifficulty.expert;
      default:
        return ChallengeDifficulty.medium;
    }
  }

  /// Update progress on challenges
  /// Now calls backend API instead of updating locally
  Future<List<DailyChallenge>> updateProgress(
    DailyChallengeType type,
    int increment,
  ) async {
    final completedChallenges = <DailyChallenge>[];

    for (final challenge in _challenges) {
      if (challenge.type == type &&
          !challenge.isCompleted &&
          !challenge.isExpired) {
        try {
          // Call backend API
          final challengeId = int.parse(challenge.id);
          final completed = await _backendService.updateDailyChallengeProgress(
            challengeId: challengeId,
            increment: increment,
          );

          if (completed) {
            // Reload challenges to get updated state
            await load();

            // Find the completed challenge in the new list
            final updatedChallenge = _challenges.firstWhere(
              (c) => c.id == challenge.id,
              orElse: () => challenge,
            );

            if (updatedChallenge.isCompleted) {
              completedChallenges.add(updatedChallenge);
            }
          }
        } catch (e) {
          _lastError = ErrorMessages.forChallengeUpdate(e);
          debugPrint('[DailyChallengeServiceV2] Failed to update progress: $e');
          // Queue for later sync when online
          await _queuePendingUpdate(challenge.id, increment);
          notifyListeners();
        }
      }
    }

    return completedChallenges;
  }

  /// Update progress for lesson completion
  Future<List<DailyChallenge>> onLessonCompleted({
    required int xpEarned,
    required bool isPerfect,
    required int wordsLearned,
  }) async {
    final allCompletedChallenges = <DailyChallenge>[];

    // Update lessons completed
    final lessonsCompleted =
        await updateProgress(DailyChallengeType.lessonsCompleted, 1);
    allCompletedChallenges.addAll(lessonsCompleted);

    // Update XP earned
    final xpCompleted =
        await updateProgress(DailyChallengeType.xpEarned, xpEarned);
    allCompletedChallenges.addAll(xpCompleted);

    // Update perfect scores
    if (isPerfect) {
      final perfectCompleted =
          await updateProgress(DailyChallengeType.perfectScore, 1);
      allCompletedChallenges.addAll(perfectCompleted);
    }

    // Update words learned
    final wordsCompleted =
        await updateProgress(DailyChallengeType.wordsLearned, wordsLearned);
    allCompletedChallenges.addAll(wordsCompleted);

    // Update streak maintain
    final streakCompleted =
        await updateProgress(DailyChallengeType.streakMaintain, 1);
    allCompletedChallenges.addAll(streakCompleted);

    return allCompletedChallenges;
  }

  /// Cache challenges for offline use
  Future<void> _cacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cache challenges
      final challengesList = _challenges.map((c) => c.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(challengesList));

      // Cache streak
      await prefs.setString(_streakCacheKey, json.encode(_streak.toJson()));

      debugPrint('[DailyChallengeServiceV2] Cached ${_challenges.length} challenges');
    } catch (e) {
      debugPrint('[DailyChallengeServiceV2] Failed to cache data: $e');
    }
  }

  /// Load challenges from cache (offline mode)
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load challenges
      final challengesJson = prefs.getString(_cacheKey);
      if (challengesJson != null) {
        final decoded = json.decode(challengesJson) as List;
        _challenges = decoded
            .map((item) => DailyChallenge.fromJson(item))
            .where((c) => !c.isExpired)
            .toList();
      }

      // Load streak
      final streakJson = prefs.getString(_streakCacheKey);
      if (streakJson != null) {
        _streak = ChallengeStreak.fromJson(json.decode(streakJson));
      }

      debugPrint('[DailyChallengeServiceV2] Loaded ${_challenges.length} challenges from cache');
    } catch (e) {
      debugPrint('[DailyChallengeServiceV2] Failed to load from cache: $e');
    }
  }

  /// Queue update for later sync when back online
  Future<void> _queuePendingUpdate(String challengeId, int increment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = 'pending_challenge_updates';

      final queueJson = prefs.getString(queueKey) ?? '[]';
      final queue = json.decode(queueJson) as List;

      queue.add({
        'challenge_id': challengeId,
        'increment': increment,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(queueKey, json.encode(queue));
      debugPrint('[DailyChallengeServiceV2] Queued update for challenge $challengeId');
    } catch (e) {
      debugPrint('[DailyChallengeServiceV2] Failed to queue update: $e');
    }
  }

  /// Sync pending updates when back online
  Future<void> syncPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = 'pending_challenge_updates';

      final queueJson = prefs.getString(queueKey);
      if (queueJson == null) return;

      final queue = json.decode(queueJson) as List;
      if (queue.isEmpty) return;

      debugPrint('[DailyChallengeServiceV2] Syncing ${queue.length} pending updates');

      for (final update in queue.toList()) {
        try {
          final challengeId = int.parse(update['challenge_id'] as String);
          final increment = update['increment'] as int;

          await _backendService.updateDailyChallengeProgress(
            challengeId: challengeId,
            increment: increment,
          );

          // Remove from queue
          queue.remove(update);
        } catch (e) {
          debugPrint('[DailyChallengeServiceV2] Failed to sync update: $e');
          break; // Stop syncing on error
        }
      }

      // Save updated queue
      await prefs.setString(queueKey, json.encode(queue));

      // Reload challenges to get updated state
      if (queue.isEmpty) {
        await load();
      }
    } catch (e) {
      debugPrint('[DailyChallengeServiceV2] Failed to sync pending updates: $e');
    }
  }

  /// Refresh challenges from backend
  Future<void> refresh() async {
    await load();
  }
}
