import 'dart:async';
import 'package:flutter/material.dart';
import '../effects/epic_celebration.dart';

/// Detect if streak is a milestone (3, 7, 14, 30, 50, 100, 365 days)
bool _isStreakMilestone(int streakDays) {
  const milestones = [3, 7, 14, 30, 50, 100, 365];
  return milestones.contains(streakDays);
}

/// Get milestone-specific message
String _getMilestoneMessage(int streakDays) {
  switch (streakDays) {
    case 3:
      return '🔥 3-day streak! Building momentum!';
    case 7:
      return '✨ 1 WEEK STREAK! You\'re on fire!';
    case 14:
      return '🚀 2 WEEK STREAK! Unstoppable!';
    case 30:
      return '🏆 1 MONTH STREAK! Legendary dedication!';
    case 50:
      return '💎 50-DAY STREAK! Diamond commitment!';
    case 100:
      return '👑 100-DAY STREAK! You\'re a champion!';
    case 365:
      return '🌟 1 YEAR STREAK! MASTER ACHIEVEMENT!';
    default:
      return 'Milestone unlocked: $streakDays-day streak!';
  }
}

/// Show an epic celebration when the learner extends their streak.
/// Auto-detects milestones (3, 7, 14, 30, 50, 100, 365 days)
Future<void> showStreakCelebration(
  BuildContext context, {
  required int streakDays,
  bool isMilestone = false,
  bool isNewRecord = false,
}) async {
  final overlay = Overlay.of(context);

  // Auto-detect milestone if not explicitly set
  final autoMilestone = isMilestone || _isStreakMilestone(streakDays);

  final message = isNewRecord
      ? 'New record! $streakDays-day streak!'
      : autoMilestone
      ? _getMilestoneMessage(streakDays)
      : '🔥 $streakDays-day streak!';

  final completer = Completer<void>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: EpicCelebration(
        type: CelebrationType.streakMilestone,
        message: message,
        onComplete: () {
          if (entry.mounted) {
            entry.remove();
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    ),
  );

  overlay.insert(entry);

  // Fallback - ensure overlay is removed even if onComplete is not triggered
  Future.delayed(const Duration(seconds: 6), () {
    if (!completer.isCompleted) {
      if (entry.mounted) {
        entry.remove();
      }
      completer.complete();
    }
  });

  return completer.future;
}
