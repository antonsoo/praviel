import 'dart:convert';
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

  /// Get current user progress
  Future<UserProgressResponse> getUserProgress() async {
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
  }

  /// Update user progress after completing a lesson or activity
  Future<UserProgressResponse> updateProgress({
    required int xpGained,
    String? lessonId,
    int? timeSpentMinutes,
    bool? isPerfect,
    int? wordsLearnedCount,
  }) async {
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
  }

  void close() {
    _client.close();
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
