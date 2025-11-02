import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_exception.dart';

/// API client for user progress tracking
class ProgressApi {
  ProgressApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  String? _authToken;

  bool get _hasAuth => _authToken != null && _authToken!.trim().isNotEmpty;

  void setAuthToken(String? token) {
    _authToken = token?.trim();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_hasAuth) 'Authorization': 'Bearer $_authToken',
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
        // Don't retry on API errors (4xx client errors)
        if (e is ApiException && !e.shouldRetry) {
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
    throw ApiException('Max retries exceeded');
  }

  void _ensureAuthenticated({String feature = 'access this feature'}) {
    if (!_hasAuth) {
      throw ApiException('Sign in to ${feature.trim()}.', statusCode: 401);
    }
  }

  /// Get current user progress
  Future<UserProgressResponse> getUserProgress() async {
    if (!_hasAuth) {
      return UserProgressResponse.guest();
    }

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserProgressResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to load user progress';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Get another user's progress (requires appropriate visibility permissions)
  Future<GamificationUserProgress> getUserProgressById(String userId) async {
    _ensureAuthenticated(feature: 'view detailed community progress');

    return _retryRequest<GamificationUserProgress>(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/gamification/users/$userId/progress',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return GamificationUserProgress.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to load user progress';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
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
    _ensureAuthenticated(feature: 'sync your lesson progress');

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/update');
      final body = {
        'xp_gained': xpGained,
        if (lessonId != null) 'lesson_id': lessonId,
        if (timeSpentMinutes != null) 'time_spent_minutes': timeSpentMinutes,
        if (isPerfect != null) 'is_perfect': isPerfect,
        if (wordsLearnedCount != null) 'words_learned_count': wordsLearnedCount,
      };

      debugPrint(
        '[ProgressApi] Updating progress (data redacted for security)',
      );

      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('[ProgressApi] Progress updated successfully');
        return UserProgressResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        debugPrint(
          '[ProgressApi] Failed to update progress: ${response.statusCode} ${response.body}',
        );
        final String message =
            _extractErrorMessage(response.body) ?? 'Failed to update progress';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Get user's skill ratings (ELO per topic) - NEW ENDPOINT
  Future<List<UserSkillResponse>> getUserSkills({String? topicType}) async {
    _ensureAuthenticated(feature: 'view your adaptive skill ratings');

    return _retryRequest(() async {
      final queryParams = <String, String>{
        if (topicType != null) 'topic_type': topicType,
      };
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/skills',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map(
              (json) =>
                  UserSkillResponse.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        final String message =
            _extractErrorMessage(response.body) ?? 'Failed to load user skills';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Update skill rating after exercise completion (uses ELO system)
  Future<UserSkillResponse> updateSkillRating({
    required String topicType,
    required String topicId,
    required bool correct,
  }) async {
    _ensureAuthenticated(feature: 'update your skill ratings');

    return _retryRequest(() async {
      final queryParams = {
        'topic_type': topicType,
        'topic_id': topicId,
        'correct': correct.toString(),
      };
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/skills/update',
      ).replace(queryParameters: queryParams);
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserSkillResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        // Don't fail lesson completion if skill tracking fails
        debugPrint(
          '[ProgressApi] Warning: Failed to update skill rating: ${response.body}',
        );
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to update skill rating';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Get user's unlocked achievements - NEW ENDPOINT
  Future<List<UserAchievementResponse>> getUserAchievements() async {
    _ensureAuthenticated(feature: 'view your unlocked achievements');

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/achievements');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map(
              (json) => UserAchievementResponse.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to load achievements';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Get user's reading statistics for all works - NEW ENDPOINT
  Future<List<UserTextStatsResponse>> getUserTextStats() async {
    _ensureAuthenticated(feature: 'view your reading analytics');

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/texts');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map(
              (json) =>
                  UserTextStatsResponse.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        final String message =
            _extractErrorMessage(response.body) ?? 'Failed to load text stats';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Get user's reading statistics for a specific work - NEW ENDPOINT
  Future<UserTextStatsResponse> getUserTextStatsForWork(int workId) async {
    _ensureAuthenticated(feature: 'view your reading analytics');

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/texts/$workId');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserTextStatsResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to load text stats for work';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Purchase a streak freeze using coins
  Future<Map<String, dynamic>> purchaseStreakFreeze() async {
    _ensureAuthenticated(feature: 'use the power-up shop');

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/streak-freeze/buy');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to purchase streak freeze';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Purchase a 2x XP Boost using coins (150 coins)
  Future<Map<String, dynamic>> purchaseXpBoost() async {
    _ensureAuthenticated(feature: 'use the power-up shop');

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/power-ups/xp-boost/buy',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to purchase XP Boost';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Purchase a Hint Reveal using coins (50 coins)
  Future<Map<String, dynamic>> purchaseHintReveal() async {
    _ensureAuthenticated(feature: 'use the power-up shop');

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/power-ups/hint-reveal/buy',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to purchase Hint Reveal';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Purchase a Time Warp/Skip Question using coins (100 coins)
  Future<Map<String, dynamic>> purchaseTimeWarp() async {
    _ensureAuthenticated(feature: 'use the power-up shop');

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/power-ups/time-warp/buy',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to purchase Time Warp';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Purchase streak repair using coins (200 coins)
  Future<Map<String, dynamic>> purchaseStreakRepair() async {
    _ensureAuthenticated(feature: 'use the power-up shop');

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/shop/streak-repair/buy',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to purchase Streak Repair';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Purchase gold avatar border using coins (500 coins)
  Future<Map<String, dynamic>> purchaseAvatarBorder() async {
    _ensureAuthenticated(feature: 'use the power-up shop');

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/shop/avatar-border/buy',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to purchase Avatar Border';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Purchase premium dark theme using coins (300 coins)
  Future<Map<String, dynamic>> purchasePremiumTheme() async {
    _ensureAuthenticated(feature: 'use the power-up shop');

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/shop/theme-premium/buy',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to purchase Premium Theme';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Activate a 2x XP Boost for 30 minutes
  Future<Map<String, dynamic>> activateXpBoost() async {
    _ensureAuthenticated(feature: 'activate power-ups');

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/progress/me/power-ups/xp-boost/activate',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ??
            'Failed to activate XP Boost';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Use a hint to reveal answer help
  Future<Map<String, dynamic>> useHint() async {
    _ensureAuthenticated(feature: 'use your power-ups');

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/hint/use');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ?? 'Failed to use hint';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Use a skip to bypass a difficult question
  Future<Map<String, dynamic>> useSkip() async {
    _ensureAuthenticated(feature: 'use your power-ups');

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/power-ups/skip/use');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final String message =
            _extractErrorMessage(response.body) ?? 'Failed to use skip';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    });
  }

  /// Extract error message from response body
  String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        // Try various error message fields
        return json['detail'] as String? ??
            json['message'] as String? ??
            (json['error'] is Map ? json['error']['message'] as String? : null);
      }
    } catch (_) {
      // If JSON parsing fails, return null
    }
    return null;
  }

  bool _closed = false;

  void close() {
    if (_closed) {
      return;
    }
    if (_ownsClient) {
      _client.close();
    }
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
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
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
class GamificationDailyActivity {
  final String date;
  final int lessonsCompleted;
  final int xpEarned;
  final int minutesStudied;
  final int wordsLearned;

  GamificationDailyActivity({
    required this.date,
    required this.lessonsCompleted,
    required this.xpEarned,
    required this.minutesStudied,
    required this.wordsLearned,
  });

  factory GamificationDailyActivity.fromJson(Map<String, dynamic> json) {
    return GamificationDailyActivity(
      date: json['date'] as String,
      lessonsCompleted: json['lessons_completed'] as int,
      xpEarned: json['xp_earned'] as int,
      minutesStudied: json['minutes_studied'] as int,
      wordsLearned: json['words_learned'] as int,
    );
  }
}

class GamificationUserProgress {
  final String userId;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final String lastActivityDate;
  final int lessonsCompleted;
  final int wordsLearned;
  final int minutesStudied;
  final Map<String, int> languageXp;
  final List<String> unlockedAchievements;
  final List<GamificationDailyActivity> weeklyActivity;
  final int xpForNextLevel;
  final double progressToNextLevel;

  GamificationUserProgress({
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
    required this.weeklyActivity,
    required this.xpForNextLevel,
    required this.progressToNextLevel,
  });

  int get xpToNextLevel => max(xpForNextLevel - totalXp, 0);

  factory GamificationUserProgress.fromJson(Map<String, dynamic> json) {
    return GamificationUserProgress(
      userId: json['user_id'] as String,
      totalXp: json['total_xp'] as int,
      level: json['level'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      lastActivityDate: json['last_activity_date'] as String,
      lessonsCompleted: json['lessons_completed'] as int,
      wordsLearned: json['words_learned'] as int,
      minutesStudied: json['minutes_studied'] as int,
      languageXp: Map<String, int>.from(json['language_xp'] as Map),
      unlockedAchievements: List<String>.from(
        json['unlocked_achievements'] as List,
      ),
      weeklyActivity: (json['weekly_activity'] as List<dynamic>)
          .map(
            (item) => GamificationDailyActivity.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      xpForNextLevel: json['xp_for_next_level'] as int,
      progressToNextLevel: (json['progress_to_next_level'] as num).toDouble(),
    );
  }
}

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
  final DateTime?
  xpBoostExpiresAt; // CRITICAL: When the active XP boost expires
  final int totalLessons;
  final int totalExercises;
  final int totalTimeMinutes;
  final DateTime? lastLessonAt;
  final DateTime? lastStreakUpdate;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final int xpToNextLevel;
  final double progressToNextLevel;
  final List<UserAchievementResponse>? newlyUnlockedAchievements;

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
    this.xpBoostExpiresAt,
    required this.totalLessons,
    required this.totalExercises,
    required this.totalTimeMinutes,
    this.lastLessonAt,
    this.lastStreakUpdate,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.xpToNextLevel,
    required this.progressToNextLevel,
    this.newlyUnlockedAchievements,
  });

  static UserProgressResponse guest() {
    return UserProgressResponse(
      xpTotal: 0,
      level: 1,
      streakDays: 0,
      maxStreak: 0,
      coins: 0,
      streakFreezes: 0,
      totalLessons: 0,
      totalExercises: 0,
      totalTimeMinutes: 0,
      xpForCurrentLevel: 0,
      xpForNextLevel: 100,
      xpToNextLevel: 100,
      progressToNextLevel: 0.0,
      newlyUnlockedAchievements: const [],
    );
  }

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
      xpBoostExpiresAt: json['xp_boost_expires_at'] != null
          ? DateTime.parse(json['xp_boost_expires_at'] as String)
          : null,
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
      newlyUnlockedAchievements: json['newly_unlocked_achievements'] != null
          ? (json['newly_unlocked_achievements'] as List)
                .map(
                  (a) => UserAchievementResponse.fromJson(
                    a as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }
}
