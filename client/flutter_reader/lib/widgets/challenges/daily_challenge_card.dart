import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import 'dart:math' as math;

enum ChallengeDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum ChallengeType {
  translation,
  vocabulary,
  grammar,
  reading,
  listening,
  speaking,
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int xpReward;
  final int coinReward;
  final DateTime expiresAt;
  final bool isCompleted;
  final int currentProgress;
  final int targetProgress;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.xpReward,
    required this.coinReward,
    required this.expiresAt,
    this.isCompleted = false,
    this.currentProgress = 0,
    required this.targetProgress,
  });

  double get progressPercent => targetProgress > 0 ? currentProgress / targetProgress : 0.0;
}

/// Daily challenge card with premium animations and rewards
class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final difficultyColor = _getDifficultyColor(widget.challenge.difficulty);
    final typeIcon = _getTypeIcon(widget.challenge.type);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticService.medium();
        SoundService.instance.tap();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
          decoration: BoxDecoration(
            gradient: widget.challenge.isCompleted
                ? LinearGradient(
                    colors: [
                      Colors.green.shade100.withValues(alpha: 0.3),
                      Colors.green.shade200.withValues(alpha: 0.2),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                      colorScheme.surfaceContainer.withValues(alpha: 0.6),
                    ],
                  ),
            borderRadius: BorderRadius.circular(VibrantRadius.xl),
            border: Border.all(
              color: widget.challenge.isCompleted
                  ? Colors.green.withValues(alpha: 0.5)
                  : difficultyColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: difficultyColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer effect for uncompleted challenges
              if (!widget.challenge.isCompleted)
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(VibrantRadius.xl),
                        child: CustomPaint(
                          painter: _ShimmerPainter(
                            animation: _shimmerController,
                            color: difficultyColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Type icon
                        Container(
                          padding: const EdgeInsets.all(VibrantSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [difficultyColor, difficultyColor.withValues(alpha: 0.6)],
                            ),
                            borderRadius: BorderRadius.circular(VibrantRadius.md),
                          ),
                          child: Icon(typeIcon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: VibrantSpacing.md),
                        // Title and difficulty
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.challenge.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              _DifficultyBadge(difficulty: widget.challenge.difficulty),
                            ],
                          ),
                        ),
                        // Completion checkmark
                        if (widget.challenge.isCompleted)
                          Container(
                            padding: const EdgeInsets.all(VibrantSpacing.xs),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: VibrantSpacing.md),

                    // Description
                    Text(
                      widget.challenge.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: VibrantSpacing.md),

                    // Progress bar
                    if (!widget.challenge.isCompleted) ...[
                      _ProgressIndicator(
                        progress: widget.challenge.progressPercent,
                        current: widget.challenge.currentProgress,
                        target: widget.challenge.targetProgress,
                        color: difficultyColor,
                      ),
                      const SizedBox(height: VibrantSpacing.md),
                    ],

                    // Rewards and timer
                    Row(
                      children: [
                        // XP Reward
                        _RewardChip(
                          icon: Icons.stars_rounded,
                          value: '${widget.challenge.xpReward} XP',
                          color: Colors.amber,
                        ),
                        const SizedBox(width: VibrantSpacing.sm),
                        // Coin Reward
                        _RewardChip(
                          icon: Icons.monetization_on_rounded,
                          value: '${widget.challenge.coinReward}',
                          color: Colors.orange,
                        ),
                        const Spacer(),
                        // Time remaining
                        _TimeRemaining(expiresAt: widget.challenge.expiresAt),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.beginner:
        return Colors.green;
      case ChallengeDifficulty.intermediate:
        return Colors.blue;
      case ChallengeDifficulty.advanced:
        return Colors.purple;
      case ChallengeDifficulty.expert:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.translation:
        return Icons.translate_rounded;
      case ChallengeType.vocabulary:
        return Icons.book_rounded;
      case ChallengeType.grammar:
        return Icons.auto_stories_rounded;
      case ChallengeType.reading:
        return Icons.menu_book_rounded;
      case ChallengeType.listening:
        return Icons.headphones_rounded;
      case ChallengeType.speaking:
        return Icons.mic_rounded;
    }
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final ChallengeDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = difficulty.name[0].toUpperCase() + difficulty.name.substring(1);
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (difficulty) {
      case ChallengeDifficulty.beginner:
        return Colors.green;
      case ChallengeDifficulty.intermediate:
        return Colors.blue;
      case ChallengeDifficulty.advanced:
        return Colors.purple;
      case ChallengeDifficulty.expert:
        return Colors.red;
    }
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.progress,
    required this.current,
    required this.target,
    required this.color,
  });

  final double progress;
  final int current;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$current / $target',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRemaining extends StatelessWidget {
  const _TimeRemaining({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = expiresAt.difference(DateTime.now());
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: hours < 1 ? Colors.red : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${hours}h ${minutes}m',
          style: theme.textTheme.labelSmall?.copyWith(
            color: hours < 1 ? Colors.red : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for shimmer effect
class _ShimmerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _ShimmerPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.0),
          color,
          color.withValues(alpha: 0.0),
        ],
        stops: [
          math.max(0.0, animation.value - 0.3),
          animation.value,
          math.min(1.0, animation.value + 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) => true;
}
