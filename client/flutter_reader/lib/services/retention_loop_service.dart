import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Retention Loop Architecture
/// Implements psychological engagement mechanics from 2025 research
/// - Streaks increase retention by 22%
/// - Variable rewards boost engagement by 100-150%
/// - Social proof increases return rate by 30%
class RetentionLoopService extends ChangeNotifier {
  static const String _loopsKey = 'retention_loops_state';

  // Core loops
  DailyHabitLoop? _dailyLoop;
  WeeklyGoalLoop? _weeklyLoop;
  SocialCompetitionLoop? _socialLoop;
  MasteryProgressLoop? _masteryLoop;

  bool _loaded = false;

  bool get isLoaded => _loaded;
  DailyHabitLoop? get dailyLoop => _dailyLoop;
  WeeklyGoalLoop? get weeklyLoop => _weeklyLoop;
  SocialCompetitionLoop? get socialLoop => _socialLoop;
  MasteryProgressLoop? get masteryLoop => _masteryLoop;

  /// Load all loops
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_loopsKey);

      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _dailyLoop = DailyHabitLoop.fromJson(data['daily'] ?? {});
        _weeklyLoop = WeeklyGoalLoop.fromJson(data['weekly'] ?? {});
        _socialLoop = SocialCompetitionLoop.fromJson(data['social'] ?? {});
        _masteryLoop = MasteryProgressLoop.fromJson(data['mastery'] ?? {});
      } else {
        _dailyLoop = DailyHabitLoop();
        _weeklyLoop = WeeklyGoalLoop();
        _socialLoop = SocialCompetitionLoop();
        _masteryLoop = MasteryProgressLoop();
      }

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[RetentionLoopService] Failed to load: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  /// Check in for today (triggers all loops)
  Future<List<RetentionReward>> checkIn({
    required int xpEarned,
    required int lessonsCompleted,
  }) async {
    final rewards = <RetentionReward>[];

    // Daily habit loop
    if (_dailyLoop != null) {
      final dailyReward = _dailyLoop!.checkIn(DateTime.now());
      if (dailyReward != null) rewards.add(dailyReward);
    }

    // Weekly goal loop
    if (_weeklyLoop != null) {
      _weeklyLoop!.addProgress(xpEarned, lessonsCompleted);
      final weeklyReward = _weeklyLoop!.checkProgress();
      if (weeklyReward != null) rewards.add(weeklyReward);
    }

    // Mastery loop
    if (_masteryLoop != null) {
      final masteryReward = _masteryLoop!.addMastery(xpEarned);
      if (masteryReward != null) rewards.add(masteryReward);
    }

    await _save();
    notifyListeners();

    return rewards;
  }

  /// Update social loop (external data from leaderboard)
  Future<RetentionReward?> updateSocialRank({
    required int currentRank,
    required int totalUsers,
  }) async {
    if (_socialLoop == null) return null;

    final reward = _socialLoop!.updateRank(currentRank, totalUsers);
    await _save();
    notifyListeners();

    return reward;
  }

  /// Get next reward preview (creates anticipation)
  Map<String, String> getNextRewards() {
    final next = <String, String>{};

    if (_dailyLoop != null) {
      final daysUntilMilestone = _dailyLoop!.daysUntilNextMilestone();
      if (daysUntilMilestone != null) {
        next['streak'] =
            '$daysUntilMilestone days until ${_dailyLoop!.nextMilestone()} day streak!';
      }
    }

    if (_weeklyLoop != null) {
      final remaining = _weeklyLoop!.xpRemainingForGoal();
      if (remaining > 0) {
        next['weekly'] = '$remaining XP until weekly goal!';
      }
    }

    if (_masteryLoop != null) {
      final toNext = _masteryLoop!.xpToNextLevel();
      next['mastery'] =
          '$toNext XP to mastery level ${_masteryLoop!.currentLevel + 1}!';
    }

    return next;
  }

  /// Save state
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'daily': _dailyLoop?.toJson() ?? {},
        'weekly': _weeklyLoop?.toJson() ?? {},
        'social': _socialLoop?.toJson() ?? {},
        'mastery': _masteryLoop?.toJson() ?? {},
      };
      await prefs.setString(_loopsKey, jsonEncode(data));
    } catch (e) {
      debugPrint('[RetentionLoopService] Failed to save: $e');
    }
  }

  /// Reset all loops
  Future<void> reset() async {
    _dailyLoop = DailyHabitLoop();
    _weeklyLoop = WeeklyGoalLoop();
    _socialLoop = SocialCompetitionLoop();
    _masteryLoop = MasteryProgressLoop();
    await _save();
    notifyListeners();
  }
}

