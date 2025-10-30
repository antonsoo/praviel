import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

/// API client for achievements
class AchievementsApi {
  AchievementsApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;
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

  /// Returns the full achievement showcase (locked + unlocked)
  Future<List<Achievement>> getAchievements() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/gamification/achievements');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
        return json
            .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final message =
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

  /// Backwards compatible alias for older callers
  Future<List<Achievement>> getUserAchievements() => getAchievements();

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
    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Achievement showcase model
class Achievement {
  final String id;
  final String achievementType; // badge, milestone, collection
  final String title;
  final String description;
  final String icon; // Emoji or glyph
  final String iconName; // Material icon fallback
  final int tier;
  final String rarityLabel;
  final double? rarityPercent;
  final String category;
  final int xpReward;
  final int coinReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int? progressCurrent;
  final int? progressTarget;
  final Map<String, dynamic> unlockCriteria;

  Achievement({
    required this.id,
    required this.achievementType,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconName,
    required this.tier,
    required this.rarityLabel,
    required this.rarityPercent,
    required this.category,
    required this.xpReward,
    required this.coinReward,
    required this.isUnlocked,
    required this.unlockedAt,
    required this.progressCurrent,
    required this.progressTarget,
    required this.unlockCriteria,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      achievementType:
          json['achievement_type'] as String? ??
          json['achievementType'] as String? ??
          json['type'] as String? ??
          'general',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏅',
      iconName:
          json['icon_name'] as String? ??
          json['iconName'] as String? ??
          'emoji_events',
      tier: json['tier'] as int? ?? 1,
      rarityLabel:
          json['rarity_label'] as String? ??
          json['rarity'] as String? ??
          'common',
      rarityPercent: (json['rarity_percent'] as num?)?.toDouble(),
      category: json['category'] as String? ?? 'general',
      xpReward: json['xp_reward'] as int? ?? json['xpReward'] as int? ?? 0,
      coinReward:
          json['coin_reward'] as int? ?? json['coinReward'] as int? ?? 0,
      isUnlocked:
          json['is_unlocked'] as bool? ?? json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progressCurrent:
          json['progress_current'] as int? ?? json['progressCurrent'] as int?,
      progressTarget:
          json['progress_target'] as int? ?? json['progressTarget'] as int?,
      unlockCriteria: Map<String, dynamic>.from(
        json['unlock_criteria'] as Map? ?? {},
      ),
    );
  }

  double get completionPercent {
    if (progressCurrent == null ||
        progressTarget == null ||
        progressTarget == 0) {
      return isUnlocked ? 1.0 : 0.0;
    }
    return (progressCurrent! / progressTarget!).clamp(0.0, 1.0);
  }

  bool get isInProgress =>
      !isUnlocked && progressCurrent != null && progressCurrent! > 0;

  String get rarityDisplay {
    if (rarityPercent == null) return rarityLabel;
    return '$rarityLabel (${rarityPercent!.toStringAsFixed(1)}%)';
  }
}
