import 'dart:convert';
import 'package:http/http.dart' as http;

/// API client for achievements
class AchievementsApi {
  AchievementsApi({required this.baseUrl});

  final String baseUrl;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Get user's unlocked achievements
  Future<List<Achievement>> getUserAchievements() async {
    final uri = Uri.parse('$baseUrl/api/v1/progress/me/achievements');
    final response = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
      return json.map((e) => Achievement.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load achievements: ${response.body}');
    }
  }
}

/// Achievement model
class Achievement {
  final int id;
  final int userId;
  final String achievementType; // badge, milestone, collection
  final String achievementId;
  final Map<String, dynamic> meta; // Contains title, description, icon, tier, etc.
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