/// Daily habit loop - creates daily check-in habit
class DailyHabitLoop {
  int currentStreak = 0;
  DateTime? lastCheckIn;
  List<int> milestones = [3, 7, 14, 30, 60, 100, 365];

  DailyHabitLoop({this.currentStreak = 0, this.lastCheckIn});

  RetentionReward? checkIn(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    if (lastCheckIn == null) {
      // First check-in
      currentStreak = 1;
      lastCheckIn = today;
      return RetentionReward(
        type: RewardType.streakStart,
        title: 'Started Your Journey!',
        description: 'Keep coming back daily to build a streak',
        xpBonus: 10,
      );
    }

    final lastDay = DateTime(
      lastCheckIn!.year,
      lastCheckIn!.month,
      lastCheckIn!.day,
    );
    final daysSince = today.difference(lastDay).inDays;

    if (daysSince == 1) {
      // Consecutive day
      currentStreak++;
      lastCheckIn = today;

      // Check for milestone
      if (milestones.contains(currentStreak)) {
        return RetentionReward(
          type: RewardType.streakMilestone,
          title: '$currentStreak Day Streak!',
          description: 'You\'re on fire! Keep it going!',
          xpBonus: currentStreak * 5,
        );
      }

      return null; // Regular check-in, no special reward
    } else if (daysSince == 0) {
      // Already checked in today
      return null;
    } else {
      // Streak broken
      final brokenStreak = currentStreak;
      currentStreak = 1;
      lastCheckIn = today;

      return RetentionReward(
        type: RewardType.streakBroken,
        title: 'Streak Reset',
        description: 'Your $brokenStreak day streak ended. Start fresh today!',
        xpBonus: 0,
      );
    }
  }

  int? daysUntilNextMilestone() {
    final next = milestones.firstWhere(
      (m) => m > currentStreak,
      orElse: () => -1,
    );
    return next > 0 ? next - currentStreak : null;
  }

  int? nextMilestone() {
    return milestones.firstWhere((m) => m > currentStreak, orElse: () => -1);
  }

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'lastCheckIn': lastCheckIn?.toIso8601String(),
  };

  factory DailyHabitLoop.fromJson(Map<String, dynamic> json) {
    return DailyHabitLoop(
      currentStreak: json['currentStreak'] ?? 0,
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'])
          : null,
    );
  }
}

/// Weekly goal loop - creates medium-term motivation
class WeeklyGoalLoop {
  int weeklyXpGoal = 500; // Default
  int currentWeekXp = 0;
  int currentWeekLessons = 0;
  DateTime? weekStartDate;

  WeeklyGoalLoop({
    this.weeklyXpGoal = 500,
    this.currentWeekXp = 0,
    this.currentWeekLessons = 0,
    this.weekStartDate,
  });

  void addProgress(int xp, int lessons) {
    _checkWeekRollover();
    currentWeekXp += xp;
    currentWeekLessons += lessons;
  }

  RetentionReward? checkProgress() {
    _checkWeekRollover();

    if (currentWeekXp >= weeklyXpGoal && currentWeekXp - weeklyXpGoal < 100) {
      // Just hit the goal
      return RetentionReward(
        type: RewardType.weeklyGoal,
        title: 'Weekly Goal Achieved!',
        description: 'You earned $currentWeekXp XP this week!',
        xpBonus: 100,
      );
    }

    return null;
  }

  void _checkWeekRollover() {
    final now = DateTime.now();
    if (weekStartDate == null) {
      weekStartDate = _getWeekStart(now);
      return;
    }

    final weekStart = _getWeekStart(now);
    if (weekStart.isAfter(weekStartDate!)) {
      // New week
      currentWeekXp = 0;
      currentWeekLessons = 0;
      weekStartDate = weekStart;
    }
  }

