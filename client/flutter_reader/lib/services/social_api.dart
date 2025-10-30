import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// API client for social features (leaderboard, friends, challenges, power-ups)
class SocialApi {
  SocialApi({required this.baseUrl, http.Client? client})
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

  bool get _hasAuth => _authToken != null && _authToken!.trim().isNotEmpty;

  void _ensureAuthenticated() {
    if (!_hasAuth) {
      throw Exception('Authentication required');
    }
  }

  /// Retry helper for transient network errors with exponential backoff
  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (e) {
        // Don't retry on HTTP errors - only transient network errors
        if (e.toString().contains('Failed to')) {
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

  // Leaderboard

  Future<LeaderboardResponse> getLeaderboard(
    String boardType, {
    int limit = 50,
  }) async {
    if (!_hasAuth) {
      return LeaderboardResponse(
        boardType: boardType,
        users: const [],
        currentUserRank: 0,
        totalUsers: 0,
      );
    }

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/social/leaderboard/$boardType?limit=$limit',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return LeaderboardResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to load leaderboard: ${response.body}');
      }
    });
  }

  // Friends

  Future<List<FriendResponse>> getFriends() async {
    if (!_hasAuth) {
      return <FriendResponse>[];
    }

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/friends');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map(
              (json) => FriendResponse.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to load friends: ${response.body}');
      }
    });
  }

  Future<Map<String, dynamic>> addFriend(String username) async {
    _ensureAuthenticated();

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/friends/add');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'friend_username': username}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to add friend: ${response.body}');
      }
    });
  }

  Future<Map<String, dynamic>> acceptFriendRequest(int friendId) async {
    _ensureAuthenticated();

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/friends/$friendId/accept');
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to accept friend request: ${response.body}');
      }
    });
  }

  Future<Map<String, dynamic>> removeFriend(int friendId) async {
    _ensureAuthenticated();

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/friends/$friendId');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to remove friend: ${response.body}');
      }
    });
  }

  // Challenges

  Future<ChallengeResponse> createChallenge({
    required int friendId,
    required String challengeType,
    required int targetValue,
    int durationHours = 24,
  }) async {
    _ensureAuthenticated();

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/challenges/create');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'friend_id': friendId,
              'challenge_type': challengeType,
              'target_value': targetValue,
              'duration_hours': durationHours,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return ChallengeResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to create challenge: ${response.body}');
      }
    });
  }

  Future<List<ChallengeResponse>> getChallenges() async {
    if (!_hasAuth) {
      return <ChallengeResponse>[];
    }

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/challenges');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map(
              (json) =>
                  ChallengeResponse.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to load challenges: ${response.body}');
      }
    });
  }

  // Power-Ups

  Future<List<PowerUpInventoryResponse>> getPowerUps() async {
    if (!_hasAuth) {
      return <PowerUpInventoryResponse>[];
    }

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/power-ups');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map(
              (json) => PowerUpInventoryResponse.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw Exception('Failed to load power-ups: ${response.body}');
      }
    });
  }

  Future<Map<String, dynamic>> purchasePowerUp({
    required String powerUpType,
    int quantity = 1,
  }) async {
    _ensureAuthenticated();

    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/social/power-ups/purchase');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'power_up_type': powerUpType,
              'quantity': quantity,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to purchase power-up: ${response.body}');
      }
    });
  }

  Future<Map<String, dynamic>> activatePowerUp(String powerUpType) async {
    _ensureAuthenticated();

    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/social/power-ups/$powerUpType/activate',
      );
      final response = await _client
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to activate power-up: ${response.body}');
      }
    });
  }

  // User Profile

  Future<UserProfileResponse> getUserProfile() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/users/me');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserProfileResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    });
  }

  Future<UserProfileResponse> updateUserProfile({
    String? realName,
    String? discordUsername,
    String? profileVisibility,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/users/me');
      final body = <String, dynamic>{};
      if (realName != null) {
        body['real_name'] = realName.isEmpty ? null : realName;
      }
      if (discordUsername != null) {
        body['discord_username'] = discordUsername.isEmpty
            ? null
            : discordUsername;
      }
      if (profileVisibility != null) {
        body['profile_visibility'] = profileVisibility;
      }

      final response = await _client
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserProfileResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    });
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

