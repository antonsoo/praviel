import 'package:flutter/material.dart';
import 'backend_progress_service.dart';
import 'daily_goal_service.dart';
import 'daily_challenge_service_v2.dart';
import 'combo_service.dart';
import 'power_up_service.dart';
import 'badge_service.dart';
import 'achievement_service.dart';
import 'backend_challenge_service.dart';
import '../api/progress_api.dart';
import '../models/badge.dart';
import '../models/power_up.dart';
import '../models/achievement.dart';
import '../models/daily_challenge.dart';
import '../widgets/badges/badge_widgets.dart';
import '../widgets/gamification/achievement_widgets.dart';
import '../widgets/gamification/celebration_dialog.dart';
import '../widgets/notifications/milestone_notification.dart';

/// Coordinator service that handles all gamification updates after a lesson
class GamificationCoordinator {
  GamificationCoordinator({
    required this.progressService,
    required this.dailyGoalService,
    required this.dailyChallengeService,
    required this.comboService,
    required this.powerUpService,
    required this.badgeService,
    required this.achievementService,
    this.progressApi,
    this.backendChallengeService,
  });

  final BackendProgressService progressService;
  final DailyGoalService dailyGoalService;
  final DailyChallengeServiceV2 dailyChallengeService;
  final ComboService comboService;
  final PowerUpService powerUpService;
  final BadgeService badgeService;
  final AchievementService achievementService;
  final ProgressApi? progressApi;
  final BackendChallengeService? backendChallengeService;

  /// Process a single exercise result
  Future<ExerciseResult> processExercise({
    required BuildContext context,
    required bool isCorrect,
    required int baseXP,
    int wordsLearned = 0,
  }) async {
    if (isCorrect) {
      // Update combo
      comboService.recordCorrect();

      // Apply combo multiplier
      final multiplier = comboService.comboMultiplier;
      final bonusXP = comboService.bonusXP;
      final totalXP = (baseXP * multiplier).round() + bonusXP;

      // Apply power-up multipliers
      final xpBoostActive = powerUpService.isActive(PowerUpType.xpBoost);
      final finalXP = xpBoostActive ? (totalXP * 2).round() : totalXP;

      // Show combo milestone if reached
      if (comboService.isComboMilestone(comboService.currentCombo)) {
        MilestoneNotificationService.showCombo(
          context,
          comboService.currentCombo,
        );
      }

      return ExerciseResult(
        correct: true,
        xpEarned: finalXP,
        comboCount: comboService.currentCombo,
        multiplier: multiplier,
        bonusXP: bonusXP,
      );
    } else {
      // Break combo on wrong answer
      comboService.recordWrong();

      return ExerciseResult(
        correct: false,
        xpEarned: 0,
        comboCount: 0,
        multiplier: 1.0,
        bonusXP: 0,
      );
    }
  }

