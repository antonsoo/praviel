import 'dart:convert';
import 'package:http/http.dart' as http;

/// API client for daily and weekly challenges
class ChallengesApi {
  ChallengesApi({required this.baseUrl});

  final String baseUrl;
  final http.Client _client = http.Client();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Daily Challenges

  Future<List<DailyChallengeApiResponse>> getDailyChallenges() async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/daily');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map((json) =>
              DailyChallengeApiResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load daily challenges: ${response.body}');
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
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update progress: ${response.body}');
    }
  }

  Future<ChallengeStreakApiResponse> getStreak() async {
    final uri = Uri.parse('$baseUrl/api/v1/challenges/streak');
    final response = await _client.get(uri, headers: _headers);

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
    final response = await _client.get(uri, headers: _headers);

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
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update weekly progress: ${response.body}');
    }
  }

  // User Progress

  Future<UserProgressApiResponse> getUserProgress() async {
    final uri = Uri.parse('$baseUrl/api/v1/progress/me');
    final response = await _client.get(uri, headers: _headers);

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
    final response = await _client.post(uri, headers: _headers);

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
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to start double or nothing: ${response.body}');
    }
  }

  Future<DoubleOrNothingStatusResponse> getDoubleOrNothingStatus() async {
    final uri =
        Uri.parse('$baseUrl/api/v1/challenges/double-or-nothing/status');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return DoubleOrNothingStatusResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
          'Failed to get double or nothing status: ${response.body}');
    }
  }

  void close() {
    _client.close();
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
