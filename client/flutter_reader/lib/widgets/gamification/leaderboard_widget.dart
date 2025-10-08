import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';

/// User entry for leaderboard
class LeaderboardUser {
  const LeaderboardUser({
    required this.name,
    required this.xp,
    required this.level,
    required this.rank,
    this.isCurrentUser = false,
    this.avatarUrl,
  });

  final String name;
  final int xp;
  final int level;
  final int rank;
  final bool isCurrentUser;
  final String? avatarUrl;
}

/// Leaderboard widget showing top learners
class LeaderboardWidget extends StatelessWidget {
  const LeaderboardWidget({
    required this.users,
    this.title = 'Leaderboard',
    this.onUserTap,
    super.key,
  });

  final List<LeaderboardUser> users;
  final String title;
  final Function(LeaderboardUser)? onUserTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        // Top 3 podium
        if (users.length >= 3)
          _buildPodium(users.take(3).toList(), theme, colorScheme),
        const SizedBox(height: VibrantSpacing.lg),
        // Remaining users list
        if (users.length > 3)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length - 3,
            itemBuilder: (context, index) {
              final user = users[index + 3];
              return _LeaderboardListItem(
                user: user,
                onTap: onUserTap != null ? () => onUserTap!(user) : null,
              );
            },
          ),
      ],
    );
  }

  Widget _buildPodium(
    List<LeaderboardUser> topThree,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Reorder: 2nd, 1st, 3rd for visual podium effect
    final reordered = [
      if (topThree.length > 1) topThree[1], // 2nd place
      topThree[0], // 1st place
      if (topThree.length > 2) topThree[2], // 3rd place
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: reordered.asMap().entries.map((entry) {
          final visualIndex = entry.key;
          final user = entry.value;
          final actualRank = user.rank;

          // Heights: 2nd=80, 1st=100, 3rd=60
          final height = visualIndex == 1
              ? 100.0
              : visualIndex == 0
                  ? 80.0
                  : 60.0;

          return Expanded(
            child: _PodiumPlace(
              user: user,
              height: height,
              isFirst: actualRank == 1,
              accent: colorScheme,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Podium place widget (top 3)
class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.user,
    required this.height,
    required this.isFirst,
    required this.accent,
  });

  final LeaderboardUser user;
  final double height;
  final bool isFirst;
  final ColorScheme accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = accent;

    final Color medalColor;
    switch (user.rank) {
      case 1:
        medalColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        medalColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        medalColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        medalColor = colorScheme.primary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with rank badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: isFirst ? 64 : 56,
              height: isFirst ? 64 : 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    medalColor,
                    medalColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: VibrantShadow.md(colorScheme),
              ),
              child: Center(
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: medalColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user.rank.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.sm),
        // Name
        Text(
          user.name,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        // Level
        Text(
          'Lvl ${user.level}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VibrantSpacing.sm),
        // Podium base
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                medalColor.withValues(alpha: 0.3),
                medalColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.md),
            ),
            border: Border.all(
              color: medalColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${user.xp}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: medalColor,
                  ),
                ),
                Text(
                  'XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// List item for ranks 4+
class _LeaderboardListItem extends StatelessWidget {
  const _LeaderboardListItem({
    required this.user,
    this.onTap,
  });

  final LeaderboardUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedScaleButton(
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.xs,
        ),
        padding: const EdgeInsets.all(VibrantSpacing.md),
        decoration: BoxDecoration(
          color: user.isCurrentUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VibrantRadius.md),
          border: user.isCurrentUser
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Rank number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VibrantRadius.sm),
              ),
              child: Center(
                child: Text(
                  '#${user.rank}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: VibrantTheme.heroGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: VibrantSpacing.md),
            // Name & Level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Level ${user.level}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // XP
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.xp}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact leaderboard card for dashboard
class CompactLeaderboard extends StatelessWidget {
  const CompactLeaderboard({
    required this.users,
    this.onViewAll,
    super.key,
  });

  final List<LeaderboardUser> users;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: const Color(0xFFFFA500),
                    size: 20,
                  ),
                  const SizedBox(width: VibrantSpacing.xs),
                  Text(
                    'Leaderboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          ...users.take(5).map((user) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              child: Row(
                children: [
                  Text(
                    '#${user.rank}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.md),
                  Expanded(
                    child: Text(
                      user.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: user.isCurrentUser
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${user.xp} XP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
