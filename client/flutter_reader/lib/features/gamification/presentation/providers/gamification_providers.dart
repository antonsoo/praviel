import 'dart:math' as dart_math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/user_progress.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../../../app_providers.dart';
import '../../../../services/auth_service.dart';

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

/// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return ref.watch(apiHttpClientProvider);
});

/// Base URL provider (override in main.dart with actual API URL)
final baseUrlProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.apiBaseUrl;
});

/// Gamification repository provider
/// Uses HttpGamificationRepository to connect to backend API
/// Falls back to MockGamificationRepository if backend is unavailable
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  // Production implementation: connect to backend API
  final client = ref.watch(httpClientProvider);
  final baseUrl = ref.watch(baseUrlProvider);
  final repository = HttpGamificationRepository(
    client: client,
    baseUrl: baseUrl,
  );

  void syncToken(AuthService auth) {
    repository.setAuthToken(auth.accessToken);
  }

  final auth = ref.watch(authServiceProvider);
  syncToken(auth);

  ref.listen<AuthService>(authServiceProvider, (_, next) => syncToken(next));

  return repository;

  // For development/demo with mock data, uncomment:
  // return MockGamificationRepository();
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Current user ID state notifier
class CurrentUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setUserId(String? userId) {
    state = userId;
  }
}

/// Current user ID provider (should be set from auth state)
final currentUserIdProvider = NotifierProvider<CurrentUserIdNotifier, String?>(
  CurrentUserIdNotifier.new,
);

/// Auto-sync auth state to current user ID provider
final authUserIdSyncProvider = Provider<void>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.id.toString();

  // Update currentUserIdProvider when auth state changes
  if (userId != null) {
    ref.read(currentUserIdProvider.notifier).setUserId(userId);
  } else {
    ref.read(currentUserIdProvider.notifier).setUserId(null);
  }
});

/// User progress provider with auto-loading
final userProgressProvider = FutureProvider.autoDispose<UserProgress>((
  ref,
) async {
  final auth = ref.watch(authServiceProvider);
  final currentUser = auth.currentUser;
  if (!auth.isAuthenticated || currentUser == null) {
    return UserProgress.guest();
  }

  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getUserProgress(currentUser.id.toString());
});

/// Achievements provider
final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((
  ref,
) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getAchievements();
});

/// User achievements provider
final userAchievementsProvider = FutureProvider.autoDispose<List<Achievement>>((
  ref,
) async {
  final auth = ref.watch(authServiceProvider);
  final currentUser = auth.currentUser;
  if (!auth.isAuthenticated || currentUser == null) {
    return const <Achievement>[];
  }

  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getUserAchievements(currentUser.id.toString());
});

/// Daily challenges provider
final dailyChallengesProvider =
    FutureProvider.autoDispose<List<DailyChallenge>>((ref) async {
      final auth = ref.watch(authServiceProvider);
      final currentUser = auth.currentUser;
      if (!auth.isAuthenticated || currentUser == null) {
        return const <DailyChallenge>[];
      }

      final repository = ref.watch(gamificationRepositoryProvider);
      return repository.getDailyChallenges(currentUser.id.toString());
    });

/// Leaderboard provider with parameters
final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, LeaderboardParams>((ref, params) async {
      final repository = ref.watch(gamificationRepositoryProvider);
      return repository.getLeaderboard(
        scope: params.scope,
        period: params.period,
        languageCode: params.languageCode,
        limit: params.limit,
      );
    });

/// Leaderboard parameters class
class LeaderboardParams {
  final LeaderboardScope scope;
  final LeaderboardPeriod period;
  final String? languageCode;
  final int limit;

