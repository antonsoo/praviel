/// Model for tracking daily challenge completion streaks
class ChallengeStreak {
  const ChallengeStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletionDate,
    required this.totalDaysCompleted,
    required this.isActiveToday,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime lastCompletionDate;
  final int totalDaysCompleted;
  final bool isActiveToday;

  factory ChallengeStreak.initial() {
    return ChallengeStreak(
      currentStreak: 0,
      longestStreak: 0,
      lastCompletionDate: DateTime.now(),
      totalDaysCompleted: 0,
      isActiveToday: false,
    );
  }

  factory ChallengeStreak.fromJson(Map<String, dynamic> json) {
    return ChallengeStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastCompletionDate: DateTime.parse(
        json['lastCompletionDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      totalDaysCompleted: json['totalDaysCompleted'] as int? ?? 0,
      isActiveToday: json['isActiveToday'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletionDate': lastCompletionDate.toIso8601String(),
      'totalDaysCompleted': totalDaysCompleted,
      'isActiveToday': isActiveToday,
    };
  }

  ChallengeStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletionDate,
    int? totalDaysCompleted,
    bool? isActiveToday,
  }) {
    return ChallengeStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      totalDaysCompleted: totalDaysCompleted ?? this.totalDaysCompleted,
      isActiveToday: isActiveToday ?? this.isActiveToday,
    );
  }

  /// Check if streak is active (completed today or yesterday)
  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastCompletionDate.year,
      lastCompletionDate.month,
      lastCompletionDate.day,
    );

    final diff = today.difference(lastDay).inDays;
    return diff <= 1;
  }

  /// Get milestone level (for rewards)
  int get milestoneLevel {
    if (currentStreak >= 100) return 5; // Legendary
    if (currentStreak >= 50) return 4;  // Epic
    if (currentStreak >= 30) return 3;  // Master
    if (currentStreak >= 14) return 2;  // Pro
    if (currentStreak >= 7) return 1;   // Beginner
    return 0;
  }

  /// Get streak title
  String get title {
    switch (milestoneLevel) {
      case 5: return 'Legendary Streak';
      case 4: return 'Epic Streak';
      case 3: return 'Master Streak';
      case 2: return 'Pro Streak';
      case 1: return 'Week Warrior';
      default: return 'Challenge Streak';
    }
  }

  /// Get streak emoji
  String get emoji {
    switch (milestoneLevel) {
      case 5: return '👑';
      case 4: return '🏆';
      case 3: return '⭐';
      case 2: return '💪';
      case 1: return '🔥';
      default: return '✨';
    }
  }
}
