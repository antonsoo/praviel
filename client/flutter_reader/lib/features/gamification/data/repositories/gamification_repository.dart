import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/models/user_progress.dart';

/// Repository interface for gamification data
abstract class GamificationRepository {
  Future<UserProgress> getUserProgress(String userId);
  Future<UserProgress> updateProgress(UserProgress progress);
  Future<List<Achievement>> getAchievements();
  Future<List<Achievement>> getUserAchievements(String userId);
  Future<Achievement> unlockAchievement(String userId, String achievementId);
  Future<List<DailyChallenge>> getDailyChallenges(String userId);
  Future<DailyChallenge> updateChallengeProgress(
    String userId,
    String challengeId,
    int progress,
  );
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    String? languageCode,
    int limit = 100,
  });
}

/// HTTP implementation of gamification repository
class HttpGamificationRepository implements GamificationRepository {
  final http.Client _client;
  final String _baseUrl;
  String? _authToken;

  HttpGamificationRepository({
    required http.Client client,
    required String baseUrl,
    String? authToken,
  })  : _client = client,
        _baseUrl = baseUrl,
        _authToken = authToken;

  /// Set or update the authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get headers with optional authentication
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  @override
  Future<UserProgress> getUserProgress(String userId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/v1/gamification/users/$userId/progress'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return UserProgress.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load user progress: ${response.statusCode}');
    }
  }

  @override
  Future<UserProgress> updateProgress(UserProgress progress) async {
    final response = await _client.put(
      Uri.parse(
          '$_baseUrl/api/v1/gamification/users/${progress.userId}/progress'),
      headers: _getHeaders(),
      body: jsonEncode(progress.toJson()),
    );

    if (response.statusCode == 200) {
      return UserProgress.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to update progress: ${response.statusCode}');
    }
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/v1/gamification/achievements'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load achievements: ${response.statusCode}');
    }
  }

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/v1/gamification/users/$userId/achievements'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load user achievements: ${response.statusCode}');
    }
  }

  @override
  Future<Achievement> unlockAchievement(
    String userId,
    String achievementId,
  ) async {
    final response = await _client.post(
      Uri.parse(
          '$_baseUrl/api/v1/gamification/users/$userId/achievements/$achievementId/unlock'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Achievement.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to unlock achievement: ${response.statusCode}');
    }
  }

  @override
  Future<List<DailyChallenge>> getDailyChallenges(String userId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/v1/gamification/users/$userId/challenges'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((e) => DailyChallenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load daily challenges: ${response.statusCode}');
    }
  }

  @override
  Future<DailyChallenge> updateChallengeProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    final response = await _client.put(
      Uri.parse(
          '$_baseUrl/api/v1/gamification/users/$userId/challenges/$challengeId/progress'),
      headers: _getHeaders(),
      body: jsonEncode({'progress': progress}),
    );

    if (response.statusCode == 200) {
      return DailyChallenge.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
          'Failed to update challenge progress: ${response.statusCode}');
    }
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    String? languageCode,
    int limit = 100,
  }) async {
    final queryParams = {
      'scope': scope.name,
      'period': period.name,
      'limit': limit.toString(),
      if (languageCode != null) 'languageCode': languageCode,
    };

    final response = await _client.get(
      Uri.parse('$_baseUrl/api/v1/gamification/leaderboard')
          .replace(queryParameters: queryParams),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> entries = responseData['entries'] as List;
      return entries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load leaderboard: ${response.statusCode}');
    }
  }
}

/// Mock implementation for development/testing
class MockGamificationRepository implements GamificationRepository {
  @override
  Future<UserProgress> getUserProgress(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return UserProgress(
      userId: userId,
      totalXp: 1250,
      level: 5,
      currentStreak: 7,
      longestStreak: 14,
      lastActivityDate: DateTime.now(),
      lessonsCompleted: 42,
      wordsLearned: 186,
      minutesStudied: 340,
      languageXp: {
        'lat': 800,
        'grc-cls': 450,
      },
      unlockedAchievements: ['first_lesson', 'week_streak', 'vocab_master_50'],
      weeklyActivity: _generateMockWeeklyActivity(),
    );
  }

