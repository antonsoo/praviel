import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// API client for Quests (long-term progression goals)
class QuestsApi {
  QuestsApi({required this.baseUrl});

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

  /// Create a new quest
  Future<Quest> createQuest({
    required String questType,
    required int targetValue,
    int durationDays = 30,
    String? title,
    String? description,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'quest_type': questType,
          'target_value': targetValue,
          'duration_days': durationDays,
          if (title != null) 'title': title,
          if (description != null) 'description': description,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return Quest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create quest: ${response.body}');
      }
    });
  }

  /// List quests
  Future<List<Quest>> listQuests({bool includeCompleted = false}) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/').replace(
        queryParameters: {
          'include_completed': includeCompleted.toString(),
        },
      );
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((json) => Quest.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load quests: ${response.body}');
      }
    });
  }

  /// Get only active quests (new endpoint)
  Future<List<Quest>> getActiveQuests() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/active');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((json) => Quest.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load active quests: ${response.body}');
      }
    });
  }

  /// Get only completed quests (new endpoint)
  Future<List<Quest>> getCompletedQuests() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/completed');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((json) => Quest.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load completed quests: ${response.body}');
      }
    });
  }

  /// Get a specific quest
  Future<Quest> getQuest(int questId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return Quest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load quest: ${response.body}');
      }
    });
  }

  /// Update quest progress
  Future<Quest> updateQuestProgress(int questId, int increment) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
      final response = await _client.put(
        uri,
        headers: _headers,
        body: jsonEncode({
          'increment': increment,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return Quest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update progress: ${response.body}');
      }
    });
  }

  /// Complete a quest and claim rewards
  Future<QuestCompletionResponse> completeQuest(int questId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId/complete');
      final response = await _client.post(uri, headers: _headers).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return QuestCompletionResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to complete quest: ${response.body}');
      }
    });
  }

  /// Abandon a quest
  Future<void> abandonQuest(int questId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
      final response = await _client.delete(uri, headers: _headers).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to abandon quest: ${response.body}');
      }
    });
  }

  void dispose() {
    _client.close();
  }
}

/// Quest model matching backend QuestResponse schema
class Quest {
  Quest({
    required this.id,
    required this.questType,
    required this.questId,
    required this.title,
    this.description,
    required this.progressCurrent,
    required this.progressTarget,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.completedAt,
    required this.xpReward,
    this.achievementReward,
    required this.progressPercentage,
  });

  final int id;
  final String questType;
  final String questId;
  final String title;
  final String? description;
  final int progressCurrent;
  final int progressTarget;
  final String status; // "active", "completed", "failed", "expired"
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final int xpReward;
  final String? achievementReward;
  final double progressPercentage;

  // Backward compatibility getters
  int get targetValue => progressTarget;
  int get currentProgress => progressCurrent;
  int get coinReward => 0; // No longer supported by backend

  /// Days remaining until expiration
  int get daysRemaining {
    if (expiresAt == null) return 999;
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);
    return difference.inDays.clamp(0, 9999);
  }

  /// Is this quest completed?
  bool get isCompleted => status == 'completed';

  /// Is this quest failed?
  bool get isFailed => status == 'failed';

  /// Is this quest active (not completed, not failed, not expired)?
  bool get isActive =>
      status == 'active' &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as int,
      questType: json['quest_type'] as String,
      questId: json['quest_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      progressCurrent: json['progress_current'] as int,
      progressTarget: json['progress_target'] as int,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      xpReward: json['xp_reward'] as int,
      achievementReward: json['achievement_reward'] as String?,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
    );
  }
}

/// Response after completing a quest
class QuestCompletionResponse {
  QuestCompletionResponse({
    required this.message,
    required this.rewardsGranted,
    required this.xpEarned,
    required this.coinsEarned,
    required this.totalXp,
    required this.totalCoins,
  });

  final String message;
  final bool rewardsGranted;
  final int xpEarned;
  final int coinsEarned;
  final int totalXp;
  final int totalCoins;

  factory QuestCompletionResponse.fromJson(Map<String, dynamic> json) {
    return QuestCompletionResponse(
      message: json['message'] as String,
      rewardsGranted: json['rewards_granted'] as bool,
      xpEarned: json['xp_earned'] as int,
      coinsEarned: json['coins_earned'] as int,
      totalXp: json['total_xp'] as int,
      totalCoins: json['total_coins'] as int,
    );
  }
}

/// Quest type constants
class QuestType {
  static const String dailyStreak = 'daily_streak';
  static const String xpMilestone = 'xp_milestone';
  static const String lessonCount = 'lesson_count';
  static const String skillMastery = 'skill_mastery';
}
