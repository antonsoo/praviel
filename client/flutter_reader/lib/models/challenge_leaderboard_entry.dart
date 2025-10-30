/// Leaderboard entry for challenge completion tracking
class ChallengeLeaderboardEntry {
  const ChallengeLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.challengesCompleted,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRewards,
    required this.rank,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final int challengesCompleted;
  final int currentStreak;
  final int longestStreak;
  final int totalRewards;
  final int rank;

  factory ChallengeLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ChallengeLeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      challengesCompleted: json['challengesCompleted'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalRewards: json['totalRewards'] as int? ?? 0,
      rank: json['rank'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'challengesCompleted': challengesCompleted,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalRewards': totalRewards,
      'rank': rank,
    };
  }

  ChallengeLeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    int? challengesCompleted,
    int? currentStreak,
    int? longestStreak,
    int? totalRewards,
    int? rank,
  }) {
    return ChallengeLeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalRewards: totalRewards ?? this.totalRewards,
      rank: rank ?? this.rank,
    );
  }

  /// Create mock data for development/testing
  static List<ChallengeLeaderboardEntry> mockData() {
    return [
      const ChallengeLeaderboardEntry(
        userId: '1',
        username: 'StreakMaster',
        avatarUrl: null,
        challengesCompleted: 45,
        currentStreak: 15,
        longestStreak: 30,
        totalRewards: 4500,
        rank: 1,
      ),
      const ChallengeLeaderboardEntry(
        userId: '2',
        username: 'ChallengeChamp',
        avatarUrl: null,
        challengesCompleted: 38,
        currentStreak: 10,
        longestStreak: 20,
        totalRewards: 3800,
        rank: 2,
      ),
      const ChallengeLeaderboardEntry(
        userId: '3',
        username: 'DailyWarrior',
        avatarUrl: null,
        challengesCompleted: 32,
        currentStreak: 8,
        longestStreak: 15,
        totalRewards: 3200,
        rank: 3,
      ),
    ];
  }
}
