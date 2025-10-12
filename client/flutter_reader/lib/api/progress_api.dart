import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// API client for user progress tracking
class ProgressApi {
  ProgressApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Retry helper for transient network errors with exponential backoff
  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (e) {
        // Don't retry on HTTP 4xx errors (client errors)
        if (e.toString().contains('Failed to') &&
            (e.toString().contains('40') || e.toString().contains('41') ||
             e.toString().contains('42') || e.toString().contains('43'))) {
          rethrow;
        }

        // Last attempt - rethrow the error
        if (attempt == maxRetries - 1) {
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 4s
        final delaySeconds = pow(2, attempt).toInt();
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Get current user progress
  Future<UserProgressResponse> getUserProgress() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me');
      final response = await _client.get(uri, headers: _headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        return UserProgressResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to load user progress: ${response.body}');
      }
    });
  }

  /// Update user progress after completing a lesson or activity
  Future<UserProgressResponse> updateProgress({
    required int xpGained,
    String? lessonId,
    int? timeSpentMinutes,
    bool? isPerfect,
    int? wordsLearnedCount,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/update');
      final body = {
        'xp_gained': xpGained,
        if (lessonId != null) 'lesson_id': lessonId,
        if (timeSpentMinutes != null) 'time_spent_minutes': timeSpentMinutes,
        if (isPerfect != null) 'is_perfect': isPerfect,
        if (wordsLearnedCount != null) 'words_learned_count': wordsLearnedCount,
      };

      debugPrint('[ProgressApi] Updating progress: $body');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('[ProgressApi] Progress updated successfully');
        return UserProgressResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        debugPrint('[ProgressApi] Failed to update progress: ${response.statusCode} ${response.body}');
        throw Exception('Failed to update progress: ${response.body}');
      }
    });
  }

  /// Get user's skill ratings (ELO per topic) - NEW ENDPOINT
  Future<List<UserSkillResponse>> getUserSkills({String? topicType}) async {
    return _retryRequest(() async {
      final queryParams = <String, String>{
        if (topicType != null) 'topic_type': topicType,
      };
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/skills').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await _client.get(uri, headers: _headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((json) => UserSkillResponse.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load user skills: ${response.body}');
      }
    });
  }

  /// Get user's unlocked achievements - NEW ENDPOINT
  Future<List<UserAchievementResponse>> getUserAchievements() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/achievements');
      final response = await _client.get(uri, headers: _headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((json) => UserAchievementResponse.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load achievements: ${response.body}');
      }
    });
  }

  /// Get user's reading statistics for all works - NEW ENDPOINT
  Future<List<UserTextStatsResponse>> getUserTextStats() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/texts');
      final response = await _client.get(uri, headers: _headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((json) => UserTextStatsResponse.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load text stats: ${response.body}');
      }
    });
  }

  /// Get user's reading statistics for a specific work - NEW ENDPOINT
  Future<UserTextStatsResponse> getUserTextStatsForWork(int workId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/texts/$workId');
      final response = await _client.get(uri, headers: _headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        return UserTextStatsResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to load text stats for work: ${response.body}');
      }
    });
  }

  /// Purchase a streak freeze using coins
  Future<Map<String, dynamic>> purchaseStreakFreeze() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/streak-freeze/buy');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to purchase streak freeze: ${response.body}');
      }
    });
  }

  /// Purchase a 2x XP Boost using coins (150 coins)
  Future<Map<String, dynamic>> purchaseXpBoost() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/xp-boost/buy');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to purchase XP Boost: ${response.body}');
      }
    });
  }

  /// Purchase a Hint Reveal using coins (50 coins)
  Future<Map<String, dynamic>> purchaseHintReveal() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/hint-reveal/buy');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to purchase Hint Reveal: ${response.body}');
      }
    });
  }

  /// Purchase a Time Warp/Skip Question using coins (100 coins)
  Future<Map<String, dynamic>> purchaseTimeWarp() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/time-warp/buy');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to purchase Time Warp: ${response.body}');
      }
    });
  }

  /// Activate a 2x XP Boost for 30 minutes
  Future<Map<String, dynamic>> activateXpBoost() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/xp-boost/activate');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to activate XP Boost: ${response.body}');
      }
    });
  }

  /// Use a hint to reveal answer help
  Future<Map<String, dynamic>> useHint() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/hint/use');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to use hint: ${response.body}');
      }
    });
  }

  /// Use a skip to bypass a difficult question
  Future<Map<String, dynamic>> useSkip() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/skip/use');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to use skip: ${response.body}');
      }
    });
  }

  bool _closed = false;

  void close() {
    if (_closed) {
      return;
    }
    _client.close();
    _closed = true;
  }

  void dispose() => close();
}

/// User skill response model (ELO ratings per topic)
class UserSkillResponse {
  final String topicType;
  final String topicId;
  final double eloRating;
  final double? accuracy;
  final int totalAttempts;
  final int correctAttempts;
  final DateTime? lastPracticedAt;

  UserSkillResponse({
    required this.topicType,
    required this.topicId,
    required this.eloRating,
    this.accuracy,
    required this.totalAttempts,
    required this.correctAttempts,
    this.lastPracticedAt,
  });

