import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'progress_store.dart';

/// Centralized service for progress tracking and gamification
class ProgressService extends ChangeNotifier {
  ProgressService(this._store);

  final ProgressStore _store;
  Map<String, dynamic> _progress = {};
  bool _loaded = false;
  Future<void> _updateChain = Future.value();

  int get xpTotal => _progress['xpTotal'] as int? ?? 0;
  int get streakDays => _progress['streakDays'] as int? ?? 0;
  String? get lastLessonAt => _progress['lastLessonAt'] as String?;
  int get totalLessons => _progress['totalLessons'] as int? ?? 0;
  int get perfectLessons => _progress['perfectLessons'] as int? ?? 0;
  int get wordsLearned => _progress['wordsLearned'] as int? ?? 0;
  int get dailyXP => _progress['dailyXP'] as int? ?? 0;
  String? get lastXPResetDate => _progress['lastXPResetDate'] as String?;

  int get currentLevel => calculateLevel(xpTotal);
  int get xpForCurrentLevel => getXPForLevel(currentLevel);
  int get xpForNextLevel => getXPForLevel(currentLevel + 1);
  double get progressToNextLevel => getProgressToNextLevel(xpTotal);

  /// Calculate level from total XP: Level = floor(sqrt(XP/100))
  static int calculateLevel(int xp) {
    if (xp <= 0) return 0;
    return (sqrt(xp / 100)).floor();
  }

  /// Get XP required to reach a specific level: XP = level^2 * 100
  static int getXPForLevel(int level) {
    return level * level * 100;
  }

  /// Get progress percentage to next level (0.0 to 1.0)
  static double getProgressToNextLevel(int xp) {
    final currentLevel = calculateLevel(xp);
    final currentLevelXP = getXPForLevel(currentLevel);
    final nextLevelXP = getXPForLevel(currentLevel + 1);
    final xpInCurrentLevel = xp - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;
    if (xpNeededForNextLevel == 0) return 0.0;
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  /// Get XP remaining to next level
  int get xpToNextLevel => xpForNextLevel - xpTotal;

  Future<void> load() async {
    try {
      _progress = await _store.load();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[ProgressService] Failed to load progress: $e');
      _progress = {};
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> updateProgress({
    required int xpGained,
    required DateTime timestamp,
    bool isPerfect = false,
    int wordsLearnedCount = 0,
    bool countLesson = true,
  }) async {
    // Chain this update after the previous one completes
    // This ensures all updates execute sequentially in order
    final previousUpdate = _updateChain;
    final completer = Completer<void>();

    _updateChain = previousUpdate.then((_) async {
      try {
        await _performUpdate(
          xpGained,
          timestamp,
          isPerfect,
          wordsLearnedCount,
          countLesson,
        );
        completer.complete();
      } catch (e) {
        completer.completeError(e);
        rethrow;
      }
    });

    // Wait for this specific update to complete
    return completer.future;
  }

  Future<void> _performUpdate(
    int xpGained,
    DateTime timestamp,
    bool isPerfect,
    int wordsLearnedCount,
    bool countLesson,
  ) async {
    try {
      final oldLevel = currentLevel;

      // Create updated copy WITHOUT modifying current state
      final updatedProgress = Map<String, dynamic>.from(_progress);
      updatedProgress['xpTotal'] = xpTotal + xpGained;
      if (countLesson) {
        updatedProgress['lastLessonAt'] = timestamp.toIso8601String();
        updatedProgress['totalLessons'] = totalLessons + 1;
        updatedProgress['wordsLearned'] = wordsLearned + wordsLearnedCount;
        if (isPerfect) {
          updatedProgress['perfectLessons'] = perfectLessons + 1;
        }
      }

      // Track daily XP (reset at midnight)
      final today = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final lastReset = lastXPResetDate != null
          ? DateTime.parse(lastXPResetDate!)
          : null;

      if (lastReset == null ||
          today.difference(DateTime(lastReset.year, lastReset.month, lastReset.day)).inDays > 0) {
        // New day - reset daily XP
        updatedProgress['dailyXP'] = xpGained;
        updatedProgress['lastXPResetDate'] = today.toIso8601String();
      } else {
        // Same day - add to daily XP
        updatedProgress['dailyXP'] = dailyXP + xpGained;
      }

      // Update streak logic (tracks daily, not per-lesson)
      if (countLesson) {
        final lastStreakUpdate = updatedProgress['lastStreakUpdate'] as String?;
        if (lastStreakUpdate != null) {
          final lastUpdate = DateTime.parse(lastStreakUpdate);
          final lastUpdateDay = DateTime(
            lastUpdate.year,
            lastUpdate.month,
            lastUpdate.day,
          );
          final daysDiff = today.difference(lastUpdateDay).inDays;

          if (daysDiff == 0) {
            // Same day - don't increment streak
            // Streak remains the same
          } else if (daysDiff == 1) {
            // Next day - increment streak
            updatedProgress['streakDays'] =
                (updatedProgress['streakDays'] as int? ?? 0) + 1;
            updatedProgress['lastStreakUpdate'] = today.toIso8601String();
          } else {
            // Gap - reset streak
            updatedProgress['streakDays'] = 1;
            updatedProgress['lastStreakUpdate'] = today.toIso8601String();
          }
        } else {
          // First lesson ever
          updatedProgress['streakDays'] = 1;
          updatedProgress['lastStreakUpdate'] = today.toIso8601String();
        }
      }

      // Save to storage FIRST - if this fails, we don't update memory
      await _store.save(updatedProgress);

      // Only update memory state after successful save
      _progress = updatedProgress;
      notifyListeners();

      // Check for level up
      final newLevel = currentLevel;
      if (newLevel > oldLevel) {
        debugPrint('[ProgressService] Level up! $oldLevel -> $newLevel');
      }
    } catch (e) {
      debugPrint('[ProgressService] Failed to update progress: $e');
      // Memory state unchanged - safe to keep displaying old state
      rethrow; // Let caller handle the error
    }
  }

  Future<void> reset() async {
    await _store.reset();
    _progress = await _store.load();
    notifyListeners();
  }

  bool get hasProgress => xpTotal > 0 || streakDays > 0;
  bool get isLoaded => _loaded;
}
