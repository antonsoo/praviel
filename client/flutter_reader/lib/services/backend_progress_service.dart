import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../api/api_exception.dart';
import '../api/progress_api.dart';
import 'progress_store.dart';

/// Level-up event for triggering UI celebrations
class LevelUpEvent {
  final int oldLevel;
  final int newLevel;
  final DateTime timestamp;

  LevelUpEvent({
    required this.oldLevel,
    required this.newLevel,
    required this.timestamp,
  });
}

/// Backend-connected progress service that syncs with the server
/// Falls back to local storage when offline or not authenticated
class BackendProgressService extends ChangeNotifier {
  BackendProgressService({
    required ProgressApi progressApi,
    required ProgressStore localStore,
    required bool isAuthenticated,
    Connectivity? connectivity,
  }) : _progressApi = progressApi,
       _localStore = localStore,
       _isAuthenticated = isAuthenticated,
       _connectivity = connectivity ?? Connectivity();

  final ProgressApi _progressApi;
  final ProgressStore _localStore;
  bool _isAuthenticated;
  final Connectivity _connectivity;

  UserProgressResponse? _backendProgress;
  Map<String, dynamic> _localProgress = {};
  bool _loaded = false;
  bool _syncing = false;
  Future<void> _updateChain = Future.value();
  Box<Map<String, dynamic>>? _queueBox;
  final String _queueBoxName = 'progress_sync_queue';
  List<_QueuedProgressUpdate> _pendingUpdates = [];
  bool _queueInitialized = false;
  bool _queueProcessing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  final _levelUpController = StreamController<LevelUpEvent>.broadcast();
  Stream<LevelUpEvent> get levelUpStream => _levelUpController.stream;

  // Getters - prefer backend data when available, fallback to local
  int get xpTotal =>
      _backendProgress?.xpTotal ?? (_localProgress['xpTotal'] as int? ?? 0);
  int get streakDays =>
      _backendProgress?.streakDays ??
      (_localProgress['streakDays'] as int? ?? 0);
  int get maxStreak => _backendProgress?.maxStreak ?? 0;
  int get coins => _backendProgress?.coins ?? 0;
  int get streakFreezes => _backendProgress?.streakFreezes ?? 0;
  int get totalLessons =>
      _backendProgress?.totalLessons ??
      (_localProgress['totalLessons'] as int? ?? 0);
  int get totalExercises => _backendProgress?.totalExercises ?? 0;
  int get totalTimeMinutes => _backendProgress?.totalTimeMinutes ?? 0;
  int get perfectLessons => _localProgress['perfectLessons'] as int? ?? 0;
  int get wordsLearned => _localProgress['wordsLearned'] as int? ?? 0;
  DateTime? get lastLessonAt =>
      _backendProgress?.lastLessonAt ??
      (_localProgress['lastLessonAt'] != null
          ? DateTime.tryParse(_localProgress['lastLessonAt'] as String)
          : null);
  DateTime? get lastStreakUpdate => _backendProgress?.lastStreakUpdate;

  int get currentLevel => _backendProgress?.level ?? calculateLevel(xpTotal);
  int get xpForCurrentLevel =>
      _backendProgress?.xpForCurrentLevel ?? getXPForLevel(currentLevel);
  int get xpForNextLevel =>
      _backendProgress?.xpForNextLevel ?? getXPForLevel(currentLevel + 1);
  double get progressToNextLevel =>
      _backendProgress?.progressToNextLevel ?? getProgressToNextLevel(xpTotal);
  int get xpToNextLevel =>
      _backendProgress?.xpToNextLevel ?? (xpForNextLevel - xpTotal);

