import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_challenge.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../app_providers.dart';
import 'dart:math' as math;

/// Daily challenges card for home screen
class DailyChallengesCard extends ConsumerWidget {
  const DailyChallengesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeServiceAsync = ref.watch(dailyChallengeServiceProvider);

    return challengeServiceAsync.when(
      data: (service) {
        final challenges = service.activeChallenges;

        // Show error message if there was a loading error
        if (service.lastError != null && challenges.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(service.lastError!),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => service.refresh(),
                ),
              ),
            );
          });
        }

        if (challenges.isEmpty) {
          return const SizedBox.shrink();
        }

        return _DailyChallengesCardContent(challenges: challenges);
      },
      loading: () => const _LoadingCard(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _DailyChallengesCardContent extends StatelessWidget {
  const _DailyChallengesCardContent({required this.challenges});

  final List<DailyChallenge> challenges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        boxShadow: VibrantShadow.lg(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: VibrantTheme.heroGradient,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Challenges',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${challenges.where((c) => c.isCompleted).length}/${challenges.length} completed',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Time remaining
                _TimeRemainingBadge(expiresAt: challenges.first.expiresAt),
              ],
            ),
          ),

          // Challenges list
          ...challenges.map(
            (challenge) => _ChallengeItem(challenge: challenge),
          ),

          const SizedBox(height: VibrantSpacing.sm),
        ],
      ),
    );
  }
}

class _ChallengeItem extends StatelessWidget {
  const _ChallengeItem({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: challenge.isCompleted
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: challenge.isCompleted
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: challenge.isCompleted
                      ? VibrantTheme.successGradient
                      : LinearGradient(
                          colors: [
                            challenge.difficultyColor,
                            challenge.difficultyColor.withValues(alpha: 0.7),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(VibrantRadius.sm),
                ),
                child: Icon(
                  challenge.isCompleted
                      ? Icons.check_circle_rounded
                      : challenge.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: challenge.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: challenge.difficultyColor.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(
                              VibrantRadius.sm,
                            ),
                          ),
                          child: Text(
                            challenge.difficultyLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: challenge.difficultyColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.xxs),
                    Text(
                      challenge.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),

          // Progress bar
          if (!challenge.isCompleted) ...[
            SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: challenge.progressPercentage,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            challenge.difficultyColor,
                            challenge.difficultyColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VibrantSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${challenge.currentProgress}/${challenge.targetValue}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.coinReward}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFFFD700),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.xpReward}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else
            // Completed state
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: VibrantSpacing.xs),
                Text(
                  'Completed!',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '+${challenge.coinReward} coins, +${challenge.xpReward} XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimeRemainingBadge extends StatefulWidget {
  const _TimeRemainingBadge({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_TimeRemainingBadge> createState() => _TimeRemainingBadgeState();
}

class _TimeRemainingBadgeState extends State<_TimeRemainingBadge> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update every minute
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = widget.expiresAt.difference(DateTime.now());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: hours < 3
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
        border: Border.all(
          color: hours < 3 ? Colors.red : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: hours < 3 ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '${hours}h ${minutes}m',
            style: theme.textTheme.labelSmall?.copyWith(
              color: hours < 3 ? Colors.red : Colors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(VibrantSpacing.md),
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Animated celebration when challenge is completed
class ChallengeCelebration extends StatefulWidget {
  const ChallengeCelebration({super.key, required this.challenge});

  final DailyChallenge challenge;

  @override
  State<ChallengeCelebration> createState() => _ChallengeCelebrationState();
}

class _ChallengeCelebrationState extends State<ChallengeCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.slow,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: VibrantCurve.bounceIn),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(VibrantSpacing.xl),
                decoration: BoxDecoration(
                  gradient: VibrantTheme.successGradient,
                  borderRadius: BorderRadius.circular(VibrantRadius.xxl),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    Text(
                      'Challenge Complete!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      widget.challenge.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(VibrantRadius.lg),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: VibrantSpacing.xs),
                          Text(
                            '+${widget.challenge.coinReward}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: VibrantSpacing.lg),
                          Icon(Icons.star_rounded, color: Colors.white),
                          const SizedBox(width: VibrantSpacing.xs),
                          Text(
                            '+${widget.challenge.xpReward}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorScheme.primary,
                      ),
                      child: const Text('Awesome!'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
