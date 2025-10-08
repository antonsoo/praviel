import 'package:flutter/material.dart';

/// Type of daily challenge
enum DailyChallengeType {
  lessonsCompleted,     // Complete X lessons
  xpEarned,            // Earn X XP
  perfectScore,        // Get perfect score on X lessons
  streakMaintain,      // Maintain your streak
  wordsLearned,        // Learn X new words
  timeSpent,           // Spend X minutes learning
  comboAchieved,       // Achieve X combo
}

/// Difficulty level affects rewards
enum ChallengeDifficulty {
  easy,    // 50 coins
  medium,  // 100 coins
  hard,    // 200 coins
  expert,  // 500 coins
}

/// Daily challenge model
class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentProgress,
    required this.coinReward,
    required this.xpReward,
    required this.expiresAt,
    this.isCompleted = false,
    this.completedAt,
    this.isWeekendBonus = false,
  });

  final String id;
  final DailyChallengeType type;
  final ChallengeDifficulty difficulty;
  final String title;
  final String description;
  final int targetValue;
  final int currentProgress;
  final int coinReward;
  final int xpReward;
  final DateTime expiresAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isWeekendBonus;

  double get progressPercentage =>
      (currentProgress / targetValue).clamp(0.0, 1.0);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  String get timeRemainingText {
    final duration = timeRemaining;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  IconData get icon {
    switch (type) {
      case DailyChallengeType.lessonsCompleted:
        return Icons.book_rounded;
      case DailyChallengeType.xpEarned:
        return Icons.star_rounded;
      case DailyChallengeType.perfectScore:
        return Icons.verified_rounded;
      case DailyChallengeType.streakMaintain:
        return Icons.local_fire_department_rounded;
      case DailyChallengeType.wordsLearned:
        return Icons.translate_rounded;
      case DailyChallengeType.timeSpent:
        return Icons.timer_rounded;
      case DailyChallengeType.comboAchieved:
        return Icons.flash_on_rounded;
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFF10B981); // Green
      case ChallengeDifficulty.medium:
        return const Color(0xFF3B82F6); // Blue
      case ChallengeDifficulty.hard:
        return const Color(0xFF9333EA); // Purple
      case ChallengeDifficulty.expert:
        return const Color(0xFFFFD700); // Gold
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.expert:
        return 'Expert';
    }
  }

  DailyChallenge copyWith({
    String? id,
    DailyChallengeType? type,
    ChallengeDifficulty? difficulty,
    String? title,
    String? description,
    int? targetValue,
    int? currentProgress,
    int? coinReward,
    int? xpReward,
    DateTime? expiresAt,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isWeekendBonus,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      coinReward: coinReward ?? this.coinReward,
      xpReward: xpReward ?? this.xpReward,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isWeekendBonus: isWeekendBonus ?? this.isWeekendBonus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'difficulty': difficulty.name,
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'coinReward': coinReward,
      'xpReward': xpReward,
      'expiresAt': expiresAt.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'isWeekendBonus': isWeekendBonus,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      type: DailyChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: json['targetValue'] as int,
      currentProgress: json['currentProgress'] as int,
      coinReward: json['coinReward'] as int,
      xpReward: json['xpReward'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isWeekendBonus: json['isWeekendBonus'] as bool? ?? false,
    );
  }

  /// Generate daily challenges based on user level
  static List<DailyChallenge> generateDaily(int userLevel) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

    // Check if it's weekend (Saturday or Sunday)
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final rewardMultiplier = isWeekend ? 2.0 : 1.0;

    final challenges = <DailyChallenge>[];

    // Easy challenge - always include
    challenges.add(DailyChallenge(
      id: 'daily_easy_${now.day}',
      type: DailyChallengeType.lessonsCompleted,
      difficulty: ChallengeDifficulty.easy,
      title: isWeekend ? '🎉 Weekend Quick Learner' : 'Quick Learner',
      description: 'Complete 2 lessons today',
      targetValue: 2,
      currentProgress: 0,
      coinReward: (50 * rewardMultiplier).round(),
      xpReward: (25 * rewardMultiplier).round(),
      expiresAt: tomorrow,
      isWeekendBonus: isWeekend,
    ));

    // Medium challenge
    challenges.add(DailyChallenge(
      id: 'daily_medium_${now.day}',
      type: DailyChallengeType.xpEarned,
      difficulty: ChallengeDifficulty.medium,
      title: isWeekend ? '🎉 Weekend XP Hunter' : 'XP Hunter',
      description: 'Earn ${userLevel * 50} XP today',
      targetValue: userLevel * 50,
      currentProgress: 0,
      coinReward: (100 * rewardMultiplier).round(),
      xpReward: (50 * rewardMultiplier).round(),
      expiresAt: tomorrow,
      isWeekendBonus: isWeekend,
    ));

    // Hard challenge - for more advanced users
    if (userLevel >= 3) {
      challenges.add(DailyChallenge(
        id: 'daily_hard_${now.day}',
        type: DailyChallengeType.perfectScore,
        difficulty: ChallengeDifficulty.hard,
        title: isWeekend ? '🎉 Weekend Perfectionist' : 'Perfectionist',
        description: 'Get perfect score on 3 lessons',
        targetValue: 3,
        currentProgress: 0,
        coinReward: (200 * rewardMultiplier).round(),
        xpReward: (100 * rewardMultiplier).round(),
        expiresAt: tomorrow,
        isWeekendBonus: isWeekend,
      ));
    }

    // Streak challenge
    challenges.add(DailyChallenge(
      id: 'daily_streak_${now.day}',
      type: DailyChallengeType.streakMaintain,
      difficulty: ChallengeDifficulty.medium,
      title: isWeekend ? '🎉 Weekend Streak Keeper' : 'Streak Keeper',
      description: 'Maintain your streak today',
      targetValue: 1,
      currentProgress: 0,
      coinReward: (75 * rewardMultiplier).round(),
      xpReward: (30 * rewardMultiplier).round(),
      expiresAt: tomorrow,
      isWeekendBonus: isWeekend,
    ));

    return challenges;
  }
}
