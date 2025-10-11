import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../api/progress_api.dart';
import 'progress_store.dart';

/// Backend-connected progress service that syncs with the server
/// Falls back to local storage when offline or not authenticated
class BackendProgressService extends ChangeNotifier {
  BackendProgressService({
    required ProgressApi progressApi,
    required ProgressStore localStore,
    required bool isAuthenticated,
  })  : _progressApi = progressApi,
        _localStore = localStore,
        _isAuthenticated = isAuthenticated;

  final ProgressApi _progressApi;
  final ProgressStore _localStore;
  bool _isAuthenticated;

  UserProgressResponse? _backendProgress;
  Map<String, dynamic> _localProgress = {};
  bool _loaded = false;
  bool _syncing = false;
  Future<void> _updateChain = Future.value();

  // Getters - prefer backend data when available, fallback to local
  int get xpTotal => _backendProgress?.xpTotal ?? (_localProgress['xpTotal'] as int? ?? 0);
  int get streakDays => _backendProgress?.streakDays ?? (_localProgress['streakDays'] as int? ?? 0);
  int get maxStreak => _backendProgress?.maxStreak ?? 0;
  int get coins => _backendProgress?.coins ?? 0;
  int get streakFreezes => _backendProgress?.streakFreezes ?? 0;
  int get totalLessons => _backendProgress?.totalLessons ?? (_localProgress['totalLessons'] as int? ?? 0);
  int get totalExercises => _backendProgress?.totalExercises ?? 0;
  int get totalTimeMinutes => _backendProgress?.totalTimeMinutes ?? 0;
  int get perfectLessons => _localProgress['perfectLessons'] as int? ?? 0;
  int get wordsLearned => _localProgress['wordsLearned'] as int? ?? 0;
  DateTime? get lastLessonAt => _backendProgress?.lastLessonAt ??
      (_localProgress['lastLessonAt'] != null ? DateTime.tryParse(_localProgress['lastLessonAt'] as String) : null);
  DateTime? get lastStreakUpdate => _backendProgress?.lastStreakUpdate;

  int get currentLevel => _backendProgress?.level ?? calculateLevel(xpTotal);
  int get xpForCurrentLevel => _backendProgress?.xpForCurrentLevel ?? getXPForLevel(currentLevel);
  int get xpForNextLevel => _backendProgress?.xpForNextLevel ?? getXPForLevel(currentLevel + 1);
  double get progressToNextLevel => _backendProgress?.progressToNextLevel ?? getProgressToNextLevel(xpTotal);
  int get xpToNextLevel => _backendProgress?.xpToNextLevel ?? (xpForNextLevel - xpTotal);

  bool get hasProgress => xpTotal > 0 || streakDays > 0;
  bool get isLoaded => _loaded;
  bool get isSyncing => _syncing;
  bool get isUsingBackend => _backendProgress != null && _isAuthenticated;

  /// Calculate level from total XP: Level = floor(sqrt(XP/100))
  static int calculateLevel(int xp) {
    if (xp <= 0) return 0;
    return (sqrt(xp / 100)).floor();
  }

  /// Get XP required to reach a specific level: XP = level^2 * 100
  static int getXPForLevel(int level) {
    return level * level * 100;
  }