  factory UserSkillResponse.fromJson(Map<String, dynamic> json) {
    return UserSkillResponse(
      topicType: json['topic_type'] as String,
      topicId: json['topic_id'] as String,
      eloRating: (json['elo_rating'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      totalAttempts: json['total_attempts'] as int,
      correctAttempts: json['correct_attempts'] as int,
      lastPracticedAt: json['last_practiced_at'] != null
          ? DateTime.parse(json['last_practiced_at'] as String)
          : null,
    );
  }

  double get accuracyRate =>
      totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;
}

/// User achievement response model
class UserAchievementResponse {
  final String achievementType;
  final String achievementId;
  final DateTime unlockedAt;
  final int? progressCurrent;
  final int? progressTarget;

  UserAchievementResponse({
    required this.achievementType,
    required this.achievementId,
    required this.unlockedAt,
    this.progressCurrent,
    this.progressTarget,
  });

  factory UserAchievementResponse.fromJson(Map<String, dynamic> json) {
    return UserAchievementResponse(
      achievementType: json['achievement_type'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      progressCurrent: json['progress_current'] as int?,
      progressTarget: json['progress_target'] as int?,
    );
  }
}

/// User text statistics response model
class UserTextStatsResponse {
  final int workId;
  final double? lemmaCoveragePct;
  final int tokensSeen;
  final int uniqueLemmasKnown;
  final double? avgWpm;
  final double? comprehensionPct;
  final int segmentsCompleted;
  final String? lastSegmentRef;
  final int maxHintlessRun;

  UserTextStatsResponse({
    required this.workId,
    this.lemmaCoveragePct,
    required this.tokensSeen,
    required this.uniqueLemmasKnown,
    this.avgWpm,
    this.comprehensionPct,
    required this.segmentsCompleted,
    this.lastSegmentRef,
    required this.maxHintlessRun,
  });

  factory UserTextStatsResponse.fromJson(Map<String, dynamic> json) {
    return UserTextStatsResponse(
      workId: json['work_id'] as int,
      lemmaCoveragePct: json['lemma_coverage_pct'] != null
          ? (json['lemma_coverage_pct'] as num).toDouble()
          : null,
      tokensSeen: json['tokens_seen'] as int,
      uniqueLemmasKnown: json['unique_lemmas_known'] as int,
      avgWpm: json['avg_wpm'] != null
          ? (json['avg_wpm'] as num).toDouble()
          : null,
      comprehensionPct: json['comprehension_pct'] != null
          ? (json['comprehension_pct'] as num).toDouble()
          : null,
      segmentsCompleted: json['segments_completed'] as int,
      lastSegmentRef: json['last_segment_ref'] as String?,
      maxHintlessRun: json['max_hintless_run'] as int,
    );
  }
}

/// User progress response model
class UserProgressResponse {
  final int xpTotal;
  final int level;
  final int streakDays;
  final int maxStreak;
  final int coins;
  final int streakFreezes;
  final int xpBoost2x;
  final int xpBoost5x;
  final int timeWarp;
  final int coinDoubler;
  final int perfectProtection;
  final int totalLessons;
  final int totalExercises;
  final int totalTimeMinutes;
  final DateTime? lastLessonAt;
  final DateTime? lastStreakUpdate;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final int xpToNextLevel;
  final double progressToNextLevel;

  UserProgressResponse({
    required this.xpTotal,
    required this.level,
    required this.streakDays,
    required this.maxStreak,
    required this.coins,
    required this.streakFreezes,
    this.xpBoost2x = 0,
    this.xpBoost5x = 0,
    this.timeWarp = 0,
    this.coinDoubler = 0,
    this.perfectProtection = 0,
    required this.totalLessons,
    required this.totalExercises,
    required this.totalTimeMinutes,
    this.lastLessonAt,
    this.lastStreakUpdate,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.xpToNextLevel,
    required this.progressToNextLevel,
  });

  factory UserProgressResponse.fromJson(Map<String, dynamic> json) {
    return UserProgressResponse(
      xpTotal: json['xp_total'] as int,
      level: json['level'] as int,
      streakDays: json['streak_days'] as int,
      maxStreak: json['max_streak'] as int,
      coins: json['coins'] as int,
      streakFreezes: json['streak_freezes'] as int,
      xpBoost2x: (json['xp_boost_2x'] as int?) ?? 0,
      xpBoost5x: (json['xp_boost_5x'] as int?) ?? 0,
      timeWarp: (json['time_warp'] as int?) ?? 0,
      coinDoubler: (json['coin_doubler'] as int?) ?? 0,
      perfectProtection: (json['perfect_protection'] as int?) ?? 0,
      totalLessons: json['total_lessons'] as int,
      totalExercises: json['total_exercises'] as int,
      totalTimeMinutes: json['total_time_minutes'] as int,
      lastLessonAt: json['last_lesson_at'] != null
          ? DateTime.parse(json['last_lesson_at'] as String)
          : null,
      lastStreakUpdate: json['last_streak_update'] != null
          ? DateTime.parse(json['last_streak_update'] as String)
          : null,
      xpForCurrentLevel: json['xp_for_current_level'] as int,
      xpForNextLevel: json['xp_for_next_level'] as int,
      xpToNextLevel: json['xp_to_next_level'] as int,
      progressToNextLevel: (json['progress_to_next_level'] as num).toDouble(),
    );
  }
}
