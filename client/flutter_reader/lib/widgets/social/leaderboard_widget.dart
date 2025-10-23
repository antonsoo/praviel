import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

enum LeaderboardScope {
  global,
  friends,
  language,
  weekly,
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String avatarUrl;
  final int score;
  final int rank;
  final String languageCode;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.score,
    required this.rank,
    required this.languageCode,
    this.isCurrentUser = false,
  });
}

/// Professional leaderboard with rankings, medals, and competition
class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.currentUserEntry,
    this.scope = LeaderboardScope.global,
    this.onScopeChanged,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardEntry currentUserEntry;
  final LeaderboardScope scope;
  final Function(LeaderboardScope)? onScopeChanged;

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LeaderboardScope.values.length,
      vsync: this,
      initialIndex: widget.scope.index,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onScopeChanged?.call(LeaderboardScope.values[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Tabs for different scopes
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Global'),
              Tab(text: 'Friends'),
              Tab(text: 'Language'),
              Tab(text: 'This Week'),
            ],
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: VibrantTheme.heroGradient,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
            ),
            dividerColor: Colors.transparent,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            onTap: (_) {
              HapticService.light();
              SoundService.instance.tap();
            },
          ),
        ),

        const SizedBox(height: VibrantSpacing.xl),

        // Top 3 podium
        _PodiumDisplay(
          entries: widget.entries.take(3).toList(),
        ),

        const SizedBox(height: VibrantSpacing.xl),

        // Current user card (if not in top 10)
        if (!widget.entries.take(10).any((e) => e.isCurrentUser)) ...[
          _CurrentUserCard(entry: widget.currentUserEntry),
          const SizedBox(height: VibrantSpacing.md),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: VibrantSpacing.md),
        ],

        // Rest of the leaderboard
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: VibrantSpacing.xl),
            itemCount: widget.entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: VibrantSpacing.sm),
            itemBuilder: (context, index) {
              final entry = widget.entries[index];
              return _LeaderboardListItem(
                entry: entry,
                showMedal: index < 3,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Podium display for top 3
class _PodiumDisplay extends StatelessWidget {
  const _PodiumDisplay({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Arrange as: 2nd, 1st, 3rd
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (second != null)
          _PodiumItem(
            entry: second,
            height: 100,
            color: Colors.grey.shade400,
            medal: '🥈',
          ),

        const SizedBox(width: VibrantSpacing.sm),

        // 1st place (tallest)
        if (first != null)
          _PodiumItem(
            entry: first,
            height: 140,
            color: Colors.amber,
            medal: '🥇',
          ),

        const SizedBox(width: VibrantSpacing.sm),

        // 3rd place
        if (third != null)
          _PodiumItem(
            entry: third,
            height: 80,
            color: const Color(0xFFCD7F32), // Bronze
            medal: '🥉',
          ),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.entry,
    required this.height,
    required this.color,
    required this.medal,
  });

  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final String medal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Avatar with medal
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(entry.avatarUrl),
                onBackgroundImageError: (_, _) {},
                child: entry.avatarUrl.isEmpty
                    ? Text(entry.username[0].toUpperCase())
                    : null,
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Text(medal, style: const TextStyle(fontSize: 24)),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Text(
          entry.username,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: VibrantSpacing.xs),
        // Podium
        Container(
          width: 72,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.md),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${entry.rank}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${entry.score} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Current user highlight card
class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: VibrantSpacing.md),
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(entry.avatarUrl),
            onBackgroundImageError: (_, _) {},
          ),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      ),
                      child: Text(
                        'You',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${entry.score} XP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events_rounded,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

/// Individual leaderboard list item
class _LeaderboardListItem extends StatelessWidget {
  const _LeaderboardListItem({
    required this.entry,
    required this.showMedal,
  });

  final LeaderboardEntry entry;
  final bool showMedal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        border: entry.isCurrentUser
            ? Border.all(color: colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              showMedal ? _getMedal(entry.rank) : '#${entry.rank}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: showMedal ? 24 : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: VibrantSpacing.md),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(entry.avatarUrl),
            onBackgroundImageError: (_, _) {},
          ),
          const SizedBox(width: VibrantSpacing.md),
          // Username
          Expanded(
            child: Text(
              entry.username,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          // Score
          Text(
            '${entry.score}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            'XP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getMedal(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}