  /// Get progress percentage to next level (0.0 to 1.0)
  static double getProgressToNextLevel(int xp) {
    final currentLevel = calculateLevel(xp);
    final currentLevelXP = getXPForLevel(currentLevel);
    final nextLevelXP = getXPForLevel(currentLevel + 1);
    final xpInCurrentLevel = xp - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;
    if (xpNeededForNextLevel == 0) return 0.0;
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  void updateAuthStatus(bool isAuthenticated) {
    if (_isAuthenticated != isAuthenticated) {
      _isAuthenticated = isAuthenticated;
      if (isAuthenticated) {
        // Just authenticated - sync local progress to backend
        _syncLocalToBackend();
      }
    }
  }

  Future<void> load() async {
    try {
      // Always load local progress first (fast, offline-capable)
      _localProgress = await _localStore.load();
      _loaded = true;
      notifyListeners();

      // If authenticated, fetch from backend
      if (_isAuthenticated) {
        await _syncFromBackend();
      }
    } catch (e) {
      debugPrint('[BackendProgressService] Failed to load: $e');
      _localProgress = {};
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _syncFromBackend() async {
    if (!_isAuthenticated) return;

    try {
      _syncing = true;
      notifyListeners();

      final backendData = await _progressApi.getUserProgress();
      _backendProgress = backendData;

      debugPrint('[BackendProgressService] Synced from backend: ${backendData.xpTotal} XP, ${backendData.streakDays} day streak');

      _syncing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[BackendProgressService] Backend sync failed: $e');
      _syncing = false;
      notifyListeners();
      // Continue using local data as fallback
    }
  }

  Future<void> _syncLocalToBackend() async {
    if (!_isAuthenticated) return;

    try {
      // If we have local progress but no backend progress, push local to backend
      final localXP = _localProgress['xpTotal'] as int? ?? 0;
      if (localXP > 0 && (_backendProgress == null || _backendProgress!.xpTotal == 0)) {
        debugPrint('[BackendProgressService] Pushing local progress to backend...');
        await _progressApi.updateProgress(
          xpGained: localXP,
          lessonId: 'local_sync',
        );
        await _syncFromBackend();
      }
    } catch (e) {
      debugPrint('[BackendProgressService] Failed to sync local to backend: $e');
    }
  }

  Future<void> updateProgress({
    required int xpGained,
    required DateTime timestamp,
    bool isPerfect = false,
    int wordsLearnedCount = 0,
    bool countLesson = true,
    String? lessonId,
  }) async {
    // Chain updates sequentially
    final previousUpdate = _updateChain;
    final completer = Completer<void>();

    _updateChain = previousUpdate.then((_) async {
      try {
        await _performUpdate(
          xpGained,
          timestamp,
          isPerfect,
          wordsLearnedCount,
          countLesson,
          lessonId,
        );
        completer.complete();
      } catch (e) {
        completer.completeError(e);
        rethrow;
      }
    });

    return completer.future;
  }

  Future<void> _performUpdate(
    int xpGained,
    DateTime timestamp,
    bool isPerfect,
    int wordsLearnedCount,
    bool countLesson,
    String? lessonId,
  ) async {
    final oldLevel = currentLevel;

    try {
      if (_isAuthenticated) {
        // Update backend first
        final updated = await _progressApi.updateProgress(
          xpGained: xpGained,
          lessonId: lessonId,
          timeSpentMinutes: 1, // TODO: track actual time
          isPerfect: isPerfect,
          wordsLearnedCount: wordsLearnedCount,
        );

        _backendProgress = updated;
        debugPrint('[BackendProgressService] Backend updated: ${updated.xpTotal} XP, ${updated.streakDays} day streak');

        // Also update local cache for offline access
        _localProgress['xpTotal'] = updated.xpTotal;
        _localProgress['streakDays'] = updated.streakDays;
        _localProgress['totalLessons'] = updated.totalLessons;
        _localProgress['lastLessonAt'] = updated.lastLessonAt?.toIso8601String();
        await _localStore.save(_localProgress);
      } else {
        // Offline mode - update local only
        final updatedLocal = Map<String, dynamic>.from(_localProgress);
        updatedLocal['xpTotal'] = xpTotal + xpGained;

        if (countLesson) {
          updatedLocal['lastLessonAt'] = timestamp.toIso8601String();
          updatedLocal['totalLessons'] = totalLessons + 1;
          updatedLocal['wordsLearned'] = (updatedLocal['wordsLearned'] as int? ?? 0) + wordsLearnedCount;
          if (isPerfect) {
            updatedLocal['perfectLessons'] = (updatedLocal['perfectLessons'] as int? ?? 0) + 1;
          }

          // Update streak (simple logic for offline mode)
          final today = DateTime(timestamp.year, timestamp.month, timestamp.day);
          final lastUpdate = updatedLocal['lastStreakUpdate'] as String?;

          if (lastUpdate != null) {
            final lastDay = DateTime.parse(lastUpdate);
            final diff = today.difference(DateTime(lastDay.year, lastDay.month, lastDay.day)).inDays;

            if (diff == 0) {
              // Same day - no change
            } else if (diff == 1) {
              // Next day - increment
              updatedLocal['streakDays'] = streakDays + 1;
              updatedLocal['lastStreakUpdate'] = today.toIso8601String();
            } else {
              // Gap - reset
              updatedLocal['streakDays'] = 1;
              updatedLocal['lastStreakUpdate'] = today.toIso8601String();
            }
          } else {
            // First lesson
            updatedLocal['streakDays'] = 1;
            updatedLocal['lastStreakUpdate'] = today.toIso8601String();
          }
        }

        await _localStore.save(updatedLocal);
        _localProgress = updatedLocal;

        debugPrint('[BackendProgressService] Local updated (offline): ${updatedLocal['xpTotal']} XP');
      }

      notifyListeners();

      // Check for level up
      final newLevel = currentLevel;
      if (newLevel > oldLevel) {
        debugPrint('[BackendProgressService] Level up! $oldLevel -> $newLevel');
        // TODO: trigger celebration animation
      }
    } catch (e) {
      debugPrint('[BackendProgressService] Update failed: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    if (_isAuthenticated) {
      await _syncFromBackend();
    } else {
      await load();
    }
  }

  Future<void> reset() async {
    await _localStore.reset();
    _localProgress = await _localStore.load();
    _backendProgress = null;
    notifyListeners();
  }
}
