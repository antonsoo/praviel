import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class QuestsApiException implements Exception {
  const QuestsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// API client for Quests (long-term progression goals)
class QuestsApi {
  QuestsApi({required this.baseUrl, http.Client? client})
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
        // Don't retry on API errors (4xx/5xx) - only transient network errors
        if (e is QuestsApiException) {
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
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'quest_type': questType,
              'target_value': targetValue,
              'duration_days': durationDays,
              if (title != null) 'title': title,
              if (description != null) 'description': description,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return Quest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw QuestsApiException(
          'Failed to create quest: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Preview quest rewards without creating it
  Future<QuestPreview> previewQuest({
    required String questType,
    required int targetValue,
    required int durationDays,
    String? title,
    String? description,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/preview');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'quest_type': questType,
              'target_value': targetValue,
              'duration_days': durationDays,
              if (title != null && title.isNotEmpty) 'title': title,
              if (description != null && description.isNotEmpty)
                'description': description,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return QuestPreview.fromJson(json);
      } else {
        throw QuestsApiException(
          'Failed to preview quest: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Fetch quest templates to guide user selection
  Future<List<QuestTemplate>> fetchQuestTemplates() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/available');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => QuestTemplate.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw QuestsApiException(
          'Failed to load quest templates: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// List quests
  Future<List<Quest>> listQuests({bool includeCompleted = false}) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/').replace(
        queryParameters: {'include_completed': includeCompleted.toString()},
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => Quest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw QuestsApiException(
          'Failed to load quests: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Get only active quests (new endpoint)
  Future<List<Quest>> getActiveQuests() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/active');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => Quest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw QuestsApiException(
          'Failed to load active quests: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Get only completed quests (new endpoint)
  Future<List<Quest>> getCompletedQuests() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/completed');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => Quest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw QuestsApiException(
          'Failed to load completed quests: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Get a specific quest
  Future<Quest> getQuest(int questId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return Quest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw QuestsApiException(
          'Failed to load quest: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Update quest progress
  Future<Quest> updateQuestProgress(int questId, int increment) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: jsonEncode({'increment': increment}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return Quest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw QuestsApiException(
          'Failed to update progress: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Complete a quest and claim rewards
  Future<QuestCompletionResponse> completeQuest(int questId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId/complete');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return QuestCompletionResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw QuestsApiException(
          'Failed to complete quest: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Abandon a quest
  Future<void> abandonQuest(int questId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw QuestsApiException(
          'Failed to abandon quest: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Quest template metadata from backend
class QuestTemplate {
  QuestTemplate({
    required this.questType,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.coinReward,
    required this.targetValue,
    required this.durationDays,
    required this.difficultyTier,
    this.achievementReward,
    this.suggestions,
  });

  final String questType;
  final String title;
  final String description;
  final int xpReward;
  final int coinReward;
  final int targetValue;
  final int durationDays;
  final String difficultyTier;
  final String? achievementReward;
  final Map<String, dynamic>? suggestions;

  factory QuestTemplate.fromJson(Map<String, dynamic> json) {
    return QuestTemplate(
      questType: json['quest_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: (json['xp_reward'] as num).toInt(),
      coinReward: (json['coin_reward'] as num).toInt(),
      targetValue: (json['target_value'] as num).toInt(),
      durationDays: (json['duration_days'] as num).toInt(),
      difficultyTier: json['difficulty_tier'] as String,
      achievementReward: json['achievement_reward'] as String?,
      suggestions: (json['suggestions'] as Map<String, dynamic>?),
    );
  }
}

/// Quest preview response
class QuestPreview {
  QuestPreview({
    required this.questType,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.durationDays,
    required this.xpReward,
    required this.coinReward,
    required this.difficultyTier,
    this.achievementReward,
    required this.meta,
  });

  final String questType;
  final String title;
  final String description;
  final int targetValue;
  final int durationDays;
  final int xpReward;
  final int coinReward;
  final String difficultyTier;
  final String? achievementReward;
  final Map<String, dynamic> meta;

  factory QuestPreview.fromJson(Map<String, dynamic> json) {
    return QuestPreview(
      questType: json['quest_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: (json['target_value'] as num).toInt(),
      durationDays: (json['duration_days'] as num).toInt(),
      xpReward: (json['xp_reward'] as num).toInt(),
      coinReward: (json['coin_reward'] as num).toInt(),
      difficultyTier: json['difficulty_tier'] as String,
      achievementReward: json['achievement_reward'] as String?,
      meta: (json['meta'] as Map<String, dynamic>?) ?? const {},
    );
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
    required this.isCompletedFlag,
    required this.isFailedFlag,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.completedAt,
    required this.xpReward,
    required this.coinReward,
    this.achievementReward,
    required this.progressPercentage,
    this.difficultyTier,
  });

  final int id;
  final String questType;
  final String questId;
  final String title;
  final String? description;
  final int progressCurrent;
  final int progressTarget;
  final bool isCompletedFlag;
  final bool isFailedFlag;
  final String status; // "active", "completed", "failed", "expired"
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final int xpReward;
  final int coinReward;
  final String? achievementReward;
  final double progressPercentage;
  final String? difficultyTier;

  // Backward compatibility getters
  int get targetValue => progressTarget;
  int get currentProgress => progressCurrent;

  /// Days remaining until expiration
  int get daysRemaining {
    if (expiresAt == null) return 999;
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);
    return difference.inDays.clamp(0, 9999);
  }

  /// Is this quest completed?
  bool get isCompleted => isCompletedFlag;

  /// Is this quest failed?
  bool get isFailed =>
      isFailedFlag || status == 'failed' || status == 'expired';

  /// Is this quest active (not completed, not failed, not expired)?
  bool get isActive =>
      !isCompleted &&
      !isFailed &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory Quest.fromJson(Map<String, dynamic> json) {
    final rawProgress =
        json['current_progress'] ?? json['progress_current'] ?? 0;
    final rawTarget = json['target_value'] ?? json['progress_target'] ?? 1;
    final status = json['status'] as String? ?? 'active';
    return Quest(
      id: json['id'] as int,
      questType: json['quest_type'] as String,
      questId: json['quest_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      progressCurrent: (rawProgress as num).toInt(),
      progressTarget: (rawTarget as num).toInt(),
      isCompletedFlag: json['is_completed'] as bool? ?? status == 'completed',
      isFailedFlag: json['is_failed'] as bool? ?? status == 'failed',
      status: status,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      xpReward: json['xp_reward'] as int,
      coinReward: (json['coin_reward'] as num?)?.toInt() ?? 0,
      achievementReward: json['achievement_reward'] as String?,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      difficultyTier: json['difficulty_tier'] as String?,
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
    this.achievementEarned,
  });

  final String message;
  final bool rewardsGranted;
  final int xpEarned;
  final int coinsEarned;
  final int totalXp;
  final int totalCoins;
  final String? achievementEarned;

  factory QuestCompletionResponse.fromJson(Map<String, dynamic> json) {
    return QuestCompletionResponse(
      message: json['message'] as String,
      rewardsGranted: json['rewards_granted'] as bool,
      xpEarned: json['xp_earned'] as int,
      coinsEarned: json['coins_earned'] as int,
      totalXp: json['total_xp'] as int,
      totalCoins: json['total_coins'] as int,
      achievementEarned: json['achievement_earned'] as String?,
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
