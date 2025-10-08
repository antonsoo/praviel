import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking daily XP goals and streaks
class DailyGoalService extends ChangeNotifier {
  static const String _goalKey = 'daily_goal';
  static const String _lastCheckKey = 'daily_goal_last_check';
  static const String _streakKey = 'daily_goal_streak';
  static const String _progressKey = 'daily_goal_progress';

  int _dailyGoalXP = 50; // Default: 50 XP per day
  int _currentProgress = 0;
  int _goalStreak = 0;
  DateTime? _lastCheck;
  bool _loaded = false;

  int get dailyGoalXP => _dailyGoalXP;
  int get currentProgress => _currentProgress;
  int get goalStreak => _goalStreak;
  double get progressPercentage => _dailyGoalXP > 0
      ? (_currentProgress / _dailyGoalXP).clamp(0.0, 1.0)
      : 0.0;
  bool get isGoalMet => _currentProgress >= _dailyGoalXP;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyGoalXP = prefs.getInt(_goalKey) ?? 50;
      _goalStreak = prefs.getInt(_streakKey) ?? 0;
      _currentProgress = prefs.getInt(_progressKey) ?? 0;

      final lastCheckStr = prefs.getString(_lastCheckKey);
      if (lastCheckStr != null) {
        _lastCheck = DateTime.parse(lastCheckStr);
        _checkDayRollover();
      }

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[DailyGoalService] Failed to load: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  /// Check if we need to reset progress for a new day
  void _checkDayRollover() {
    if (_lastCheck == null) return;

    final now = DateTime.now();
    final lastCheckDay = DateTime(
      _lastCheck!.year,
      _lastCheck!.month,
      _lastCheck!.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    if (today.isAfter(lastCheckDay)) {
      final daysDiff = today.difference(lastCheckDay).inDays;

      if (daysDiff == 1 && _currentProgress >= _dailyGoalXP) {
        // Goal was met yesterday, increment streak
        _goalStreak++;
      } else if (daysDiff > 1) {
        // Missed days, reset streak
        _goalStreak = 0;
      } else if (daysDiff == 1 && _currentProgress < _dailyGoalXP) {
        // Goal not met yesterday, reset streak
        _goalStreak = 0;
      }

      // Reset progress for new day
      _currentProgress = 0;
      _save();
    }
  }

  /// Add XP to today's progress
  Future<void> addProgress(int xp) async {
    _checkDayRollover();

    final wasGoalMet = isGoalMet;
    _currentProgress += xp;
    _lastCheck = DateTime.now();

    // Check if goal was just completed
    final nowGoalMet = isGoalMet;
    if (!wasGoalMet && nowGoalMet) {
      debugPrint('[DailyGoalService] Daily goal completed! 🎉');
    }

    await _save();
    notifyListeners();
  }

  /// Update the daily goal target
  Future<void> setDailyGoal(int xp) async {
    _dailyGoalXP = xp.clamp(10, 1000); // Min 10, max 1000
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_goalKey, _dailyGoalXP);
      await prefs.setInt(_streakKey, _goalStreak);
      await prefs.setInt(_progressKey, _currentProgress);
      if (_lastCheck != null) {
        await prefs.setString(_lastCheckKey, _lastCheck!.toIso8601String());
      }
    } catch (e) {
      debugPrint('[DailyGoalService] Failed to save: $e');
    }
  }

  Future<void> reset() async {
    _dailyGoalXP = 50;
    _currentProgress = 0;
    _goalStreak = 0;
    _lastCheck = null;
    await _save();
    notifyListeners();
  }
}

/// Suggested daily goals based on user level
class DailyGoalPresets {
  static const casual = 25; // 1-2 exercises
  static const regular = 50; // 2-4 exercises
  static const serious = 100; // 4-8 exercises
  static const intense = 200; // 8+ exercises

  static String getLabel(int xp) {
    if (xp <= 25) return 'Casual';
    if (xp <= 50) return 'Regular';
    if (xp <= 100) return 'Serious';
    return 'Intense';
  }

  static List<int> get allPresets => [casual, regular, serious, intense];
}