  const LeaderboardParams({
    required this.scope,
    required this.period,
    this.languageCode,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardParams &&
          runtimeType == other.runtimeType &&
          scope == other.scope &&
          period == other.period &&
          languageCode == other.languageCode &&
          limit == other.limit;

  @override
  int get hashCode =>
      scope.hashCode ^ period.hashCode ^ languageCode.hashCode ^ limit.hashCode;
}

// ============================================================================
// CONTROLLER PROVIDERS (for mutations)
// ============================================================================

/// Gamification controller for state mutations
final gamificationControllerProvider = Provider<GamificationController>((ref) {
  return GamificationController(ref);
});

/// Controller class for gamification actions
class GamificationController {
  final Ref _ref;

  GamificationController(this._ref);

  bool get _isAuthenticated {
    final auth = _ref.read(authServiceProvider);
    return auth.isAuthenticated && auth.currentUser != null;
  }

  /// Update user progress
  Future<void> updateProgress(UserProgress progress) async {
    if (!_isAuthenticated) {
      return;
    }

    final repository = _ref.read(gamificationRepositoryProvider);
    await repository.updateProgress(progress);
    // Invalidate to trigger refresh
    _ref.invalidate(userProgressProvider);
  }

  /// Add XP to user
  Future<void> addXp(int xp, String languageCode) async {
    if (!_isAuthenticated) {
      return;
    }

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final currentProgress = await _ref.read(userProgressProvider.future);

    final newLanguageXp = Map<String, int>.from(currentProgress.languageXp);
    newLanguageXp[languageCode] = (newLanguageXp[languageCode] ?? 0) + xp;

    final newTotalXp = currentProgress.totalXp + xp;
    final newLevel = _calculateLevel(newTotalXp);

    final updatedProgress = currentProgress.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
      languageXp: newLanguageXp,
      lastActivityDate: DateTime.now(),
    );

    await updateProgress(updatedProgress);
  }

  /// Complete a lesson
  Future<void> completeLesson({
    required String languageCode,
    required int xpEarned,
    required int wordsLearned,
    required int minutesStudied,
  }) async {
    if (!_isAuthenticated) {
      return;
    }

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final currentProgress = await _ref.read(userProgressProvider.future);

    // Update streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = DateTime(
      currentProgress.lastActivityDate.year,
      currentProgress.lastActivityDate.month,
      currentProgress.lastActivityDate.day,
    );

    int newStreak = currentProgress.currentStreak;
    if (lastActivity == today) {
      // Same day, no change
    } else if (lastActivity == today.subtract(const Duration(days: 1))) {
      // Yesterday, increment streak
      newStreak++;
    } else {
      // Streak broken, reset to 1
      newStreak = 1;
    }

    final newLongestStreak = newStreak > currentProgress.longestStreak
        ? newStreak
        : currentProgress.longestStreak;

    // Update language XP
    final newLanguageXp = Map<String, int>.from(currentProgress.languageXp);
    newLanguageXp[languageCode] = (newLanguageXp[languageCode] ?? 0) + xpEarned;

    final newTotalXp = currentProgress.totalXp + xpEarned;
    final newLevel = _calculateLevel(newTotalXp);

    // Update weekly activity
    final newWeeklyActivity = List<DailyActivity>.from(
      currentProgress.weeklyActivity,
    );
    final todayIndex = newWeeklyActivity.indexWhere(
      (a) => _isSameDay(a.date, today),
    );

    if (todayIndex >= 0) {
      // Update existing entry
      final todayActivity = newWeeklyActivity[todayIndex];
      newWeeklyActivity[todayIndex] = DailyActivity(
        date: today,
        lessonsCompleted: todayActivity.lessonsCompleted + 1,
        xpEarned: todayActivity.xpEarned + xpEarned,
        minutesStudied: todayActivity.minutesStudied + minutesStudied,
      );
    } else {
      // Add new entry
      newWeeklyActivity.add(
        DailyActivity(
          date: today,
          lessonsCompleted: 1,
          xpEarned: xpEarned,
          minutesStudied: minutesStudied,
        ),
      );
      // Keep only last 7 days
      newWeeklyActivity.sort((a, b) => a.date.compareTo(b.date));
      if (newWeeklyActivity.length > 7) {
        newWeeklyActivity.removeAt(0);
      }
    }

    final updatedProgress = currentProgress.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: now,
      lessonsCompleted: currentProgress.lessonsCompleted + 1,
      wordsLearned: currentProgress.wordsLearned + wordsLearned,
      minutesStudied: currentProgress.minutesStudied + minutesStudied,
      languageXp: newLanguageXp,
      weeklyActivity: newWeeklyActivity,
    );

    await updateProgress(updatedProgress);

    // Check for achievements
    await _checkAchievements(updatedProgress);

    // Update challenge progress
    _ref.invalidate(dailyChallengesProvider);
  }

  /// Unlock an achievement
  Future<void> unlockAchievement(String achievementId) async {
    if (!_isAuthenticated) {
      return;
    }

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final repository = _ref.read(gamificationRepositoryProvider);
    await repository.unlockAchievement(userId, achievementId);

    // Invalidate to trigger refresh
    _ref.invalidate(userAchievementsProvider);
    _ref.invalidate(achievementsProvider);
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    if (!_isAuthenticated) {
      return;
    }

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final repository = _ref.read(gamificationRepositoryProvider);
    await repository.updateChallengeProgress(userId, challengeId, progress);

    // Invalidate to trigger refresh
    _ref.invalidate(dailyChallengesProvider);
  }

  // Helper methods

  int _calculateLevel(int totalXp) {
    // Reverse of XP formula: level = (totalXp / 100)^(2/3)
    return (totalXp / 100)
        .clamp(1, double.infinity)
        .toDouble()
        .pow(2 / 3)
        .floor();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _checkAchievements(UserProgress progress) async {
    final allAchievements = await _ref.read(achievementsProvider.future);

    for (final achievement in allAchievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      final requirement = achievement.requirement;
      if (requirement is LessonsCountRequirement) {
        shouldUnlock = progress.lessonsCompleted >= requirement.count;
      } else if (requirement is StreakDaysRequirement) {
        shouldUnlock = progress.currentStreak >= requirement.days;
      } else if (requirement is XpTotalRequirement) {
        shouldUnlock = progress.totalXp >= requirement.xp;
      } else if (requirement is WordsLearnedRequirement) {
        shouldUnlock = progress.wordsLearned >= requirement.words;
      } else if (requirement is LanguagesMasteredRequirement) {
        final masteredLanguages = progress.languageXp.values
            .where((xp) => xp > 0)
            .length;
        shouldUnlock = masteredLanguages >= requirement.count;
      }

      if (shouldUnlock) {
        await unlockAchievement(achievement.id);
      }
    }
  }
}

extension on double {
  double pow(num exponent) {
    return dart_math.pow(this, exponent).toDouble();
  }
}
