import 'package:flutter/material.dart';

/// Duolingo-style progress bar for lessons
/// Shows progress through tasks with smooth animation
class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.height = 12,
  });

  final int current;
  final int total;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          children: [
            // Background
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            // Animated progress
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
