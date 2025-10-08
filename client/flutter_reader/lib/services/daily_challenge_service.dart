import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_challenge.dart';
import '../models/challenge_streak.dart';
import 'progress_service.dart';
import 'power_up_service.dart';

/// Service for managing daily challenges and challenge streaks
class DailyChallengeService extends ChangeNotifier {
  DailyChallengeService(this._progressService, this._powerUpService);

  final ProgressService _progressService;
  final PowerUpService _powerUpService;

  static const String _challengesKey = 'daily_challenges';
  static const String _lastGeneratedKey = 'challenges_last_generated';
  static const String _streakKey = 'challenge_streak';

  List<DailyChallenge> _challenges = [];
  ChallengeStreak _streak = ChallengeStreak.initial();
  bool _loaded = false;

  List<DailyChallenge> get challenges => List.unmodifiable(_challenges);
  bool get isLoaded => _loaded;

  List<DailyChallenge> get activeChallenges =>
      _challenges.where((c) => !c.isCompleted && !c.isExpired).toList();

  List<DailyChallenge> get completedChallenges =>
      _challenges.where((c) => c.isCompleted).toList();

  int get completedCount => completedChallenges.length;
  int get totalRewardsEarned => completedChallenges.fold(
      0, (sum, c) => sum + c.coinReward);

  // Challenge streak getters
  ChallengeStreak get streak => _streak;
  int get currentStreak => _streak.currentStreak;
  int get longestStreak => _streak.longestStreak;
  bool get hasCompletedAllToday => _streak.isActiveToday;

  // Check if all today's challenges are completed
  bool get allChallengesCompletedToday {
    if (_challenges.isEmpty) return false;
    return _challenges.where((c) => !c.isExpired).every((c) => c.isCompleted);
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load streak data
      final streakJson = prefs.getString(_streakKey);
      if (streakJson != null) {
        _streak = ChallengeStreak.fromJson(json.decode(streakJson));
      }

      // Check if we need to generate new challenges for today
      final lastGenerated = prefs.getString(_lastGeneratedKey);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      if (lastGenerated != todayStr) {
        // New day - check if streak broke
        await _checkStreakStatus();
        // Generate new challenges for today
        await _generateDailyChallenges();
      } else {
        // Load existing challenges
        final challengesJson = prefs.getString(_challengesKey);
        if (challengesJson != null) {
          final decoded = json.decode(challengesJson) as List;
          _challenges = decoded
              .map((item) => DailyChallenge.fromJson(item))
              .where((c) => !c.isExpired) // Filter expired
              .toList();
        } else {
          await _generateDailyChallenges();
        }
      }

      // Check if all challenges completed today for streak
      if (allChallengesCompletedToday && !_streak.isActiveToday) {
        await _updateStreakForCompletion();
      }

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[DailyChallengeService] Failed to load: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _generateDailyChallenges() async {
    final userLevel = _progressService.currentLevel;
    _challenges = DailyChallenge.generateDaily(userLevel);

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    await prefs.setString(_lastGeneratedKey, todayStr);
    await _save();
    notifyListeners();
  }

  /// Update progress on a challenge based on user actions
  /// Returns list of newly completed challenges
  Future<List<DailyChallenge>> updateProgress(
    DailyChallengeType type,
    int increment,
  ) async {
    final completedChallenges = <DailyChallenge>[];

    for (var i = 0; i < _challenges.length; i++) {
      final challenge = _challenges[i];

      if (challenge.type == type &&
          !challenge.isCompleted &&
          !challenge.isExpired) {
        final newProgress = challenge.currentProgress + increment;
        final wasCompleted = challenge.isCompleted;

        _challenges[i] = challenge.copyWith(
          currentProgress: newProgress,
          isCompleted: newProgress >= challenge.targetValue,
          completedAt: newProgress >= challenge.targetValue && !wasCompleted
              ? DateTime.now()
              : challenge.completedAt,
        );

        // If just completed, grant rewards
        if (!wasCompleted && _challenges[i].isCompleted) {
          await _grantRewards(_challenges[i]);
          completedChallenges.add(_challenges[i]);
        }
      }
    }

    await _save();
    notifyListeners();

    // Check if all challenges completed for streak update
    if (allChallengesCompletedToday && !_streak.isActiveToday) {
      await _updateStreakForCompletion();
    }

    return completedChallenges;
  }

  /// Update progress for lesson completion
  /// Returns list of all newly completed challenges
  Future<List<DailyChallenge>> onLessonCompleted({
    required int xpEarned,
    required bool isPerfect,
    required int wordsLearned,
  }) async {
    final allCompletedChallenges = <DailyChallenge>[];

    // Update lessons completed
    final lessonsCompleted = await updateProgress(DailyChallengeType.lessonsCompleted, 1);
    allCompletedChallenges.addAll(lessonsCompleted);

    // Update XP earned
    final xpCompleted = await updateProgress(DailyChallengeType.xpEarned, xpEarned);
    allCompletedChallenges.addAll(xpCompleted);

    // Update perfect scores
    if (isPerfect) {
      final perfectCompleted = await updateProgress(DailyChallengeType.perfectScore, 1);
      allCompletedChallenges.addAll(perfectCompleted);
    }

    // Update words learned
    final wordsCompleted = await updateProgress(DailyChallengeType.wordsLearned, wordsLearned);
    allCompletedChallenges.addAll(wordsCompleted);

    // Update streak maintain (if they complete a lesson, they're maintaining streak)
    final streakCompleted = await updateProgress(DailyChallengeType.streakMaintain, 1);
    allCompletedChallenges.addAll(streakCompleted);

    return allCompletedChallenges;
  }

  Future<void> _grantRewards(DailyChallenge challenge) async {
    try {
      // Grant coins
      await _powerUpService.addCoins(challenge.coinReward);

      // Grant XP
      await _progressService.updateProgress(
        xpGained: challenge.xpReward,
        timestamp: DateTime.now(),
        isPerfect: false,
        wordsLearnedCount: 0,
        countLesson: false, // Don't count as lesson
      );

      debugPrint(
        '[DailyChallengeService] Rewards granted: ${challenge.coinReward} coins, ${challenge.xpReward} XP',
      );
    } catch (e) {
      debugPrint('[DailyChallengeService] Failed to grant rewards: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesList = _challenges.map((c) => c.toJson()).toList();
      await prefs.setString(_challengesKey, json.encode(challengesList));

      // Save streak data
      await prefs.setString(_streakKey, json.encode(_streak.toJson()));
    } catch (e) {
      debugPrint('[DailyChallengeService] Failed to save: $e');
    }
  }

  /// Check streak status when a new day starts
  Future<void> _checkStreakStatus() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      _streak.lastCompletionDate.year,
      _streak.lastCompletionDate.month,
      _streak.lastCompletionDate.day,
    );

    final daysDiff = today.difference(lastDay).inDays;

    if (daysDiff > 1 && _streak.currentStreak > 0) {
      // Streak broken - reset to 0
      _streak = _streak.copyWith(
        currentStreak: 0,
        isActiveToday: false,
      );
      await _save();
    } else if (daysDiff == 1) {
      // New day, reset today's completion status
      _streak = _streak.copyWith(isActiveToday: false);
      await _save();
    }
  }