  DateTime _getWeekStart(DateTime date) {
    // Week starts on Monday
    final daysFromMonday = (date.weekday - DateTime.monday) % 7;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  int xpRemainingForGoal() {
    return (weeklyXpGoal - currentWeekXp).clamp(0, weeklyXpGoal);
  }

  Map<String, dynamic> toJson() => {
    'weeklyXpGoal': weeklyXpGoal,
    'currentWeekXp': currentWeekXp,
    'currentWeekLessons': currentWeekLessons,
    'weekStartDate': weekStartDate?.toIso8601String(),
  };

  factory WeeklyGoalLoop.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalLoop(
      weeklyXpGoal: json['weeklyXpGoal'] ?? 500,
      currentWeekXp: json['currentWeekXp'] ?? 0,
      currentWeekLessons: json['currentWeekLessons'] ?? 0,
      weekStartDate: json['weekStartDate'] != null
          ? DateTime.parse(json['weekStartDate'])
          : null,
    );
  }
}

/// Social competition loop - creates peer pressure motivation
class SocialCompetitionLoop {
  int currentRank = 0;
  int previousRank = 0;
  int totalUsers = 1;
  DateTime? lastUpdate;

  SocialCompetitionLoop({
    this.currentRank = 0,
    this.previousRank = 0,
    this.totalUsers = 1,
    this.lastUpdate,
  });

  RetentionReward? updateRank(int newRank, int total) {
    previousRank = currentRank;
    currentRank = newRank;
    totalUsers = total;
    lastUpdate = DateTime.now();

    // Check for rank improvements
    if (previousRank > 0 && newRank < previousRank) {
      final improvement = previousRank - newRank;
      return RetentionReward(
        type: RewardType.rankImprovement,
        title: 'Rank Up!',
        description:
            'You climbed $improvement ${improvement == 1 ? "spot" : "spots"}! Now #$newRank',
        xpBonus: improvement * 10,
      );
    }

    // Check for top percentile
    final percentile = (newRank / total * 100).round();
    if (percentile <= 10 && (previousRank / total * 100).round() > 10) {
      return RetentionReward(
        type: RewardType.topPercentile,
        title: 'Top 10%!',
        description: 'You\'re in the top tier of learners!',
        xpBonus: 200,
      );
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
    'currentRank': currentRank,
    'previousRank': previousRank,
    'totalUsers': totalUsers,
    'lastUpdate': lastUpdate?.toIso8601String(),
  };

  factory SocialCompetitionLoop.fromJson(Map<String, dynamic> json) {
    return SocialCompetitionLoop(
      currentRank: json['currentRank'] ?? 0,
      previousRank: json['previousRank'] ?? 0,
      totalUsers: json['totalUsers'] ?? 1,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : null,
    );
  }
}

/// Mastery progress loop - creates long-term engagement
class MasteryProgressLoop {
  int totalMastery = 0; // Total lifetime XP
  int currentLevel = 1;
  final List<int> levelThresholds = [
    0,
    100,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
    32000,
  ]; // XP needed for each level

  MasteryProgressLoop({this.totalMastery = 0, this.currentLevel = 1});

  RetentionReward? addMastery(int xp) {
    totalMastery += xp;
    final newLevel = _calculateLevel();

    if (newLevel > currentLevel) {
      // Level up!
      final oldLevel = currentLevel;
      currentLevel = newLevel;

      return RetentionReward(
        type: RewardType.masteryLevel,
        title: 'Mastery Level $currentLevel!',
        description: 'You advanced from level $oldLevel!',
        xpBonus: newLevel * 50,
      );
    }

    return null;
  }

  int _calculateLevel() {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (totalMastery >= levelThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  int xpToNextLevel() {
    if (currentLevel >= levelThresholds.length) {
      return 0; // Max level
    }
    return levelThresholds[currentLevel] - totalMastery;
  }

  Map<String, dynamic> toJson() => {
    'totalMastery': totalMastery,
    'currentLevel': currentLevel,
  };

  factory MasteryProgressLoop.fromJson(Map<String, dynamic> json) {
    return MasteryProgressLoop(
      totalMastery: json['totalMastery'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
    );
  }
}

/// Retention reward - variable reward that triggers dopamine
class RetentionReward {
  final RewardType type;
  final String title;
  final String description;
  final int xpBonus;

  RetentionReward({
    required this.type,
    required this.title,
    required this.description,
    required this.xpBonus,
  });
}

enum RewardType {
  streakStart,
  streakMilestone,
  streakBroken,
  weeklyGoal,
  rankImprovement,
  topPercentile,
  masteryLevel,
}
