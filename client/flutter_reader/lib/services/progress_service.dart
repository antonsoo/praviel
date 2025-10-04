import 'dart:math';
import 'package:flutter/foundation.dart';
import 'progress_store.dart';

/// Centralized service for progress tracking and gamification
class ProgressService extends ChangeNotifier {
  ProgressService(this._store);

  final ProgressStore _store;
  Map<String, dynamic> _progress = {};
  bool _loaded = false;

  int get xpTotal => _progress['xpTotal'] as int? ?? 0;
  int get streakDays => _progress['streakDays'] as int? ?? 0;
  String? get lastLessonAt => _progress['lastLessonAt'] as String?;

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
    _progress = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateProgress({
    required int xpGained,
    required DateTime timestamp,
  }) async {
    final oldLevel = currentLevel;

    _progress['xpTotal'] = xpTotal + xpGained;
    _progress['lastLessonAt'] = timestamp.toIso8601String();

    // Update streak logic (tracks daily, not per-lesson)
    final lastStreakUpdate = _progress['lastStreakUpdate'] as String?;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastStreakUpdate != null) {
      final lastUpdate = DateTime.parse(lastStreakUpdate);
      final lastUpdateDay = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
      final daysDiff = today.difference(lastUpdateDay).inDays;

      if (daysDiff == 0) {
        // Same day - don't increment streak
        // Streak remains the same
      } else if (daysDiff == 1) {
        // Next day - increment streak
        _progress['streakDays'] = streakDays + 1;
        _progress['lastStreakUpdate'] = today.toIso8601String();
      } else {
        // Gap - reset streak
        _progress['streakDays'] = 1;
        _progress['lastStreakUpdate'] = today.toIso8601String();
      }
    } else {
      // First lesson ever
      _progress['streakDays'] = 1;
      _progress['lastStreakUpdate'] = today.toIso8601String();
    }

    await _store.save(_progress);
    notifyListeners();

    // Check for level up
    final newLevel = currentLevel;
    if (newLevel > oldLevel) {
      debugPrint('[ProgressService] Level up! $oldLevel → $newLevel');
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
