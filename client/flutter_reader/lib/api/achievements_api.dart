import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

/// API client for achievements
class AchievementsApi {
  AchievementsApi({required this.baseUrl, http.Client? client})
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
            (e.toString().contains('40') ||
                e.toString().contains('41') ||
                e.toString().contains('42') ||
                e.toString().contains('43'))) {
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

  /// Get user's unlocked achievements
  Future<List<Achievement>> getUserAchievements() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/progress/me/achievements');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
        return json
            .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
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

  /// Extract error message from response body
  String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return json['detail'] as String? ??
            json['message'] as String? ??
            (json['error'] is Map ? json['error']['message'] as String? : null);
      }
    } catch (_) {
      // If JSON parsing fails, return null
    }
    return null;
  }

  void close() {
    _client.close();
  }
}

/// Achievement model
class Achievement {
  final int id;
  final int userId;
  final String achievementType; // badge, milestone, collection
  final String achievementId;
  final Map<String, dynamic>
  meta; // Contains title, description, icon, tier, etc.
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.achievementType,
    required this.achievementId,
    required this.meta,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      achievementType: json['achievement_type'] as String,
      achievementId: json['achievement_id'] as String,
      meta: json['meta'] as Map<String, dynamic>? ?? {},
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }

  // Convenience getters from meta
  String get title => meta['title'] as String? ?? achievementId;
  String get description => meta['description'] as String? ?? '';
  String get icon => meta['icon'] as String? ?? '🏆';
  int get tier => meta['tier'] as int? ?? 1;
  int get xpReward => meta['xp_reward'] as int? ?? 0;
  int get coinReward => meta['coin_reward'] as int? ?? 0;
}
