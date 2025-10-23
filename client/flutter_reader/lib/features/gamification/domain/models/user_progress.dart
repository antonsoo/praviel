import 'dart:math' as math;

/// Immutable user progress model following professional clean architecture patterns
class UserProgress {
  final String userId;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final int lessonsCompleted;
  final int wordsLearned;
  final int minutesStudied;
  final Map<String, int> languageXp; // languageCode -> xp
  final List<String> unlockedAchievements;
  final List<DailyActivity> weeklyActivity;

  const UserProgress({
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.lessonsCompleted,
    required this.wordsLearned,
    required this.minutesStudied,
    required this.languageXp,
    required this.unlockedAchievements,
    this.weeklyActivity = const [],
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] as String,
      totalXp: json['totalXp'] as int,
      level: json['level'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastActivityDate: DateTime.parse(json['lastActivityDate'] as String),
      lessonsCompleted: json['lessonsCompleted'] as int,
      wordsLearned: json['wordsLearned'] as int,
      minutesStudied: json['minutesStudied'] as int,
      languageXp: Map<String, int>.from(json['languageXp'] as Map),
      unlockedAchievements:
          List<String>.from(json['unlockedAchievements'] as List),
      weeklyActivity: (json['weeklyActivity'] as List?)
              ?.map((e) => DailyActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalXp': totalXp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'lessonsCompleted': lessonsCompleted,
      'wordsLearned': wordsLearned,
      'minutesStudied': minutesStudied,
      'languageXp': languageXp,
      'unlockedAchievements': unlockedAchievements,
      'weeklyActivity': weeklyActivity.map((e) => e.toJson()).toList(),
    };
  }

  UserProgress copyWith({
    String? userId,
    int? totalXp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? lessonsCompleted,
    int? wordsLearned,
    int? minutesStudied,
    Map<String, int>? languageXp,
    List<String>? unlockedAchievements,
    List<DailyActivity>? weeklyActivity,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      wordsLearned: wordsLearned ?? this.wordsLearned,
      minutesStudied: minutesStudied ?? this.minutesStudied,
      languageXp: languageXp ?? this.languageXp,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
    );
  }

  /// Calculate XP needed for next level using exponential curve
  int get xpForNextLevel => _calculateXpForLevel(level + 1);

  /// Calculate progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    final currentLevelXp = _calculateXpForLevel(level);
    final nextLevelXp = xpForNextLevel;
    final xpInLevel = totalXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }

