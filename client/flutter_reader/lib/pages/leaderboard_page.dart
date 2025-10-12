import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../api/leaderboard_api.dart';
import '../theme/vibrant_theme.dart';

/// Leaderboard page showing competitive rankings
class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardResponse? _globalLeaderboard;
  LeaderboardResponse? _friendsLeaderboard;
  LeaderboardResponse? _localLeaderboard;
  bool _loadingGlobal = false;
  bool _loadingFriends = false;
  bool _loadingLocal = false;
  String? _errorGlobal;
  String? _errorFriends;
  String? _errorLocal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadCurrentTab();
      }
    });
    _loadCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentTab() {
    switch (_tabController.index) {
      case 0:
        if (_globalLeaderboard == null) _loadGlobal();
        break;
      case 1:
        if (_friendsLeaderboard == null) _loadFriends();
        break;
      case 2:
        if (_localLeaderboard == null) _loadLocal();
        break;
    }
  }

  Future<void> _loadGlobal() async {
    setState(() {
      _loadingGlobal = true;
      _errorGlobal = null;
    });

    try {
      final api = ref.read(leaderboardApiProvider);
      final leaderboard = await api.getGlobalLeaderboard(limit: 100);
      if (mounted) {
        setState(() {
          _globalLeaderboard = leaderboard;
          _loadingGlobal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorGlobal = e.toString();
          _loadingGlobal = false;
        });
      }
    }
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loadingFriends = true;
      _errorFriends = null;
    });

    try {
      final api = ref.read(leaderboardApiProvider);
      final leaderboard = await api.getFriendsLeaderboard(limit: 100);
      if (mounted) {
        setState(() {
          _friendsLeaderboard = leaderboard;
          _loadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorFriends = e.toString();
          _loadingFriends = false;
        });
      }
    }
  }

  Future<void> _loadLocal() async {
    setState(() {
      _loadingLocal = true;
      _errorLocal = null;
    });

    try {
      final api = ref.read(leaderboardApiProvider);
      final leaderboard = await api.getLocalLeaderboard(limit: 100);
      if (mounted) {
        setState(() {
          _localLeaderboard = leaderboard;
          _loadingLocal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLocal = e.toString();
          _loadingLocal = false;
        });
      }
    }
  }

  Future<void> _refreshCurrentTab() async {
    switch (_tabController.index) {
      case 0:
        await _loadGlobal();
        break;
      case 1:
        await _loadFriends();
        break;
      case 2:
        await _loadLocal();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global', icon: Icon(Icons.public_rounded)),
            Tab(text: 'Friends', icon: Icon(Icons.people_rounded)),
            Tab(text: 'Local', icon: Icon(Icons.location_on_rounded)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshCurrentTab,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(
            _globalLeaderboard,
            _loadingGlobal,
            _errorGlobal,
            _loadGlobal,
            'Global',
          ),
          _buildLeaderboardTab(
            _friendsLeaderboard,
            _loadingFriends,
            _errorFriends,
            _loadFriends,
            'Friends',
          ),
          _buildLeaderboardTab(
            _localLeaderboard,
            _loadingLocal,
            _errorLocal,
            _loadLocal,
            'Local',
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(
    LeaderboardResponse? leaderboard,
    bool loading,
    String? error,
    VoidCallback onRetry,
    String boardName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: VibrantSpacing.lg),
              Text(
                'Failed to load $boardName leaderboard',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VibrantSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (leaderboard == null || leaderboard.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'No rankings yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              boardName == 'Friends'
                  ? 'Add friends to compete!'
                  : 'Complete lessons to appear on the leaderboard!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: CustomScrollView(
        slivers: [
          // Current user rank card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(VibrantSpacing.lg),
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              decoration: BoxDecoration(
                gradient: VibrantTheme.heroGradient,
                borderRadius: BorderRadius.circular(VibrantRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Your Rank',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.sm),
                  Text(
                    '#${leaderboard.currentUserRank}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    'out of ${leaderboard.totalUsers} users',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top 3 podium
          if (leaderboard.users.length >= 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.lg,
                  vertical: VibrantSpacing.md,
                ),
                child: _buildPodium(leaderboard.users, theme, colorScheme),
              ),
            ),

          // All rankings
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              VibrantSpacing.lg,
              VibrantSpacing.md,
              VibrantSpacing.lg,
              VibrantSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = leaderboard.users[index];
                  return _buildLeaderboardEntry(entry, theme, colorScheme);
                },
                childCount: leaderboard.users.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(
    List<LeaderboardEntry> users,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (second != null)
          Expanded(
            child: _buildPodiumPlace(
              second,
              2,
              Colors.grey.shade400,
              100,
              theme,
              colorScheme,
            ),
          ),
        const SizedBox(width: VibrantSpacing.sm),
        // 1st place (tallest)
        if (first != null)
          Expanded(
            child: _buildPodiumPlace(
              first,
              1,
              const Color(0xFFFFD700),
              130,
              theme,
              colorScheme,
            ),
          ),
        const SizedBox(width: VibrantSpacing.sm),
        // 3rd place
        if (third != null)
          Expanded(
            child: _buildPodiumPlace(
              third,
              3,
              Colors.brown.shade400,
              80,
              theme,
              colorScheme,
            ),
          ),
      ],
    );
  }

  Widget _buildPodiumPlace(
    LeaderboardEntry entry,
    int place,
    Color medalColor,
    double height,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final icon = place == 1
        ? Icons.emoji_events_rounded
        : place == 2
            ? Icons.looks_two_rounded
            : Icons.looks_3_rounded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                medalColor,
                medalColor.withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: VibrantSpacing.sm),
        Text(
          entry.username,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: VibrantSpacing.xxs),
        Text(
          'Level ${entry.level}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.3),
                medalColor.withValues(alpha: 0.1),
              ],
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
                  '${entry.xp}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: medalColor,
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
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(
    LeaderboardEntry entry,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isCurrentUser = entry.isCurrentUser;
    final isTopThree = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: VibrantSpacing.sm),
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: isCurrentUser
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
        boxShadow: isCurrentUser
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isTopThree
                  ? LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    )
                  : null,
              color: isTopThree ? null : colorScheme.surfaceContainerHigh,
              border: isCurrentUser
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isTopThree ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: VibrantSpacing.md),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: VibrantSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(VibrantRadius.sm),
                        ),
                        child: Text(
                          'You',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: VibrantSpacing.xxs),
                Text(
                  'Level ${entry.level}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // XP display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flash_on_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: VibrantSpacing.xxs),
                  Text(
                    '${entry.xp}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
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
    );
  }
}
