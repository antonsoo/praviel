import 'package:flutter/material.dart';
import 'progress_service.dart';
import 'daily_goal_service.dart';
import 'combo_service.dart';
import 'power_up_service.dart';
import 'badge_service.dart';
import 'achievement_service.dart';
import '../models/badge.dart';
import '../models/power_up.dart';
import '../models/achievement.dart';
import '../widgets/badges/badge_widgets.dart';
import '../widgets/gamification/achievement_widgets.dart';
import '../widgets/notifications/milestone_notification.dart';

/// Coordinator service that handles all gamification updates after a lesson
class GamificationCoordinator {
  GamificationCoordinator({
    required this.progressService,
    required this.dailyGoalService,
    required this.comboService,
    required this.powerUpService,
    required this.badgeService,
    required this.achievementService,
  });

  final ProgressService progressService;
  final DailyGoalService dailyGoalService;
  final ComboService comboService;
  final PowerUpService powerUpService;
  final BadgeService badgeService;
  final AchievementService achievementService;

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
  Future<CompletionRewards> processLessonCompletion({
    required BuildContext context,
    required int totalXP,
    required int correctCount,
    required int totalQuestions,
    required int wordsLearned,
    required Duration lessonDuration,
  }) async {
    final isPerfect = correctCount == totalQuestions;

    // Update progress service
    await progressService.updateProgress(
      xpGained: totalXP,
      timestamp: DateTime.now(),
      isPerfect: isPerfect,
      wordsLearnedCount: wordsLearned,
    );

    // Update daily goal
    await dailyGoalService.addProgress(totalXP);

    // Check if daily goal just completed
    if (dailyGoalService.isGoalMet && context.mounted) {
      MilestoneNotificationService.showDailyGoalMet(context);
    }

    // Check achievements
    final newAchievements = await achievementService.checkAchievements(
      totalLessons: progressService.totalLessons,
      perfectLessons: progressService.perfectLessons,
      streakDays: progressService.streakDays,
      wordsLearned: progressService.wordsLearned,
      level: progressService.currentLevel,
    );

    // Check badges
    final newBadges = await badgeService.checkBadges(
      level: progressService.currentLevel,
      streakDays: progressService.streakDays,
      totalLessons: progressService.totalLessons,
      perfectLessons: progressService.perfectLessons,
      wordsLearned: progressService.wordsLearned,
      maxCombo: comboService.maxCombo,
      lessonDuration: lessonDuration,
      lessonTime: DateTime.now(),
    );

    // Award coins for completion
    final coinReward = isPerfect ? 25 : 10;
    await powerUpService.addCoins(coinReward);

    // Reset combo for next lesson
    comboService.reset();

    return CompletionRewards(
      newAchievements: newAchievements,
      newBadges: newBadges,
      coinsEarned: coinReward,
      leveledUp: false, // Will be determined by caller
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

  /// Show all rewards (badges, achievements, etc.)
  Future<void> showRewards({
    required BuildContext context,
    required CompletionRewards rewards,
  }) async {
    // Show badge unlocks first
    for (final earnedBadge in rewards.newBadges) {
      if (context.mounted) {
        await BadgeUnlockModal.show(
          context: context,
          badge: earnedBadge.badge,
        );

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
  });

  final List<Achievement> newAchievements;
  final List<EarnedBadge> newBadges;
  final int coinsEarned;
  final bool leveledUp;
}
