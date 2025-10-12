import 'dart:async';
import 'package:flutter/material.dart';
import '../effects/epic_celebration.dart';

/// Show an epic celebration when the learner extends their streak.
Future<void> showStreakCelebration(
  BuildContext context, {
  required int streakDays,
  bool isMilestone = false,
  bool isNewRecord = false,
}) async {
  final overlay = Overlay.of(context);

  final message = isNewRecord
      ? 'New record! $streakDays-day streak!'
      : isMilestone
      ? 'Milestone unlocked: $streakDays-day streak!'
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
