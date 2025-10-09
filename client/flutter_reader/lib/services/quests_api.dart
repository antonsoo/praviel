import 'dart:convert';
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

  /// Create a new quest
  Future<Quest> createQuest({
    required String questType,
    required int targetValue,
    int durationDays = 30,
    String? title,
    String? description,
  }) async {
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
  }

  /// List quests
  Future<List<Quest>> listQuests({bool includeCompleted = false}) async {
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
  }

  /// Get a specific quest
  Future<Quest> getQuest(int questId) async {
    final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return Quest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load quest: ${response.body}');
    }
  }

  /// Update quest progress
  Future<Quest> updateQuestProgress(int questId, int increment) async {
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
  }

  /// Complete a quest and claim rewards
  Future<QuestCompletionResponse> completeQuest(int questId) async {
    final uri = Uri.parse('$baseUrl/api/v1/quests/$questId/complete');
    final response = await _client.post(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return QuestCompletionResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to complete quest: ${response.body}');
    }
  }

  /// Abandon a quest
  Future<void> abandonQuest(int questId) async {
    final uri = Uri.parse('$baseUrl/api/v1/quests/$questId');
    final response = await _client.delete(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to abandon quest: ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Quest model
class Quest {
  Quest({
    required this.id,
    required this.questType,
    required this.targetValue,
    required this.currentProgress,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.coinReward,
    required this.isCompleted,
    required this.isFailed,
    required this.startedAt,
    required this.expiresAt,
    this.completedAt,
    required this.progressPercentage,
  });

  final int id;
  final String questType;
  final int targetValue;
  final int currentProgress;
  final String title;
  final String description;
  final int xpReward;
  final int coinReward;
  final bool isCompleted;
  final bool isFailed;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? completedAt;
  final double progressPercentage;

  /// Days remaining until expiration
  int get daysRemaining {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    return difference.inDays.clamp(0, 9999);
  }

  /// Is this quest active (not completed, not failed, not expired)?
  bool get isActive => !isCompleted && !isFailed && expiresAt.isAfter(DateTime.now());

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as int,
      questType: json['quest_type'] as String,
      targetValue: json['target_value'] as int,
      currentProgress: json['current_progress'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: json['xp_reward'] as int,
      coinReward: json['coin_reward'] as int,
      isCompleted: json['is_completed'] as bool,
      isFailed: json['is_failed'] as bool,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
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