  /// Check if streak is active (studied today or yesterday)
  bool get isStreakActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastActivity = DateTime(
      lastActivityDate.year,
      lastActivityDate.month,
      lastActivityDate.day,
    );
    return lastActivity == today || lastActivity == yesterday;
  }

  /// Get rank based on total XP
  String get rank {
    if (totalXp >= 100000) return 'Grandmaster';
    if (totalXp >= 50000) return 'Master';
    if (totalXp >= 25000) return 'Expert';
    if (totalXp >= 10000) return 'Advanced';
    if (totalXp >= 5000) return 'Intermediate';
    if (totalXp >= 1000) return 'Beginner';
    return 'Novice';
  }

  static int _calculateXpForLevel(int level) {
    // Exponential XP curve: 100 * level^1.5
    return (100 * math.pow(level, 1.5)).round();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgress &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

/// Daily activity tracking
class DailyActivity {
  final DateTime date;
  final int lessonsCompleted;
  final int xpEarned;
  final int minutesStudied;

  const DailyActivity({
    required this.date,
    required this.lessonsCompleted,
    required this.xpEarned,
    required this.minutesStudied,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      date: DateTime.parse(json['date'] as String),
      lessonsCompleted: json['lessonsCompleted'] as int,
      xpEarned: json['xpEarned'] as int,
      minutesStudied: json['minutesStudied'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'lessonsCompleted': lessonsCompleted,
      'xpEarned': xpEarned,
      'minutesStudied': minutesStudied,
    };
  }
}

/// Achievement model with rarity system
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final AchievementRarity rarity;
  final int xpReward;
  final AchievementRequirement requirement;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.rarity,
    required this.xpReward,
    required this.requirement,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
      ),
      xpReward: json['xpReward'] as int,
      requirement: AchievementRequirement.fromJson(
        json['requirement'] as Map<String, dynamic>,
      ),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'rarity': rarity.name,
      'xpReward': xpReward,
      'requirement': requirement.toJson(),
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  Achievement copyWith({DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      rarity: rarity,
      xpReward: xpReward,
      requirement: requirement,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

/// Achievement requirement using sealed class pattern
sealed class AchievementRequirement {
  const AchievementRequirement();

  factory AchievementRequirement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final value = json['value'] as int;

    return switch (type) {
      'lessonsCount' => LessonsCountRequirement(value),
      'streakDays' => StreakDaysRequirement(value),
      'xpTotal' => XpTotalRequirement(value),
      'wordsLearned' => WordsLearnedRequirement(value),
      'perfectQuizzes' => PerfectQuizzesRequirement(value),
      'languagesMastered' => LanguagesMasteredRequirement(value),
      _ => throw ArgumentError('Unknown requirement type: $type'),
    };
  }

  Map<String, dynamic> toJson();
}

class LessonsCountRequirement extends AchievementRequirement {
  final int count;
  const LessonsCountRequirement(this.count);

  @override
  Map<String, dynamic> toJson() => {'type': 'lessonsCount', 'value': count};
}

class StreakDaysRequirement extends AchievementRequirement {
  final int days;
  const StreakDaysRequirement(this.days);

  @override
  Map<String, dynamic> toJson() => {'type': 'streakDays', 'value': days};
}

class XpTotalRequirement extends AchievementRequirement {
  final int xp;
  const XpTotalRequirement(this.xp);

  @override
  Map<String, dynamic> toJson() => {'type': 'xpTotal', 'value': xp};
}

class WordsLearnedRequirement extends AchievementRequirement {
  final int words;
  const WordsLearnedRequirement(this.words);

  @override
  Map<String, dynamic> toJson() => {'type': 'wordsLearned', 'value': words};
}

class PerfectQuizzesRequirement extends AchievementRequirement {
  final int count;
  const PerfectQuizzesRequirement(this.count);

  @override
  Map<String, dynamic> toJson() => {'type': 'perfectQuizzes', 'value': count};
}

class LanguagesMasteredRequirement extends AchievementRequirement {
  final int count;
  const LanguagesMasteredRequirement(this.count);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'languagesMastered', 'value': count};
}

/// Daily challenge model
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeDifficulty difficulty;
  final ChallengeType type;
  final int xpReward;
  final int coinsReward;
  final DateTime expiresAt;
  final ChallengeProgress progress;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.type,
    required this.xpReward,
    required this.coinsReward,
    required this.expiresAt,
    required this.progress,
  });

  bool get isCompleted => progress.isCompleted;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
      ),
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      xpReward: json['xpReward'] as int,
      coinsReward: json['coinsReward'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      progress: ChallengeProgress.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'type': type.name,
      'xpReward': xpReward,
      'coinsReward': coinsReward,
      'expiresAt': expiresAt.toIso8601String(),
      'progress': progress.toJson(),
    };
  }

  DailyChallenge copyWith({ChallengeProgress? progress}) {
    return DailyChallenge(
      id: id,
      title: title,
      description: description,
      difficulty: difficulty,
      type: type,
      xpReward: xpReward,
      coinsReward: coinsReward,
      expiresAt: expiresAt,
      progress: progress ?? this.progress,
    );
  }
}

enum ChallengeDifficulty { beginner, intermediate, advanced, expert }

enum ChallengeType {
  translation,
  vocabulary,
  grammar,
  reading,
  listening,
  speaking,
}

class ChallengeProgress {
  final int current;
  final int target;

  const ChallengeProgress({
    required this.current,
    required this.target,
  });

  bool get isCompleted => current >= target;
  double get percentage => (current / target).clamp(0.0, 1.0);

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      current: json['current'] as int,
      target: json['target'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'target': target,
    };
  }

  ChallengeProgress copyWith({int? current}) {
    return ChallengeProgress(
      current: current ?? this.current,
      target: target,
    );
  }
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String username;
  final String avatarUrl;
  final int rank;
  final int xp;
  final String languageCode;
  final LeaderboardPeriod period;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.rank,
    required this.xp,
    required this.languageCode,
    required this.period,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String,
      rank: json['rank'] as int,
      xp: json['xp'] as int,
      languageCode: json['languageCode'] as String,
      period: LeaderboardPeriod.values.firstWhere(
        (e) => e.name == json['period'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'rank': rank,
      'xp': xp,
      'languageCode': languageCode,
      'period': period.name,
    };
  }
}

enum LeaderboardPeriod {
  allTime,
  monthly,
  weekly,
  daily,
}

enum LeaderboardScope {
  global,
  friends,
  language,
}