// Response Models

class LeaderboardResponse {
  LeaderboardResponse({
    required this.boardType,
    required this.users,
    required this.currentUserRank,
    required this.totalUsers,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      boardType: json['board_type'] as String,
      users: (json['users'] as List)
          .map(
            (u) => LeaderboardUserResponse.fromJson(u as Map<String, dynamic>),
          )
          .toList(),
      currentUserRank: json['current_user_rank'] as int,
      totalUsers: json['total_users'] as int,
    );
  }

  final String boardType;
  final List<LeaderboardUserResponse> users;
  final int currentUserRank;
  final int totalUsers;
}

class LeaderboardUserResponse {
  LeaderboardUserResponse({
    required this.rank,
    required this.userId,
    required this.username,
    required this.xp,
    required this.level,
    this.isCurrentUser = false,
    this.avatarUrl,
  });

  factory LeaderboardUserResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardUserResponse(
      rank: json['rank'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      xp: json['xp'] as int,
      level: json['level'] as int,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final int rank;
  final int userId;
  final String username;
  final int xp;
  final int level;
  final bool isCurrentUser;
  final String? avatarUrl;
}

class FriendResponse {
  FriendResponse({
    required this.userId,
    required this.username,
    required this.xp,
    required this.level,
    required this.status,
    this.isOnline = false,
  });

  factory FriendResponse.fromJson(Map<String, dynamic> json) {
    return FriendResponse(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      xp: json['xp'] as int,
      level: json['level'] as int,
      status: json['status'] as String,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }

  final int userId;
  final String username;
  final int xp;
  final int level;
  final String status;
  final bool isOnline;
}

class ChallengeResponse {
  ChallengeResponse({
    required this.id,
    required this.challengeType,
    required this.targetValue,
    required this.initiatorUsername,
    required this.opponentUsername,
    required this.initiatorProgress,
    required this.opponentProgress,
    required this.status,
    required this.startsAt,
    required this.expiresAt,
  });

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(
      id: json['id'] as int,
      challengeType: json['challenge_type'] as String,
      targetValue: json['target_value'] as int,
      initiatorUsername: json['initiator_username'] as String,
      opponentUsername: json['opponent_username'] as String,
      initiatorProgress: json['initiator_progress'] as int,
      opponentProgress: json['opponent_progress'] as int,
      status: json['status'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final int id;
  final String challengeType;
  final int targetValue;
  final String initiatorUsername;
  final String opponentUsername;
  final int initiatorProgress;
  final int opponentProgress;
  final String status;
  final DateTime startsAt;
  final DateTime expiresAt;
}

class PowerUpInventoryResponse {
  PowerUpInventoryResponse({
    required this.powerUpType,
    required this.quantity,
    required this.activeCount,
  });

  factory PowerUpInventoryResponse.fromJson(Map<String, dynamic> json) {
    return PowerUpInventoryResponse(
      powerUpType: json['power_up_type'] as String,
      quantity: json['quantity'] as int,
      activeCount: json['active_count'] as int,
    );
  }

  final String powerUpType;
  final int quantity;
  final int activeCount;
}

class UserProfileResponse {
  UserProfileResponse({
    required this.username,
    required this.email,
    this.realName,
    this.discordUsername,
    required this.profileVisibility,
    required this.createdAt,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      username: json['username'] as String,
      email: json['email'] as String,
      realName: json['real_name'] as String?,
      discordUsername: json['discord_username'] as String?,
      profileVisibility: json['profile_visibility'] as String? ?? 'friends',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String username;
  final String email;
  final String? realName;
  final String? discordUsername;
  final String profileVisibility;
  final DateTime createdAt;
}