  bool get hasProgress => xpTotal > 0 || streakDays > 0;
  bool get isLoaded => _loaded;
  bool get isSyncing => _syncing;
  bool get isUsingBackend => _backendProgress != null && _isAuthenticated;
  bool get hasPendingSync => _pendingUpdates.isNotEmpty;
  int get pendingSyncCount => _pendingUpdates.length;

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
        unawaited(_syncLocalToBackend());
        unawaited(_attemptProcessQueue());
      }
    }
  }

  Future<void> _persistQueue() async {
    // Use local variable to avoid Flutter 3.35+ null check compiler bug
    final box = _queueBox;
    if (!_queueInitialized || box == null) {
      return;
    }

    await box.clear();
    for (final update in _pendingUpdates) {
      await box.put(update.id, update.toMap());
    }
  }

  bool _shouldQueueError(Object error) {
    if (error is ApiException) {
      return error.shouldRetry;
    }
    return true;
  }

  Future<void> _cacheBackendProgress(UserProgressResponse updated) async {
    _backendProgress = updated;

    _localProgress['xpTotal'] = updated.xpTotal;
    _localProgress['streakDays'] = updated.streakDays;
    _localProgress['totalLessons'] = updated.totalLessons;
    _localProgress['lastLessonAt'] = updated.lastLessonAt?.toIso8601String();
    await _localStore.save(_localProgress);
  }

  Future<void> _applyLocalProgress({
    required int xpGained,
    required DateTime timestamp,
    required bool isPerfect,
    required int wordsLearnedCount,
    required bool countLesson,
  }) async {
    final updatedLocal = Map<String, dynamic>.from(_localProgress);
    updatedLocal['xpTotal'] = xpTotal + xpGained;

    if (countLesson) {
      updatedLocal['lastLessonAt'] = timestamp.toIso8601String();
      updatedLocal['totalLessons'] = totalLessons + 1;
      updatedLocal['wordsLearned'] =
          (updatedLocal['wordsLearned'] as int? ?? 0) + wordsLearnedCount;
      if (isPerfect) {
        updatedLocal['perfectLessons'] =
            (updatedLocal['perfectLessons'] as int? ?? 0) + 1;
      }

      final today = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final lastUpdate = updatedLocal['lastStreakUpdate'] as String?;

      if (lastUpdate != null) {
        final lastDay = DateTime.parse(lastUpdate);
        final diff =
            today.difference(DateTime(lastDay.year, lastDay.month, lastDay.day)).inDays;

        if (diff == 1) {
          updatedLocal['streakDays'] = streakDays + 1;
          updatedLocal['lastStreakUpdate'] = today.toIso8601String();
        } else if (diff > 1) {
          updatedLocal['streakDays'] = 1;
          updatedLocal['lastStreakUpdate'] = today.toIso8601String();
        }
      } else {
        updatedLocal['streakDays'] = 1;
        updatedLocal['lastStreakUpdate'] = today.toIso8601String();
      }
    }

    final newStreakValue = updatedLocal['streakDays'] as int? ?? streakDays;
    final previousMaxStreak = updatedLocal['maxStreak'] as int? ?? maxStreak;
    updatedLocal['maxStreak'] =
        newStreakValue > previousMaxStreak ? newStreakValue : previousMaxStreak;

    _localProgress = updatedLocal;
    await _localStore.save(updatedLocal);

    debugPrint(
      '[BackendProgressService] Local progress updated: ${updatedLocal['xpTotal']} XP (pending sync: ${_pendingUpdates.length})',
    );
  }

  Future<void> _enqueueProgressUpdate({
    required int xpGained,
    required DateTime timestamp,
    required bool isPerfect,
    required int wordsLearnedCount,
    required bool countLesson,
    String? lessonId,
    int? timeSpentMinutes,
    required int baselineXp,
    required int baselineLessons,
    required int baselineStreak,
  }) async {
    await _loadQueue();

    final update = _QueuedProgressUpdate(
      id: '${timestamp.millisecondsSinceEpoch}-${Random().nextInt(1 << 16)}',
      xpGained: xpGained,
      timestamp: timestamp,
      isPerfect: isPerfect,
      wordsLearnedCount: wordsLearnedCount,
      countLesson: countLesson,
      lessonId: lessonId,
      timeSpentMinutes: timeSpentMinutes,
      baselineXp: baselineXp,
      baselineLessons: baselineLessons,
      baselineStreak: baselineStreak,
    );

    _pendingUpdates.add(update);
    _pendingUpdates.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _persistQueue();
    notifyListeners();

    debugPrint(
      '[BackendProgressService] Queued progress update (${_pendingUpdates.length} pending)',
    );
  }

  Future<void> _attemptProcessQueue() async {
    if (!_isAuthenticated) {
      return;
    }

    await _loadQueue();

    if (_pendingUpdates.isEmpty || _queueProcessing) {
      return;
    }

    try {
      final results = await _connectivity.checkConnectivity();
      final isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        debugPrint('[BackendProgressService] Offline, postponing queued progress sync');
        return;
      }
    } catch (e) {
      debugPrint('[BackendProgressService] Connectivity check failed: $e');
    }

    await _processQueueInternal();
  }

  Future<void> _processQueueInternal() async {
    if (_queueProcessing || _pendingUpdates.isEmpty) {
      return;
    }

    _queueProcessing = true;
    notifyListeners();

    try {
      int? serverXp;
      try {
        final snapshot = await _progressApi.getUserProgress();
        serverXp = snapshot.xpTotal;
        await _cacheBackendProgress(snapshot);
      } catch (e) {
        debugPrint('[BackendProgressService] Unable to fetch server progress before syncing queue: $e');
      }

      final pending = List<_QueuedProgressUpdate>.from(_pendingUpdates);
      for (final update in pending) {
        final expectedXp = update.baselineXp + update.xpGained;

        if (serverXp != null && serverXp >= expectedXp) {
          _pendingUpdates.remove(update);
          debugPrint(
            '[BackendProgressService] Skipping queued update (server XP $serverXp already >= expected $expectedXp)',
          );
          continue;
        }

        try {
          final response = await _progressApi.updateProgress(
            xpGained: update.xpGained,
            lessonId: update.lessonId,
            timeSpentMinutes: update.timeSpentMinutes ?? 1,
            isPerfect: update.isPerfect,
            wordsLearnedCount: update.wordsLearnedCount,
          );

          await _cacheBackendProgress(response);
          _pendingUpdates.remove(update);
          serverXp = response.xpTotal;
          debugPrint(
            '[BackendProgressService] Synced queued progress (${_pendingUpdates.length} remaining)',
          );
        } catch (e) {
          update.retryCount += 1;
          final retryExceeded = update.retryCount >= 8;
          debugPrint(
            '[BackendProgressService] Failed to sync queued progress (retry ${update.retryCount}): $e',
          );
          if (retryExceeded) {
            debugPrint(
              '[BackendProgressService] Dropping queued progress after ${update.retryCount} failed attempts.',
            );
            _pendingUpdates.remove(update);
          }
          break;
        }
      }

      await _persistQueue();
    } finally {
      _queueProcessing = false;
      notifyListeners();
    }
  }

  Future<void> load() async {
    try {
      // Always load local progress first (fast, offline-capable)
      _localProgress = await _localStore.load();
      await _loadQueue();
      _startConnectivityMonitoring();
      _loaded = true;
      notifyListeners();

      // If authenticated, fetch from backend
      if (_isAuthenticated) {
        await _syncFromBackend();
        unawaited(_attemptProcessQueue());
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

      debugPrint(
        '[BackendProgressService] Synced from backend: ${backendData.xpTotal} XP, ${backendData.streakDays} day streak',
      );

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
      // Use local variable to avoid Flutter 3.35+ compiler bug
      final backendProgress = _backendProgress;
      if (localXP > 0 &&
          (backendProgress == null || backendProgress.xpTotal == 0)) {
        debugPrint(
          '[BackendProgressService] Pushing local progress to backend...',
        );
        await _progressApi.updateProgress(
          xpGained: localXP,
          lessonId: 'local_sync',
        );
        await _syncFromBackend();
      }
    } catch (e) {
      debugPrint(
        '[BackendProgressService] Failed to sync local to backend: $e',
      );
    }
  }

  Future<void> _loadQueue() async {
    if (_queueInitialized) {
      return;
    }

    try {
      _queueBox = await Hive.openBox<Map<String, dynamic>>(_queueBoxName);
      // Use local variable to avoid Flutter 3.35+ compiler bug
      final box = _queueBox;
      if (box != null) {
        _pendingUpdates = box.values
            .map(_QueuedProgressUpdate.fromMap)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (_pendingUpdates.isNotEmpty) {
          debugPrint(
            '[BackendProgressService] Loaded ${_pendingUpdates.length} pending progress updates from queue',
          );
        }
      } else {
        debugPrint('[BackendProgressService] Hive box was null after opening, using empty queue');
        _pendingUpdates = [];
      }
      _queueInitialized = true;
    } catch (e) {
      debugPrint('[BackendProgressService] Failed to load progress queue: $e');
      _pendingUpdates = [];
      _queueInitialized = true;
      _queueBox = null; // Ensure it's null on error
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySub ??=
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        unawaited(_attemptProcessQueue());
      }
    });
  }

  Future<List<UserAchievementResponse>> updateProgress({
    required int xpGained,
    required DateTime timestamp,
    bool isPerfect = false,
    int wordsLearnedCount = 0,
    bool countLesson = true,
    String? lessonId,
    int? timeSpentMinutes,
  }) async {
    // Chain updates sequentially
    final previousUpdate = _updateChain;
    final completer = Completer<List<UserAchievementResponse>>();

    _updateChain = previousUpdate.then((_) async {
      try {
        final achievements = await _performUpdate(
          xpGained,
          timestamp,
          isPerfect,
          wordsLearnedCount,
          countLesson,
          lessonId,
          timeSpentMinutes,
        );
        completer.complete(achievements);
      } catch (e) {
        completer.completeError(e);
        rethrow;
      }
    });

    return completer.future;
  }

  Future<List<UserAchievementResponse>> _performUpdate(
    int xpGained,
    DateTime timestamp,
    bool isPerfect,
    int wordsLearnedCount,
    bool countLesson,
    String? lessonId,
    int? timeSpentMinutes,
  ) async {
    final oldLevel = currentLevel;
    List<UserAchievementResponse> newlyUnlocked = [];

    final baselineXp = xpTotal;
    final baselineLessons = totalLessons;
    final baselineStreak = streakDays;

    try {
      if (_isAuthenticated) {
        final updated = await _progressApi.updateProgress(
          xpGained: xpGained,
          lessonId: lessonId,
          timeSpentMinutes: timeSpentMinutes ?? 1,
          isPerfect: isPerfect,
          wordsLearnedCount: wordsLearnedCount,
        );

        newlyUnlocked = updated.newlyUnlockedAchievements ?? [];
        if (newlyUnlocked.isNotEmpty) {
          debugPrint(
            '[BackendProgressService] ${newlyUnlocked.length} achievements unlocked!',
          );
        }

        await _cacheBackendProgress(updated);
        debugPrint(
          '[BackendProgressService] Backend updated: ${updated.xpTotal} XP, ${updated.streakDays} day streak',
        );
      } else {
        await _applyLocalProgress(
          xpGained: xpGained,
          timestamp: timestamp,
          isPerfect: isPerfect,
          wordsLearnedCount: wordsLearnedCount,
          countLesson: countLesson,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[BackendProgressService] Update failed: $e\n$stackTrace');
      if (_isAuthenticated && _shouldQueueError(e)) {
        await _applyLocalProgress(
          xpGained: xpGained,
          timestamp: timestamp,
          isPerfect: isPerfect,
          wordsLearnedCount: wordsLearnedCount,
          countLesson: countLesson,
        );
        await _enqueueProgressUpdate(
          xpGained: xpGained,
          timestamp: timestamp,
          isPerfect: isPerfect,
          wordsLearnedCount: wordsLearnedCount,
          countLesson: countLesson,
          lessonId: lessonId,
          timeSpentMinutes: timeSpentMinutes,
          baselineXp: baselineXp,
          baselineLessons: baselineLessons,
          baselineStreak: baselineStreak,
        );
        unawaited(_attemptProcessQueue());
      } else {
        rethrow;
      }
    }

    notifyListeners();

    final newLevel = currentLevel;
    if (newLevel > oldLevel) {
      debugPrint('[BackendProgressService] Level up! $oldLevel -> $newLevel');
      _levelUpController.add(LevelUpEvent(
        oldLevel: oldLevel,
        newLevel: newLevel,
        timestamp: DateTime.now(),
      ));
    }

    return newlyUnlocked;
  }

  Future<void> processPendingQueue({bool force = false}) async {
    if (force) {
      await _loadQueue();
      await _processQueueInternal();
    } else {
      await _attemptProcessQueue();
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
    // Use local variable to avoid Flutter 3.35+ null check compiler bug
    final box = _queueBox;
    if (box != null) {
      await box.clear();
    }
    _pendingUpdates.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _levelUpController.close();
    super.dispose();
  }
}

class _QueuedProgressUpdate {
  _QueuedProgressUpdate({
    required this.id,
    required this.xpGained,
    required this.timestamp,
    required this.isPerfect,
    required this.wordsLearnedCount,
    required this.countLesson,
    required this.baselineXp,
    required this.baselineLessons,
    required this.baselineStreak,
    this.lessonId,
    this.timeSpentMinutes,
    this.retryCount = 0,
  });

  final String id;
  final int xpGained;
  final DateTime timestamp;
  final bool isPerfect;
  final int wordsLearnedCount;
  final bool countLesson;
  final int baselineXp;
  final int baselineLessons;
  final int baselineStreak;
  final String? lessonId;
  final int? timeSpentMinutes;
  int retryCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'xp_gained': xpGained,
      'timestamp': timestamp.toIso8601String(),
      'is_perfect': isPerfect,
      'words_learned_count': wordsLearnedCount,
      'count_lesson': countLesson,
      'baseline_xp': baselineXp,
      'baseline_lessons': baselineLessons,
      'baseline_streak': baselineStreak,
      'lesson_id': lessonId,
      'time_spent_minutes': timeSpentMinutes,
      'retry_count': retryCount,
    };
  }

  static _QueuedProgressUpdate fromMap(Map<String, dynamic> map) {
    return _QueuedProgressUpdate(
      id: map['id'] as String,
      xpGained: map['xp_gained'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isPerfect: map['is_perfect'] as bool? ?? false,
      wordsLearnedCount: map['words_learned_count'] as int? ?? 0,
      countLesson: map['count_lesson'] as bool? ?? true,
      baselineXp: map['baseline_xp'] as int? ?? 0,
      baselineLessons: map['baseline_lessons'] as int? ?? 0,
      baselineStreak: map['baseline_streak'] as int? ?? 0,
      lessonId: map['lesson_id'] as String?,
      timeSpentMinutes: map['time_spent_minutes'] as int?,
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }
}