  /// Process lesson completion - returns newly unlocked badges/achievements
  /// Each sub-system has error recovery to ensure failures don't block others
  Future<CompletionRewards> processLessonCompletion({
    required BuildContext context,
    required int totalXP,
    required int correctCount,
    required int totalQuestions,
    required int wordsLearned,
    required Duration lessonDuration,
    String? lessonId,
  }) async {
    final isPerfect = correctCount == totalQuestions;

    // Track results from each sub-system
    var completedChallenges = <DailyChallenge>[];
    var newAchievements = <Achievement>[];
    var newBadges = <EarnedBadge>[];
    var coinReward = isPerfect ? 25 : 10;

    // Update progress service (CRITICAL - must succeed)
    try {
      await progressService.updateProgress(
        xpGained: totalXP,
        timestamp: DateTime.now(),
        isPerfect: isPerfect,
        wordsLearnedCount: wordsLearned,
      );
    } catch (e) {
      debugPrint('[GamificationCoordinator] CRITICAL: Failed to update progress: $e');
      // This is critical - rethrow to prevent data loss
      rethrow;
    }

    // Sync progress to backend (graceful failure)
    if (progressApi != null) {
      try {
        await progressApi!.updateProgress(
          xpGained: totalXP,
          lessonId: lessonId,
          timeSpentMinutes: lessonDuration.inMinutes,
          isPerfect: isPerfect,
          wordsLearnedCount: wordsLearned,
        );
        debugPrint('[GamificationCoordinator] Progress synced to backend');
      } catch (e) {
        debugPrint('[GamificationCoordinator] Backend sync failed: $e');
        // Continue - will retry on next sync or when online
      }
    }

    // Update daily goal (graceful failure)
    try {
      await dailyGoalService.addProgress(totalXP);

      // Check if daily goal just completed
      if (dailyGoalService.isGoalMet && context.mounted) {
        MilestoneNotificationService.showDailyGoalMet(context);
      }
    } catch (e) {
      debugPrint('[GamificationCoordinator] Failed to update daily goal: $e');
      // Continue - goal will sync later
    }

    // Update daily challenges (graceful failure)
    try {
      completedChallenges = await dailyChallengeService.onLessonCompleted(
        xpEarned: totalXP,
        isPerfect: isPerfect,
        wordsLearned: wordsLearned,
      );
    } catch (e) {
      debugPrint('[GamificationCoordinator] Failed to update challenges: $e');
      // Continue - challenges will sync later
    }

    // Update backend challenges and check for double-or-nothing completion (graceful failure)
    if (backendChallengeService != null) {
      try {
        final result = await backendChallengeService!.onLessonCompleted(
          xpEarned: totalXP,
          isPerfect: isPerfect,
          wordsLearned: wordsLearned,
          timeSpentMinutes: lessonDuration.inMinutes,
          comboAchieved: comboService.maxCombo,
        );

        // Show double-or-nothing completion celebration
        if (result.doubleOrNothingCompleted && result.doubleOrNothingCoinsWon != null) {
          if (context.mounted) {
            MilestoneNotificationService.showDoubleOrNothingComplete(
              context,
              result.doubleOrNothingCoinsWon!,
            );
          }
        }
      } catch (e) {
        debugPrint('[GamificationCoordinator] Failed to update backend challenges: $e');
        // Continue - challenges will sync later
      }
    }

    // Check achievements (graceful failure)
    try {
      newAchievements = await achievementService.checkAchievements(
        totalLessons: progressService.totalLessons,
        perfectLessons: progressService.perfectLessons,
        streakDays: progressService.streakDays,
        wordsLearned: progressService.wordsLearned,
        level: progressService.currentLevel,
      );
    } catch (e) {
      debugPrint('[GamificationCoordinator] Failed to check achievements: $e');
      // Continue - user won't see new achievements but data is safe
    }

    // Check badges (graceful failure)
    try {
      newBadges = await badgeService.checkBadges(
        level: progressService.currentLevel,
        streakDays: progressService.streakDays,
        totalLessons: progressService.totalLessons,
        perfectLessons: progressService.perfectLessons,
        wordsLearned: progressService.wordsLearned,
        maxCombo: comboService.maxCombo,
        lessonDuration: lessonDuration,
        lessonTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[GamificationCoordinator] Failed to check badges: $e');
      // Continue - user won't see new badges but data is safe
    }

    // Award coins for completion (graceful failure)
    // Note: Coins are tracked by backend via challenge completion
    // Local PowerUpService is deprecated in favor of backend coins
    try {
      await powerUpService.addCoins(coinReward);
      debugPrint('[GamificationCoordinator] Coins awarded locally (legacy): $coinReward');
    } catch (e) {
      debugPrint('[GamificationCoordinator] Failed to award coins locally: $e');
      // Continue - backend is source of truth for coins
    }

    // Reset combo for next lesson (always succeeds - local only)
    comboService.reset();

    return CompletionRewards(
      newAchievements: newAchievements,
      newBadges: newBadges,
      coinsEarned: coinReward,
      leveledUp: false, // Will be determined by caller
      completedChallenges: completedChallenges,
    );
  }

  /// Award passive XP (e.g. power-ups) without counting a new lesson.
  Future<void> awardXP(int xp) async {
    if (xp <= 0) {
      return;
    }
    await progressService.updateProgress(
      xpGained: xp,
      timestamp: DateTime.now(),
      countLesson: false,
    );
  }

  /// Show all rewards (badges, achievements, daily challenges)
  Future<void> showRewards({
    required BuildContext context,
    required CompletionRewards rewards,
  }) async {
    // Show completed daily challenges first (most immediate feedback)
    for (final challenge in rewards.completedChallenges) {
      if (context.mounted) {
        showCelebration(
          context,
          coins: challenge.coinReward,
          xp: challenge.xpReward,
          title: '🎉 Challenge Complete!',
          message: challenge.title,
        );
      }
    }

    // Show badge unlocks
    for (final earnedBadge in rewards.newBadges) {
      if (context.mounted) {
        await BadgeUnlockModal.show(context: context, badge: earnedBadge.badge);

        // Award badge rewards
        if (earnedBadge.badge.xpReward > 0) {
          await progressService.updateProgress(
            xpGained: earnedBadge.badge.xpReward,
            timestamp: DateTime.now(),
          );
        }
        if (earnedBadge.badge.coinReward > 0) {
          await powerUpService.addCoins(earnedBadge.badge.coinReward);
        }
      }
    }

    // Show achievement unlocks
    for (final achievement in rewards.newAchievements) {
      if (context.mounted) {
        await AchievementUnlockModal.show(
          context: context,
          achievement: achievement,
        );
      }
    }
  }
}

/// Result of a single exercise
class ExerciseResult {
  const ExerciseResult({
    required this.correct,
    required this.xpEarned,
    required this.comboCount,
    required this.multiplier,
    required this.bonusXP,
  });

  final bool correct;
  final int xpEarned;
  final int comboCount;
  final double multiplier;
  final int bonusXP;
}

/// Rewards from lesson completion
class CompletionRewards {
  const CompletionRewards({
    required this.newAchievements,
    required this.newBadges,
    required this.coinsEarned,
    required this.leveledUp,
    this.completedChallenges = const [],
  });

  final List<Achievement> newAchievements;
  final List<EarnedBadge> newBadges;
  final int coinsEarned;
  final bool leveledUp;
  final List<DailyChallenge> completedChallenges;
}
