import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// API client for daily and weekly challenges with offline caching
class ChallengesApi {
  ChallengesApi({required this.baseUrl});

  final String baseUrl;
  final http.Client _client = http.Client();

  String? _authToken;

  // Cache keys
  static const _keyDailyChallenges = 'cache_daily_challenges';
  static const _keyWeeklyChallenges = 'cache_weekly_challenges';
  static const _keyStreak = 'cache_streak';
  static const _keyDailyTimestamp = 'cache_daily_timestamp';
  static const _keyWeeklyTimestamp = 'cache_weekly_timestamp';
  static const _keyStreakTimestamp = 'cache_streak_timestamp';

  // Cache expiry (5 minutes for challenges, 1 minute for streak)
  static const _challengesCacheExpiry = Duration(minutes: 5);
  static const _streakCacheExpiry = Duration(minutes: 1);

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Daily Challenges

  Future<List<DailyChallengeApiResponse>> getDailyChallenges() async {
    // Try cache first
    final cached = await _getCachedDailyChallenges();
    if (cached != null) {
      return cached;
    }

    try {
      final uri = Uri.parse('$baseUrl/api/v1/challenges/daily');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        final challenges = list
            .map((json) =>
                DailyChallengeApiResponse.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache the result
        await _cacheDailyChallenges(challenges);

        return challenges;
      } else {
        throw Exception('Failed to load daily challenges: ${response.body}');
      }
    } catch (e) {
      // On network error, try to return cached data even if expired
      final expiredCache = await _getCachedDailyChallenges(ignoreExpiry: true);
      if (expiredCache != null) {
        debugPrint('[ChallengesApi] Using expired cache due to network error');
        return expiredCache;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChallengeProgress({
    required int challengeId,
    required int increment,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/update-progress');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'challenge_id': challengeId,
        'increment': increment,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update progress: ${response.body}');
    }
  }

  Future<ChallengeStreakApiResponse> getStreak() async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/streak');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChallengeStreakApiResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load streak: ${response.body}');
    }
  }

  // Weekly Challenges

  Future<List<WeeklyChallengeApiResponse>> getWeeklyChallenges() async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/weekly');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map((json) =>
              WeeklyChallengeApiResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load weekly challenges: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateWeeklyChallengeProgress({
    required int challengeId,
    required int increment,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/weekly/update-progress');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'challenge_id': challengeId,
        'increment': increment,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update weekly progress: ${response.body}');
    }
  }

  // User Progress

  Future<UserProgressApiResponse> getUserProgress() async {
    final uri = Uri.parse('$baseUrl/api/v1/progress/me');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return UserProgressApiResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load user progress: ${response.body}');
    }
  }

  // Streak Freeze

  Future<Map<String, dynamic>> purchaseStreakFreeze() async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/purchase-streak-freeze');
    final response = await _client.post(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to purchase streak freeze: ${response.body}');
    }
  }

  // Double or Nothing

  Future<Map<String, dynamic>> startDoubleOrNothing({
    required int wager,
    int days = 7,
  }) async {
    final uri =
        Uri.parse('$baseUrl/api/v1/challenges/double-or-nothing/start');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'wager': wager,
        'days': days,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to start double or nothing: ${response.body}');
    }
  }

  Future<DoubleOrNothingStatusResponse> getDoubleOrNothingStatus() async {
    final uri =
        Uri.parse('$baseUrl/api/v1/challenges/double-or-nothing/status');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return DoubleOrNothingStatusResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
          'Failed to get double or nothing status: ${response.body}');
    }
  }

  // Challenge Leaderboard

  Future<ChallengeLeaderboardResponse> getChallengeLeaderboard({
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/leaderboard?limit=$limit');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChallengeLeaderboardResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load challenge leaderboard: ${response.body}');
    }
  }

  void close() {
    _client.close();
  }

  // Cache helper methods

  Future<List<DailyChallengeApiResponse>?> _getCachedDailyChallenges({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_keyDailyChallenges);
      final cachedTimestamp = prefs.getInt(_keyDailyTimestamp);

      if (cachedJson == null || cachedTimestamp == null) {
        return null;
      }

      // Check if cache is expired
      if (!ignoreExpiry) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        if (cacheAge > _challengesCacheExpiry.inMilliseconds) {
          return null;
        }
      }

      final list = jsonDecode(cachedJson) as List;
      return list
          .map((json) => DailyChallengeApiResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ChallengesApi] Error reading cache: $e');
      return null;
    }
  }

  Future<void> _cacheDailyChallenges(List<DailyChallengeApiResponse> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = challenges.map((c) => {
        'id': c.id,
        'challenge_type': c.challengeType,
        'difficulty': c.difficulty,
        'title': c.title,
        'description': c.description,
        'target_value': c.targetValue,
        'current_progress': c.currentProgress,
        'coin_reward': c.coinReward,
        'xp_reward': c.xpReward,
        'is_completed': c.isCompleted,
        'is_weekend_bonus': c.isWeekendBonus,
        'expires_at': c.expiresAt.toIso8601String(),
        'completed_at': c.completedAt?.toIso8601String(),
      }).toList();

      await prefs.setString(_keyDailyChallenges, jsonEncode(jsonList));
      await prefs.setInt(_keyDailyTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[ChallengesApi] Error writing cache: $e');
    }
  }
}

// Response Models

class DailyChallengeApiResponse {
  DailyChallengeApiResponse({
    required this.id,
    required this.challengeType,
    required this.difficulty,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentProgress,
    required this.coinReward,
    required this.xpReward,
    required this.isCompleted,
    required this.isWeekendBonus,
    required this.expiresAt,
    this.completedAt,
  });

