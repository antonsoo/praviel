import 'dart:convert';
import 'package:http/http.dart' as http;

/// API client for leaderboard endpoints
class LeaderboardApi {
  LeaderboardApi({required this.baseUrl});

  final String baseUrl;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Get global leaderboard (all users worldwide by total XP)
  Future<LeaderboardResponse> getGlobalLeaderboard({int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/api/v1/social/leaderboard/global?limit=$limit');
    final response = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode == 200) {
      return LeaderboardResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load global leaderboard: ${response.body}');
    }
  }

  /// Get friends leaderboard (current user + their friends)
  Future<LeaderboardResponse> getFriendsLeaderboard({int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/api/v1/social/leaderboard/friends?limit=$limit');
    final response = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode == 200) {
      return LeaderboardResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load friends leaderboard: ${response.body}');
    }
  }

  /// Get local/regional leaderboard (users in same region as current user)
  Future<LeaderboardResponse> getLocalLeaderboard({int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/api/v1/social/leaderboard/local?limit=$limit');
    final response = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode == 200) {
      return LeaderboardResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load local leaderboard: ${response.body}');
    }
  }
}

/// Leaderboard response with rankings
class LeaderboardResponse {
  final String boardType; // global, friends, local
  final List<LeaderboardEntry> users;
  final int currentUserRank;
  final int totalUsers;

  LeaderboardResponse({
    required this.boardType,
    required this.users,
    required this.currentUserRank,
    required this.totalUsers,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      boardType: json['board_type'] as String,
      users: (json['users'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentUserRank: json['current_user_rank'] as int,
      totalUsers: json['total_users'] as int,
    );
  }

  // Convenience getters
  List<LeaderboardEntry> get entries => users;
  int get totalParticipants => totalUsers;
  LeaderboardEntry? get currentUserEntry => users.firstWhere(
        (entry) => entry.isCurrentUser,
        orElse: () => LeaderboardEntry(
          rank: currentUserRank,
          userId: 0,
          username: '',
          xp: 0,
          level: 0,
          isCurrentUser: true,
        ),
      );
}

/// Single entry in a leaderboard
class LeaderboardEntry {
  final int rank;
  final int userId;
  final String username;
  final int xp;
  final int level;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.xp,
    required this.level,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      xp: json['xp'] as int,
      level: json['level'] as int,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }
}
