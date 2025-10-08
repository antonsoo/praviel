import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// Service for tracking and managing achievements
class AchievementService extends ChangeNotifier {
  static const String _storageKey = 'achievements';

  final List<Achievement> _achievements = [];
  final List<Achievement> _recentlyUnlocked = [];
  bool _loaded = false;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<Achievement> get recentlyUnlocked =>
      List.unmodifiable(_recentlyUnlocked);
  bool get isLoaded => _loaded;

  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;
  int get totalCount => _achievements.length;

  /// Load achievements from storage
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      // Initialize with all available achievements
      _achievements.clear();
      _achievements.addAll(Achievements.all);

      if (jsonString != null) {
        final Map<String, dynamic> data = json.decode(jsonString);

        // Update achievements with saved progress
        for (int i = 0; i < _achievements.length; i++) {
          final achievement = _achievements[i];
          if (data.containsKey(achievement.id)) {
            _achievements[i] = Achievement.fromJson(
              data[achievement.id],
              achievement,
            );
          }
        }
      }

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AchievementService] Failed to load: $e');
      // Initialize with defaults
      _achievements.clear();
      _achievements.addAll(Achievements.all);
      _loaded = true;
      notifyListeners();
    }
  }

  /// Save achievements to storage
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};

      for (final achievement in _achievements) {
        data[achievement.id] = achievement.toJson();
      }

      await prefs.setString(_storageKey, json.encode(data));
    } catch (e) {
      debugPrint('[AchievementService] Failed to save: $e');
    }
  }

  /// Update achievement progress
  Future<void> updateProgress(String achievementId, int progress) async {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return;

    final achievement = _achievements[index];
    if (achievement.isUnlocked) return; // Already unlocked

    final newProgress = progress.clamp(0, achievement.maxProgress);
    final shouldUnlock = newProgress >= achievement.maxProgress;

    _achievements[index] = achievement.copyWith(
      progress: newProgress,
      isUnlocked: shouldUnlock,
      unlockedAt: shouldUnlock ? DateTime.now() : null,
    );

    if (shouldUnlock) {
      _recentlyUnlocked.add(_achievements[index]);
    }

    await _save();
    notifyListeners();
  }

  /// Increment achievement progress by 1
  Future<void> incrementProgress(String achievementId) async {
    final achievement = getAchievement(achievementId);
    if (achievement != null) {
      await updateProgress(achievementId, achievement.progress + 1);
    }
  }

  /// Unlock achievement directly
  Future<void> unlockAchievement(String achievementId) async {
    final achievement = getAchievement(achievementId);
    if (achievement != null && !achievement.isUnlocked) {
      await updateProgress(achievementId, achievement.maxProgress);
    }
  }

  /// Get specific achievement
  Achievement? getAchievement(String achievementId) {
    try {
      return _achievements.firstWhere((a) => a.id == achievementId);
    } catch (e) {
      return null;
    }
  }

  /// Check and update achievements based on user actions
  Future<List<Achievement>> checkAchievements({
    int? totalLessons,
    int? perfectLessons,
    int? streakDays,
    int? wordsLearned,
    int? level,
    bool? isEarlyBird,
    bool? isNightOwl,
    bool? isWeekend,
    Duration? lessonDuration,
    int? translationCount,
  }) async {
    final unlockedThisCheck = <Achievement>[];
    _recentlyUnlocked.clear();

    // First Word - Complete first exercise
    if (totalLessons != null && totalLessons >= 1) {
      final achievement = getAchievement(Achievements.firstWord.id);
      if (achievement != null && !achievement.isUnlocked) {
        await unlockAchievement(Achievements.firstWord.id);
        unlockedThisCheck.add(getAchievement(Achievements.firstWord.id)!);
      }
    }

    // Homer's Student - 5 Iliad lessons
    if (totalLessons != null) {
      await updateProgress(Achievements.homersStudent.id, totalLessons);
      if (totalLessons >= 5) {
        final achievement = getAchievement(Achievements.homersStudent.id);
        if (achievement != null &&
            achievement.isUnlocked &&
            !unlockedThisCheck.contains(achievement)) {
          unlockedThisCheck.add(achievement);
        }
      }
    }

    // Marathon Runner - 30-day streak
    if (streakDays != null) {
      await updateProgress(Achievements.marathonRunner.id, streakDays);
      if (streakDays >= 30) {
        final achievement = getAchievement(Achievements.marathonRunner.id);
        if (achievement != null &&
            achievement.isUnlocked &&
            !unlockedThisCheck.contains(achievement)) {
          unlockedThisCheck.add(achievement);
        }
      }
    }

    // Vocabulary Titan - 100 words
    if (wordsLearned != null) {
      await updateProgress(Achievements.vocabularyTitan.id, wordsLearned);
    }

    // Speed Demon - lesson < 2 minutes
    if (lessonDuration != null && lessonDuration.inSeconds < 120) {
      await unlockAchievement(Achievements.speedDemon.id);
      final achievement = getAchievement(Achievements.speedDemon.id);
      if (achievement != null &&
          achievement.isUnlocked &&
          !unlockedThisCheck.contains(achievement)) {
        unlockedThisCheck.add(achievement);
      }
    }

    // Perfect Scholar - 10 perfect lessons
    if (perfectLessons != null) {
      await updateProgress(Achievements.perfectScholar.id, perfectLessons);
    }

    // Early Bird
    if (isEarlyBird == true) {
      await unlockAchievement(Achievements.earlyBird.id);
    }

    // Night Owl
    if (isNightOwl == true) {
      await unlockAchievement(Achievements.nightOwl.id);
    }

    // Weekend Warrior
    if (isWeekend == true) {
      await incrementProgress(Achievements.weekendWarrior.id);
    }

    // Translation Master
    if (translationCount != null) {
      await updateProgress(Achievements.translationMaster.id, translationCount);
    }

    // Level achievements
    if (level != null) {
      if (level >= 10) {
        await unlockAchievement(Achievements.levelTen.id);
      }
      if (level >= 20) {
        await unlockAchievement(Achievements.levelTwenty.id);
      }
    }

    // Centurion - 100 lessons
    if (totalLessons != null && totalLessons >= 100) {
      await unlockAchievement(Achievements.centurion.id);
    }

    return _recentlyUnlocked;
  }

  /// Clear recently unlocked list
  void clearRecentlyUnlocked() {
    _recentlyUnlocked.clear();
    notifyListeners();
  }

  /// Reset all achievements (for testing)
  Future<void> reset() async {
    _achievements.clear();
    _achievements.addAll(Achievements.all);
    _recentlyUnlocked.clear();
    await _save();
    notifyListeners();
  }
}