  /// Update streak when all challenges completed
  Future<void> _updateStreakForCompletion() async {
    final now = DateTime.now();
    final newStreak = _streak.currentStreak + 1;
    final newLongest = newStreak > _streak.longestStreak
        ? newStreak
        : _streak.longestStreak;

    _streak = _streak.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastCompletionDate: now,
      totalDaysCompleted: _streak.totalDaysCompleted + 1,
      isActiveToday: true,
    );

    await _save();

    // Grant bonus rewards for streak milestones
    if (newStreak == 7 || newStreak == 30 || newStreak == 100) {
      await _grantStreakMilestoneReward(newStreak);
    }

    notifyListeners();
  }

  /// Grant bonus rewards for streak milestones
  Future<void> _grantStreakMilestoneReward(int streak) async {
    int bonusCoins = 0;
    int bonusXP = 0;

    if (streak == 7) {
      bonusCoins = 100;
      bonusXP = 50;
    } else if (streak == 30) {
      bonusCoins = 500;
      bonusXP = 250;
    } else if (streak == 100) {
      bonusCoins = 2000;
      bonusXP = 1000;
    }

    if (bonusCoins > 0) {
      await _powerUpService.addCoins(bonusCoins);
      await _progressService.updateProgress(
        xpGained: bonusXP,
        timestamp: DateTime.now(),
        countLesson: false,
      );

      debugPrint(
        '[DailyChallengeService] Streak milestone $streak reached! Bonus: $bonusCoins coins, $bonusXP XP',
      );
    }
  }

  /// Force refresh challenges (for testing or manual refresh)
  Future<void> refreshChallenges() async {
    await _generateDailyChallenges();
  }

  Future<void> reset() async {
    _challenges.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_challengesKey);
    await prefs.remove(_lastGeneratedKey);
    notifyListeners();
  }
}
