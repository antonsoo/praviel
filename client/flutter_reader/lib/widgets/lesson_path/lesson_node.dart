import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

/// Status of a lesson node
enum LessonNodeStatus { locked, unlocked, inProgress, completed, perfect }

/// Individual lesson node in the skill tree
class LessonNode extends StatefulWidget {
  const LessonNode({
    super.key,
    required this.title,
    required this.status,
    required this.onTap,
    this.lessonNumber,
    this.xpReward = 0,
    this.isCurrentPosition = false,
  });

  final String title;
  final LessonNodeStatus status;
  final VoidCallback onTap;
  final int? lessonNumber;
  final int xpReward;
  final bool isCurrentPosition; // Character is here

  @override
  State<LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<LessonNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Pulse if unlocked or current position
    if (widget.status == LessonNodeStatus.unlocked ||
        widget.isCurrentPosition) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LessonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status ||
        widget.isCurrentPosition != oldWidget.isCurrentPosition) {
      if (widget.status == LessonNodeStatus.unlocked ||
          widget.isCurrentPosition) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getNodeColor(ColorScheme colorScheme) {
    switch (widget.status) {
      case LessonNodeStatus.locked:
        return colorScheme.surfaceContainerHighest;
      case LessonNodeStatus.unlocked:
        return const Color(0xFF7C3AED); // Purple
      case LessonNodeStatus.inProgress:
        return const Color(0xFFF59E0B); // Amber
      case LessonNodeStatus.completed:
        return const Color(0xFF3B82F6); // Blue
      case LessonNodeStatus.perfect:
        return const Color(0xFF10B981); // Green
    }
  }

  IconData _getNodeIcon() {
    switch (widget.status) {
      case LessonNodeStatus.locked:
        return Icons.lock_rounded;
      case LessonNodeStatus.unlocked:
        return Icons.play_circle_filled_rounded;
      case LessonNodeStatus.inProgress:
        return Icons.pending_rounded;
      case LessonNodeStatus.completed:
        return Icons.check_circle_rounded;
      case LessonNodeStatus.perfect:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nodeColor = _getNodeColor(colorScheme);
    final isInteractive =
        widget.status != LessonNodeStatus.locked || widget.isCurrentPosition;

    return GestureDetector(
      onTap: () {
        if (isInteractive) {
          HapticService.light();
          SoundService.instance.tap();
          widget.onTap();
        } else {
          HapticService.error();
          SoundService.instance.locked();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Node circle
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = isInteractive
                  ? 1.0 + (_pulseController.value * 0.1)
                  : 1.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeColor,
                    border: widget.isCurrentPosition
                        ? Border.all(color: Colors.white, width: 4)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: nodeColor.withValues(alpha: 0.4),
                        blurRadius: widget.isCurrentPosition ? 20 : 12,
                        spreadRadius: widget.isCurrentPosition ? 4 : 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Icon
                      Center(
                        child: Icon(
                          _getNodeIcon(),
                          color: widget.status == LessonNodeStatus.locked
                              ? colorScheme.onSurfaceVariant
                              : Colors.white,
                          size: 32,
                        ),
                      ),

                      // Lesson number badge
                      if (widget.lessonNumber != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.lessonNumber}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: nodeColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),

                      // Perfect star overlay
                      if (widget.status == LessonNodeStatus.perfect)
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFBBF24),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: VibrantSpacing.sm),

          // Title
          SizedBox(
            width: 100,
            child: Text(
              widget.title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.status == LessonNodeStatus.locked
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // XP reward
          if (widget.xpReward > 0 &&
              widget.status != LessonNodeStatus.completed &&
              widget.status != LessonNodeStatus.perfect)
            Container(
              margin: const EdgeInsets.only(top: VibrantSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                gradient: VibrantTheme.xpGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${widget.xpReward} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Path connector between nodes
class PathConnector extends StatelessWidget {
  const PathConnector({
    super.key,
    required this.isCompleted,
    this.isVertical = true,
    this.length = 60,
  });

  final bool isCompleted;
  final bool isVertical;
  final double length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: isVertical ? 4 : length,
      height: isVertical ? length : 4,
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
                end: isVertical
                    ? Alignment.bottomCenter
                    : Alignment.centerRight,
                colors: [const Color(0xFF10B981), const Color(0xFF3B82F6)],
              )
            : null,
        color: isCompleted ? null : colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