  @override
  Future<UserProgress> updateProgress(UserProgress progress) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return progress;
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateMockAchievements();
  }

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateMockAchievements()
        .where((a) => a.isUnlocked)
        .toList();
  }

  @override
  Future<Achievement> unlockAchievement(
    String userId,
    String achievementId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final achievements = await getAchievements();
    final achievement = achievements.firstWhere((a) => a.id == achievementId);
    return achievement.copyWith(unlockedAt: DateTime.now());
  }

  @override
  Future<List<DailyChallenge>> getDailyChallenges(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateMockChallenges();
  }

  @override
  Future<DailyChallenge> updateChallengeProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final challenges = await getDailyChallenges(userId);
    final challenge = challenges.firstWhere((c) => c.id == challengeId);
    return challenge.copyWith(
      progress: ChallengeProgress(
        current: progress,
        target: challenge.progress.target,
      ),
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    String? languageCode,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateMockLeaderboard(limit);
  }

  List<DailyActivity> _generateMockWeeklyActivity() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DailyActivity(
        date: date,
        lessonsCompleted: i % 3 == 0 ? 0 : (i % 5) + 2,
        xpEarned: i % 3 == 0 ? 0 : ((i % 5) + 2) * 25,
        minutesStudied: i % 3 == 0 ? 0 : ((i % 5) + 2) * 12,
      );
    });
  }

  List<Achievement> _generateMockAchievements() {
    return [
      Achievement(
        id: 'first_lesson',
        title: 'First Steps',
        description: 'Complete your first lesson',
        iconName: 'school',
        rarity: AchievementRarity.common,
        xpReward: 50,
        requirement: const LessonsCountRequirement(1),
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'week_streak',
        title: 'Consistent Learner',
        description: 'Maintain a 7-day streak',
        iconName: 'local_fire_department',
        rarity: AchievementRarity.uncommon,
        xpReward: 100,
        requirement: const StreakDaysRequirement(7),
        unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Achievement(
        id: 'vocab_master_50',
        title: 'Vocabulary Master',
        description: 'Learn 50 new words',
        iconName: 'library_books',
        rarity: AchievementRarity.rare,
        xpReward: 150,
        requirement: const WordsLearnedRequirement(50),
        unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Achievement(
        id: 'month_streak',
        title: 'Dedicated Scholar',
        description: 'Maintain a 30-day streak',
        iconName: 'emoji_events',
        rarity: AchievementRarity.epic,
        xpReward: 500,
        requirement: const StreakDaysRequirement(30),
      ),
      Achievement(
        id: 'polyglot',
        title: 'Polyglot',
        description: 'Master 3 languages',
        iconName: 'language',
        rarity: AchievementRarity.legendary,
        xpReward: 1000,
        requirement: const LanguagesMasteredRequirement(3),
      ),
      Achievement(
        id: 'ancient_sage',
        title: 'Ancient Sage',
        description: 'Reach 100,000 total XP',
        iconName: 'stars',
        rarity: AchievementRarity.mythic,
        xpReward: 5000,
        requirement: const XpTotalRequirement(100000),
      ),
    ];
  }

  List<DailyChallenge> _generateMockChallenges() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final expiresAt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    return [
      DailyChallenge(
        id: 'daily_lessons_3',
        title: 'Daily Practice',
        description: 'Complete 3 lessons today',
        difficulty: ChallengeDifficulty.beginner,
        type: ChallengeType.reading,
        xpReward: 50,
        coinsReward: 10,
        expiresAt: expiresAt,
        progress: const ChallengeProgress(current: 1, target: 3),
      ),
      DailyChallenge(
        id: 'vocab_review_20',
        title: 'Vocabulary Review',
        description: 'Review 20 vocabulary cards',
        difficulty: ChallengeDifficulty.intermediate,
        type: ChallengeType.vocabulary,
        xpReward: 75,
        coinsReward: 15,
        expiresAt: expiresAt,
        progress: const ChallengeProgress(current: 8, target: 20),
      ),
      DailyChallenge(
        id: 'perfect_quiz',
        title: 'Perfect Score',
        description: 'Get 100% on a comprehension quiz',
        difficulty: ChallengeDifficulty.advanced,
        type: ChallengeType.grammar,
        xpReward: 100,
        coinsReward: 25,
        expiresAt: expiresAt,
        progress: const ChallengeProgress(current: 0, target: 1),
      ),
    ];
  }

  List<LeaderboardEntry> _generateMockLeaderboard(int limit) {
    return List.generate(limit.clamp(1, 100), (i) {
      return LeaderboardEntry(
        userId: 'user_$i',
        username: 'Scholar${i + 1}',
        avatarUrl: 'https://i.pravatar.cc/150?img=${i + 1}',
        rank: i + 1,
        xp: 10000 - (i * 100),
        languageCode: 'lat',
        period: LeaderboardPeriod.weekly,
      );
    });
  }
}
