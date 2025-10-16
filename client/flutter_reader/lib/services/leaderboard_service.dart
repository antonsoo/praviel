import 'package:flutter/foundation.dart';
import '../widgets/gamification/leaderboard_widget.dart';
import '../models/challenge_leaderboard_entry.dart';
import 'backend_progress_service.dart';
import 'social_api.dart';
import 'challenges_api.dart' as api;

/// Service for managing leaderboard data
class LeaderboardService extends ChangeNotifier {
  LeaderboardService({
    required this.progressService,
    required this.socialApi,
    required this.challengesApi,
  });

  final BackendProgressService progressService;
  final SocialApi socialApi;
  final api.ChallengesApi challengesApi;

  List<LeaderboardUser> _globalLeaderboard = [];
  List<LeaderboardUser> _friendsLeaderboard = [];
  List<LeaderboardUser> _localLeaderboard = [];
  List<ChallengeLeaderboardEntry> _challengeLeaderboard = [];

  int _globalUserRank = 0;
  int _friendsUserRank = 0;
  int _localUserRank = 0;
  int _challengeUserRank = 0;

  bool _isLoading = false;
  String? _error;

  List<LeaderboardUser> get globalLeaderboard => _globalLeaderboard;
  List<LeaderboardUser> get friendsLeaderboard => _friendsLeaderboard;
  List<LeaderboardUser> get localLeaderboard => _localLeaderboard;
  List<ChallengeLeaderboardEntry> get challengeLeaderboard =>
      _challengeLeaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get challengeUserRank => _challengeUserRank;

  /// Get current user's rank on selected leaderboard (0=global, 1=friends, 2=local)
  int currentUserRank(int boardIndex) {
    switch (boardIndex) {
      case 0:
        return _globalUserRank;
      case 1:
        return _friendsUserRank;
      case 2:
        return _localUserRank;
      default:
        return _globalUserRank;
    }
  }

  /// Get XP needed to reach next rank
  int xpToNextRank(int boardIndex) {
    final board = _getBoardByIndex(boardIndex);
    final currentRank = currentUserRank(boardIndex);

    if (currentRank == 1) return 0; // Already #1

    final userAbove = board.firstWhere(
      (u) => u.rank == currentRank - 1,
      orElse: () =>
          const LeaderboardUser(name: 'Unknown', xp: 0, level: 1, rank: 1),
    );

    final currentXP = progressService.xpTotal;
    final gap = userAbove.xp - currentXP;
    return gap > 0 ? gap : 0;
  }

  List<LeaderboardUser> _getBoardByIndex(int index) {
    switch (index) {
      case 0:
        return _globalLeaderboard;
      case 1:
        return _friendsLeaderboard;
      case 2:
        return _localLeaderboard;
      default:
        return _globalLeaderboard;
    }
  }

  /// Load all leaderboards from API
  Future<void> loadLeaderboards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all three leaderboard types in parallel
      final results = await Future.wait([
        socialApi.getLeaderboard('global', limit: 50),
        socialApi.getLeaderboard('friends', limit: 50),
        socialApi.getLeaderboard('local', limit: 50),
      ]);

      // Global leaderboard
      final globalResponse = results[0];
      _globalLeaderboard = globalResponse.users
          .map(
            (u) => LeaderboardUser(
              name: u.username,
              xp: u.xp,
              level: u.level,
              rank: u.rank,
              isCurrentUser: u.isCurrentUser,
              avatarUrl: u.avatarUrl,
            ),
          )
          .toList();
      _globalUserRank = globalResponse.currentUserRank;

      // Friends leaderboard
      final friendsResponse = results[1];
      _friendsLeaderboard = friendsResponse.users
          .map(
            (u) => LeaderboardUser(
              name: u.username,
              xp: u.xp,
              level: u.level,
              rank: u.rank,
              isCurrentUser: u.isCurrentUser,
              avatarUrl: u.avatarUrl,
            ),
          )
          .toList();
      _friendsUserRank = friendsResponse.currentUserRank;

      // Local leaderboard
      final localResponse = results[2];
      _localLeaderboard = localResponse.users
          .map(
            (u) => LeaderboardUser(
              name: u.username,
              xp: u.xp,
              level: u.level,
              rank: u.rank,
              isCurrentUser: u.isCurrentUser,
              avatarUrl: u.avatarUrl,
            ),
          )
          .toList();
      _localUserRank = localResponse.currentUserRank;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh leaderboard data (for pull-to-refresh)
  Future<void> refresh() async {
    await loadLeaderboards();
  }

  /// Add a friend by username
  Future<void> addFriend(String username) async {
    try {
      await socialApi.addFriend(username);
      // Refresh friends leaderboard after adding
      await loadLeaderboards();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(int friendshipId) async {
    try {
      await socialApi.acceptFriendRequest(friendshipId);
      // Refresh friends leaderboard after accepting
      await loadLeaderboards();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get friends list
  Future<List<FriendResponse>> getFriends() async {
    try {
      return await socialApi.getFriends();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Load challenge completion leaderboard
  Future<void> loadChallengeLeaderboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get challenge leaderboard from backend API
      final response = await challengesApi.getChallengeLeaderboard(limit: 50);

      _challengeLeaderboard = response.entries
          .map(
            (entry) => ChallengeLeaderboardEntry(
              userId: entry.userId.toString(),
              username: entry.username,
              avatarUrl: null, // Backend doesn't provide avatar yet
              challengesCompleted: entry.challengesCompleted,
              currentStreak: entry.currentStreak,
              longestStreak: entry.longestStreak,
              totalRewards: entry.totalRewards,
              rank: entry.rank,
            ),
          )
          .toList();

      // Get current user's rank from API
      _challengeUserRank = response.userRank;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all leaderboards including challenge leaderboard
  Future<void> refreshAll() async {
    await Future.wait([loadLeaderboards(), loadChallengeLeaderboard()]);
  }
}
