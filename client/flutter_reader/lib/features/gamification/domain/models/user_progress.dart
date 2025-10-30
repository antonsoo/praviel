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
  final String icon;
  final String iconName;
  final AchievementRarity rarity;
  final double? rarityPercent;
  final int xpReward;
  final int coinReward;
  final AchievementRequirement requirement;
  final DateTime? unlockedAt;
  final int tier;
  final String category;
  final Map<String, dynamic> unlockCriteria;
  final int? progressCurrent;
  final int? progressTarget;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconName,
    required this.rarity,
    required this.xpReward,
    required this.requirement,
    this.rarityPercent,
    this.coinReward = 0,
    this.unlockedAt,
    this.tier = 1,
    this.category = 'general',
    this.unlockCriteria = const {},
    this.progressCurrent,
    this.progressTarget,
  });

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final unlockCriteria =
        Map<String, dynamic>.from(json['unlock_criteria'] as Map? ?? {});

    final requirement = json['requirement'] is Map<String, dynamic>
        ? AchievementRequirement.fromJson(
            json['requirement'] as Map<String, dynamic>,
          )
        : AchievementRequirement.fromCriteria(unlockCriteria);

    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏅',
      iconName: json['icon_name'] as String? ??
          json['iconName'] as String? ??
          'emoji_events',
      rarity: AchievementRarityExtension.fromString(
        json['rarity_label'] as String? ?? json['rarity'] as String? ?? 'common',
      ),
      rarityPercent: (json['rarity_percent'] as num?)?.toDouble(),
      xpReward: json['xp_reward'] as int? ?? json['xpReward'] as int? ?? 0,
      coinReward: json['coin_reward'] as int? ?? json['coinReward'] as int? ?? 0,
      requirement: requirement,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : json['unlockedAt'] != null
              ? DateTime.parse(json['unlockedAt'] as String)
              : null,
      tier: json['tier'] as int? ?? 1,
      category: json['category'] as String? ?? 'general',
      unlockCriteria: unlockCriteria,
      progressCurrent: json['progress_current'] as int? ??
          json['progressCurrent'] as int?,
      progressTarget: json['progress_target'] as int? ??
          json['progressTarget'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'iconName': iconName,
      'rarity': rarity.name,
      'rarityPercent': rarityPercent,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'requirement': requirement.toJson(),
      'unlockedAt': unlockedAt?.toIso8601String(),
      'tier': tier,
      'category': category,
      'unlockCriteria': unlockCriteria,
      'progressCurrent': progressCurrent,
      'progressTarget': progressTarget,
    };
  }

  Achievement copyWith({DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      iconName: iconName,
      rarity: rarity,
      xpReward: xpReward,
      requirement: requirement,
      rarityPercent: rarityPercent,
      coinReward: coinReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      tier: tier,
      category: category,
      unlockCriteria: unlockCriteria,
      progressCurrent: progressCurrent,
      progressTarget: progressTarget,
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

extension AchievementRarityExtension on AchievementRarity {
  static AchievementRarity fromString(String? value) {
    final normalized = (value ?? '').toLowerCase().trim();
    switch (normalized) {
      case 'uncommon':
        return AchievementRarity.uncommon;
      case 'rare':
        return AchievementRarity.rare;
      case 'epic':
        return AchievementRarity.epic;
      case 'legendary':
        return AchievementRarity.legendary;
      case 'mythic':
        return AchievementRarity.mythic;
      case 'common':
      default:
        return AchievementRarity.common;
    }
  }
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
      'custom' =>
          CustomRequirement(json['description'] as String? ?? json['label'] as String? ?? 'Special challenge'),
      _ => throw ArgumentError('Unknown requirement type: $type'),
    };
  }

  static AchievementRequirement fromCriteria(Map<String, dynamic> criteria) {
    if (criteria.isEmpty) {
      return const CustomRequirement('Complete special challenge.');
    }

    final lessonsCompleted =
        criteria['lessons_completed'] ?? criteria['lessonsCompleted'];
    if (lessonsCompleted is num) {
      return LessonsCountRequirement(lessonsCompleted.toInt());
    }

    final perfectLessons = criteria['perfect_lessons'];
    if (perfectLessons is num) {
      return PerfectQuizzesRequirement(perfectLessons.toInt());
    }

    final streakDays = criteria['streak_days'];
    if (streakDays is num) {
      return StreakDaysRequirement(streakDays.toInt());
    }

    final xpTotal = criteria['xp_total'];
    if (xpTotal is num) {
      return XpTotalRequirement(xpTotal.toInt());
    }

    final wordsLearned = criteria['words_learned'];
    if (wordsLearned is num) {
      return WordsLearnedRequirement(wordsLearned.toInt());
    }

    final languagesCount = criteria['languages_count'];
    if (languagesCount is num) {
      return LanguagesMasteredRequirement(languagesCount.toInt());
    }

    final language = criteria['language'];
    final lessons = criteria['lessons'];
    if (language is String && lessons is num) {
      return CustomRequirement(
        'Complete ${lessons.toInt()} lessons in ${_displayLanguage(language)}.',
      );
    }

    final coins = criteria['coins'];
    if (coins is num) {
      return CustomRequirement('Collect ${coins.toInt()} coins.');
    }

    final special = criteria['special'];
    if (special is String) {
      return CustomRequirement(_describeSpecialRequirement(special));
    }

    return const CustomRequirement('Complete special challenge.');
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

class CustomRequirement extends AchievementRequirement {
  final String description;
  const CustomRequirement(this.description);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'custom',
        'value': 0,
        'description': description,
      };
}

String _displayLanguage(String code) {
  const names = {
    'grc': 'Classical Greek',
    'lat': 'Latin',
    'hbo': 'Biblical Hebrew',
    'egy': 'Middle Egyptian',
    'san': 'Sanskrit',
  };
  return names[code] ?? code.toUpperCase();
}

String _describeSpecialRequirement(String code) {
  switch (code) {
    case 'early_morning':
      return 'Complete a lesson before 7 AM.';
    case 'late_night':
      return 'Complete a lesson after 11 PM.';
    case 'weekend':
      return 'Study during the weekend.';
    case 'holiday':
      return 'Study on a major holiday.';
    default:
      return 'Complete a special challenge.';
  }
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
