import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/badge.dart';

/// Service for managing badges and medals
class BadgeService extends ChangeNotifier {
  static const String _earnedBadgesKey = 'earned_badges';

  final List<EarnedBadge> _earnedBadges = [];
  bool _loaded = false;

  List<EarnedBadge> get earnedBadges => List.unmodifiable(_earnedBadges);
  bool get isLoaded => _loaded;

  /// Get all completed badges
  List<EarnedBadge> get completedBadges =>
      _earnedBadges.where((b) => b.isCompleted).toList();

  /// Get badges in progress
  List<EarnedBadge> get inProgressBadges =>
      _earnedBadges.where((b) => !b.isCompleted).toList();

  /// Get total badge count
  int get totalBadges => completedBadges.length;

  /// Get badge completion percentage
  double get completionPercentage {
    final total = Badge.all.where((b) => !b.isSecret).length;
    return totalBadges / total;
  }

  /// Load earned badges
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_earnedBadgesKey);

      if (json != null) {
        final List decoded = jsonDecode(json);
        _earnedBadges.clear();
        _earnedBadges.addAll(
          decoded.map((item) => EarnedBadge.fromJson(item)),
        );
      }

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[BadgeService] Failed to load: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  /// Check if user has earned a badge
  bool hasBadge(String badgeId) {
    return _earnedBadges.any((b) => b.badge.id == badgeId && b.isCompleted);
  }

  /// Get earned badge by ID
  EarnedBadge? getEarnedBadge(String badgeId) {
    try {
      return _earnedBadges.firstWhere((b) => b.badge.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  /// Award a badge to user
  Future<EarnedBadge?> awardBadge(Badge badge) async {
    // Check if already earned
    if (hasBadge(badge.id)) {
      return null;
    }

    final earnedBadge = EarnedBadge(
      badge: badge,
      earnedAt: DateTime.now(),
    );

    _earnedBadges.add(earnedBadge);
    await _save();
    notifyListeners();

    return earnedBadge;
  }

  /// Update badge progress
  Future<void> updateProgress(String badgeId, double progress) async {
    final index = _earnedBadges.indexWhere((b) => b.badge.id == badgeId);

    if (index != -1) {
      final existing = _earnedBadges[index];
      _earnedBadges[index] = EarnedBadge(
        badge: existing.badge,
        earnedAt: existing.earnedAt,
        progress: progress.clamp(0.0, 1.0),
      );
    } else {
      // Create new progress entry
      final badge = Badge.all.firstWhere((b) => b.id == badgeId);
      _earnedBadges.add(EarnedBadge(
        badge: badge,
        earnedAt: DateTime.now(),
        progress: progress.clamp(0.0, 1.0),
      ));
    }

    await _save();
    notifyListeners();
  }

  /// Check and award badges based on user stats
  Future<List<EarnedBadge>> checkBadges({
    int? level,
    int? streakDays,
    int? totalLessons,
    int? perfectLessons,
    int? wordsLearned,
    int? maxCombo,
    int? friends,
    int? leaderboardRank,
    Duration? lessonDuration,
    DateTime? lessonTime,
  }) async {
    final newBadges = <EarnedBadge>[];

    // Level milestones
    if (level != null) {
      if (level >= 100 && !hasBadge('level_100')) {
        final badge = await awardBadge(Badge.level100);
        if (badge != null) newBadges.add(badge);
      } else if (level >= 50 && !hasBadge('level_50')) {
        final badge = await awardBadge(Badge.level50);
        if (badge != null) newBadges.add(badge);
      } else if (level >= 25 && !hasBadge('level_25')) {
        final badge = await awardBadge(Badge.level25);
        if (badge != null) newBadges.add(badge);
      } else if (level >= 10 && !hasBadge('level_10')) {
        final badge = await awardBadge(Badge.level10);
        if (badge != null) newBadges.add(badge);
      }
    }

    // Streak milestones
    if (streakDays != null) {
      if (streakDays >= 100 && !hasBadge('streak_100')) {
        final badge = await awardBadge(Badge.streak100);
        if (badge != null) newBadges.add(badge);
      } else if (streakDays >= 30 && !hasBadge('streak_30')) {
        final badge = await awardBadge(Badge.streak30);
        if (badge != null) newBadges.add(badge);
      } else if (streakDays >= 7 && !hasBadge('streak_7')) {
        final badge = await awardBadge(Badge.streak7);
        if (badge != null) newBadges.add(badge);
      }
    }

    // First lesson
    if (totalLessons != null && totalLessons >= 1 && !hasBadge('first_lesson')) {
      final badge = await awardBadge(Badge.firstLesson);
      if (badge != null) newBadges.add(badge);
    }

    // Combo achievements
    if (maxCombo != null && maxCombo >= 50 && !hasBadge('combo_king')) {
      final badge = await awardBadge(Badge.comboKing);
      if (badge != null) newBadges.add(badge);
    }

    // Vocabulary mastery
    if (wordsLearned != null && wordsLearned >= 1000 && !hasBadge('vocabulary_master')) {
      final badge = await awardBadge(Badge.vocabularyMaster);
      if (badge != null) newBadges.add(badge);
    }

    // Speed demon
    if (lessonDuration != null && lessonDuration.inSeconds < 60 && !hasBadge('speed_demon')) {
      final badge = await awardBadge(Badge.speedDemon);
      if (badge != null) newBadges.add(badge);
    }

    // Time-based badges
    if (lessonTime != null) {
      final hour = lessonTime.hour;

      // Night owl (midnight: 11 PM - 1 AM)
      if ((hour >= 23 || hour <= 1) && !hasBadge('night_owl')) {
        // Track midnight lessons count
        await updateProgress('night_owl', (getEarnedBadge('night_owl')?.progress ?? 0) + 0.2);
        if (getEarnedBadge('night_owl')?.progress == 1.0) {
          final badge = await awardBadge(Badge.nightOwl);
          if (badge != null) newBadges.add(badge);
        }
      }

      // Early bird (sunrise: 5-7 AM)
      if (hour >= 5 && hour <= 7 && !hasBadge('early_bird')) {
        await updateProgress('early_bird', (getEarnedBadge('early_bird')?.progress ?? 0) + 0.2);
        if (getEarnedBadge('early_bird')?.progress == 1.0) {
          final badge = await awardBadge(Badge.earlyBird);
          if (badge != null) newBadges.add(badge);
        }
      }
    }

    // Social badges
    if (friends != null && friends >= 10 && !hasBadge('social_butterfly')) {
      final badge = await awardBadge(Badge.socialButterfly);
      if (badge != null) newBadges.add(badge);
    }

    // Leaderboard badges
    if (leaderboardRank != null) {
      if (leaderboardRank == 1 && !hasBadge('champion')) {
        final badge = await awardBadge(Badge.champion);
        if (badge != null) newBadges.add(badge);
      } else if (leaderboardRank <= 10 && !hasBadge('competitor')) {
        final badge = await awardBadge(Badge.competitor);
        if (badge != null) newBadges.add(badge);
      }
    }

    return newBadges;
  }

  /// Get badges by type
  List<EarnedBadge> getBadgesByType(BadgeType type) {
    return _earnedBadges
        .where((b) => b.badge.type == type && b.isCompleted)
        .toList();
  }

  /// Get badges by rarity
  List<EarnedBadge> getBadgesByRarity(BadgeRarity rarity) {
    return _earnedBadges
        .where((b) => b.badge.rarity == rarity && b.isCompleted)
        .toList();
  }

  /// Get display badges (hide secret badges until earned)
  List<Badge> getDisplayBadges() {
    return Badge.all.where((badge) {
      if (badge.isSecret && !hasBadge(badge.id)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_earnedBadges.map((b) => b.toJson()).toList());
      await prefs.setString(_earnedBadgesKey, json);
    } catch (e) {
      debugPrint('[BadgeService] Failed to save: $e');
    }
  }

  Future<void> reset() async {
    _earnedBadges.clear();
    await _save();
    notifyListeners();
  }
}