  factory DailyChallengeApiResponse.fromJson(Map<String, dynamic> json) {
    return DailyChallengeApiResponse(
      id: json['id'] as int,
      challengeType: json['challenge_type'] as String,
      difficulty: json['difficulty'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: json['target_value'] as int,
      currentProgress: json['current_progress'] as int,
      coinReward: json['coin_reward'] as int,
      xpReward: json['xp_reward'] as int,
      isCompleted: json['is_completed'] as bool,
      isWeekendBonus: json['is_weekend_bonus'] as bool,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  final int id;
  final String challengeType;
  final String difficulty;
  final String title;
  final String description;
  final int targetValue;
  final int currentProgress;
  final int coinReward;
  final int xpReward;
  final bool isCompleted;
  final bool isWeekendBonus;
  final DateTime expiresAt;
  final DateTime? completedAt;

  double get progressPercentage =>
      (currentProgress / targetValue).clamp(0.0, 1.0);
}

class WeeklyChallengeApiResponse {
  WeeklyChallengeApiResponse({
    required this.id,
    required this.challengeType,
    required this.difficulty,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentProgress,
    required this.coinReward,
    required this.xpReward,
    required this.isCompleted,
    required this.expiresAt,
    required this.weekStart,
    required this.rewardMultiplier,
    required this.isSpecialEvent,
    required this.daysRemaining,
    this.completedAt,
  });

  factory WeeklyChallengeApiResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyChallengeApiResponse(
      id: json['id'] as int,
      challengeType: json['challenge_type'] as String,
      difficulty: json['difficulty'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: json['target_value'] as int,
      currentProgress: json['current_progress'] as int,
      coinReward: json['coin_reward'] as int,
      xpReward: json['xp_reward'] as int,
      isCompleted: json['is_completed'] as bool,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      weekStart: DateTime.parse(json['week_start'] as String),
      rewardMultiplier: (json['reward_multiplier'] as num).toDouble(),
      isSpecialEvent: json['is_special_event'] as bool,
      daysRemaining: json['days_remaining'] as int,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  final int id;
  final String challengeType;
  final String difficulty;
  final String title;
  final String description;
  final int targetValue;
  final int currentProgress;
  final int coinReward;
  final int xpReward;
  final bool isCompleted;
  final DateTime expiresAt;
  final DateTime weekStart;
  final double rewardMultiplier;
  final bool isSpecialEvent;
  final int daysRemaining;
  final DateTime? completedAt;

  double get progressPercentage =>
      (currentProgress / targetValue).clamp(0.0, 1.0);
}

class ChallengeStreakApiResponse {
  ChallengeStreakApiResponse({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDaysCompleted,
    required this.lastCompletionDate,
    required this.isActiveToday,
  });

  factory ChallengeStreakApiResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeStreakApiResponse(
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      totalDaysCompleted: json['total_days_completed'] as int,
      lastCompletionDate:
          DateTime.parse(json['last_completion_date'] as String),
      isActiveToday: json['is_active_today'] as bool,
    );
  }

  final int currentStreak;
  final int longestStreak;
  final int totalDaysCompleted;
  final DateTime lastCompletionDate;
  final bool isActiveToday;
}

class DoubleOrNothingStatusResponse {
  DoubleOrNothingStatusResponse({
    required this.hasActiveChallenge,
    this.wagerAmount,
    this.daysRequired,
    this.daysCompleted,
    this.potentialReward,
  });

  factory DoubleOrNothingStatusResponse.fromJson(Map<String, dynamic> json) {
    return DoubleOrNothingStatusResponse(
      hasActiveChallenge: json['has_active_challenge'] as bool,
      wagerAmount: json['wager_amount'] as int?,
      daysRequired: json['days_required'] as int?,
      daysCompleted: json['days_completed'] as int?,
      potentialReward: json['potential_reward'] as int?,
    );
  }

  final bool hasActiveChallenge;
  final int? wagerAmount;
  final int? daysRequired;
  final int? daysCompleted;
  final int? potentialReward;

  double? get progressPercentage {
    if (daysRequired == null || daysCompleted == null) return null;
    return (daysCompleted! / daysRequired!).clamp(0.0, 1.0);
  }
}

class UserProgressApiResponse {
  UserProgressApiResponse({
    required this.coins,
    required this.streakFreezes,
  });

  factory UserProgressApiResponse.fromJson(Map<String, dynamic> json) {
    return UserProgressApiResponse(
      coins: json['coins'] as int? ?? 0,
      streakFreezes: json['streak_freezes'] as int? ?? 0,
    );
  }

  final int coins;
  final int streakFreezes;
}

class ChallengeLeaderboardEntry {
  ChallengeLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.challengesCompleted,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRewards,
    required this.rank,
  });

  factory ChallengeLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ChallengeLeaderboardEntry(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      challengesCompleted: json['challenges_completed'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      totalRewards: json['total_rewards'] as int,
      rank: json['rank'] as int,
    );
  }

  final int userId;
  final String username;
  final int challengesCompleted;
  final int currentStreak;
  final int longestStreak;
  final int totalRewards;
  final int rank;
}

class ChallengeLeaderboardResponse {
  ChallengeLeaderboardResponse({
    required this.entries,
    required this.userRank,
    required this.totalUsers,
  });

  factory ChallengeLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] as List;
    return ChallengeLeaderboardResponse(
      entries: entriesList
          .map((e) => ChallengeLeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      userRank: json['user_rank'] as int,
      totalUsers: json['total_users'] as int,
    );
  }

  final List<ChallengeLeaderboardEntry> entries;
  final int userRank;
  final int totalUsers;
}
