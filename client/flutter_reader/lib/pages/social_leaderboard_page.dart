import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../features/gamification/presentation/providers/gamification_providers.dart';
import '../features/gamification/domain/models/user_progress.dart';
import '../widgets/social/leaderboard_widget.dart' as leaderboard_widget;
import '../widgets/common/aurora_background.dart';
import '../widgets/glassmorphism_card.dart';
import 'public_profile_page.dart';

/// Professional social/leaderboard page with competitive features
/// Inspired by modern language learning app leaderboards and gaming competitive UX
class SocialLeaderboardPage extends ConsumerStatefulWidget {
  const SocialLeaderboardPage({super.key});

  @override
  ConsumerState<SocialLeaderboardPage> createState() => _SocialLeaderboardPageState();
}

class _SocialLeaderboardPageState extends ConsumerState<SocialLeaderboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heroController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  LeaderboardScope _currentScope = LeaderboardScope.global;
  LeaderboardPeriod _currentPeriod = LeaderboardPeriod.weekly;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _tabController = TabController(length: 4, vsync: this);
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentPeriod = LeaderboardPeriod.values[_tabController.index];
        });
        HapticService.light();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final leaderboardParams = LeaderboardParams(
      scope: _currentScope,
      period: _currentPeriod,
      languageCode: _currentScope == LeaderboardScope.language ? 'lat' : null,
    );

    final leaderboardAsync = ref.watch(leaderboardProvider(leaderboardParams));
    final userProgressAsync = ref.watch(userProgressProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
          // Hero section with aurora background
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: const BoxDecoration(gradient: VibrantTheme.auroraGradient),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AuroraBackground(controller: _heroController),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.leaderboard_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: VibrantSpacing.sm),
                              Text(
                                'Leaderboard',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: VibrantSpacing.xs),
                          Text(
                            'Compete with learners worldwide, earn your place among the top scholars.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.md),
                          _ScopeSelector(
                            currentScope: _currentScope,
                            onScopeChanged: (scope) {
                              setState(() => _currentScope = scope);
                              HapticService.light();
                              SoundService.instance.tap();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarHeaderDelegate(
              tabBar: Material(
                color: colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                    Tab(text: 'All Time'),
                  ],
                ),
              ),
            ),
          ),

          // Current user card (sticky)
          SliverPersistentHeader(
            pinned: true,
            delegate: _CurrentUserHeaderDelegate(
              minHeight: 80,
              maxHeight: 80,
              child: Container(
                color: colorScheme.surface,
                child: userProgressAsync.when(
                  data: (progress) => leaderboardAsync.when(
                    data: (entries) {
                      // Find current user in leaderboard
                      final currentUserEntry = entries.firstWhere(
                        (e) => e.userId == progress.userId,
                        orElse: () => LeaderboardEntry(
                          userId: progress.userId,
                          username: 'You',
                          avatarUrl: 'https://i.pravatar.cc/150?u=${progress.userId}',
                          rank: entries.length + 1,
                          xp: progress.totalXp,
                          languageCode: 'lat',
                          period: _currentPeriod,
                        ),
                      );

                      return _CurrentUserCard(
                        entry: currentUserEntry,
                        totalUsers: entries.length,
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: -0.1, end: 0);
                    },
                    loading: () => _LoadingCurrentUserCard(),
                    error: (err, stack) => _ErrorCard(error: err.toString()),
                  ),
                  loading: () => _LoadingCurrentUserCard(),
                  error: (err, stack) => _ErrorCard(error: err.toString()),
                ),
              ),
            ),
          ),

          // Leaderboard content
          SliverPadding(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            sliver: leaderboardAsync.when(
              data: (entries) => _LeaderboardContent(
                entries: entries,
                currentUserId: ref.watch(currentUserIdProvider),
              ),
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                    child: _LoadingCard(),
                  ),
                  childCount: 10,
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: _ErrorCard(error: err.toString()),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

/// Tab bar persistent header delegate
class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabBarHeaderDelegate({required this.tabBar});

  final Widget tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return tabBar;
  }

  @override
  bool shouldRebuild(_TabBarHeaderDelegate oldDelegate) {
    return false;
  }
}

/// Scope selector chips
class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({
    required this.currentScope,
    required this.onScopeChanged,
  });

  final LeaderboardScope currentScope;
  final Function(LeaderboardScope) onScopeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VibrantSpacing.sm,
      runSpacing: VibrantSpacing.xs,
      children: LeaderboardScope.values.map((scope) {
        final isSelected = scope == currentScope;
        return GlassmorphismCard(
          blur: 16,
          borderRadius: 24,
          opacity: isSelected ? 0.25 : 0.15,
          borderOpacity: isSelected ? 0.4 : 0.25,
          padding: const EdgeInsets.symmetric(
            horizontal: VibrantSpacing.sm,
            vertical: VibrantSpacing.xs,
          ),
          child: InkWell(
            onTap: () => onScopeChanged(scope),
            borderRadius: BorderRadius.circular(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: VibrantSpacing.xs),
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                Text(
                  _getScopeLabel(scope),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getScopeLabel(LeaderboardScope scope) {
    switch (scope) {
      case LeaderboardScope.global:
        return 'Global';
      case LeaderboardScope.friends:
        return 'Friends';
      case LeaderboardScope.language:
        return 'Latin';
    }
  }
}

/// Current user card (pinned header)
class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({
    required this.entry,
    required this.totalUsers,
  });

  final LeaderboardEntry entry;
  final int totalUsers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassmorphismCard(
      blur: 20,
      borderRadius: 28,
      opacity: 0.22,
      borderOpacity: 0.35,
      margin: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.sm,
      ),
      padding: const EdgeInsets.all(VibrantSpacing.md),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary.withValues(alpha: 0.2),
          colorScheme.tertiary.withValues(alpha: 0.15),
        ],
      ),
      elevation: 4,
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: VibrantSpacing.md),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Rank',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  'Top ${((entry.rank / totalUsers) * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.xp} XP',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'this ${_getPeriodLabel(entry.period)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return 'day';
      case LeaderboardPeriod.weekly:
        return 'week';
      case LeaderboardPeriod.monthly:
        return 'month';
      case LeaderboardPeriod.allTime:
        return 'all time';
    }
  }
}

/// Leaderboard content with podium and list
class _LeaderboardContent extends StatelessWidget {
  const _LeaderboardContent({
    required this.entries,
    required this.currentUserId,
  });

  final List<LeaderboardEntry> entries;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyState(),
      );
    }

    // Get top 3 for podium
    final topThree = entries.take(3).toList();
    final remaining = entries.skip(3).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        // Podium for top 3
        if (topThree.isNotEmpty)
          leaderboard_widget.LeaderboardWidget(
            entries: topThree.map(_mapToWidgetEntry).toList(),
            currentUserEntry: currentUserId != null
                ? _mapToWidgetEntry(
                    entries.firstWhere(
                      (e) => e.userId == currentUserId,
                      orElse: () => entries.first,
                    ),
                  )
                : _mapToWidgetEntry(entries.first),
            scope: leaderboard_widget.LeaderboardScope.global,
            onScopeChanged: (_) {},
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 300.ms)
              .scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: VibrantSpacing.xl),

        // Rest of the list
        ...remaining.asMap().entries.map((entry) {
          final index = entry.key;
          final leaderboardEntry = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
            child: _LeaderboardListItem(
              entry: leaderboardEntry,
              isCurrentUser: leaderboardEntry.userId == currentUserId,
            )
                .animate()
                .fadeIn(delay: (200 + index * 50).ms, duration: 250.ms)
                .slideX(begin: 0.1, end: 0),
          );
        }),
      ]),
    );
  }

  leaderboard_widget.LeaderboardEntry _mapToWidgetEntry(LeaderboardEntry entry) {
    return leaderboard_widget.LeaderboardEntry(
      userId: entry.userId,
      username: entry.username,
      rank: entry.rank,
      score: entry.xp,
      avatarUrl: entry.avatarUrl,
      languageCode: entry.languageCode,
      isCurrentUser: entry.userId == currentUserId,
    );
  }
}

/// Individual leaderboard list item
class _LeaderboardListItem extends StatelessWidget {
  const _LeaderboardListItem({
    required this.entry,
    required this.isCurrentUser,
  });

  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassmorphismCard(
      blur: 16,
      borderRadius: 26,
      opacity: isCurrentUser ? 0.2 : 0.14,
      borderOpacity: isCurrentUser ? 0.32 : 0.2,
      padding: EdgeInsets.zero,
      gradient: isCurrentUser
          ? LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.15),
                colorScheme.tertiary.withValues(alpha: 0.1),
              ],
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.light();
            SoundService.instance.tap();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfilePage(
                  userId: entry.userId,
                  username: entry.username,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(26),
          child: Container(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 32,
                  child: Text(
                    '#${entry.rank}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.username,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isCurrentUser)
                        Text(
                          'You',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),

                // XP
                Text(
                  '${entry.xp} XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent header delegate
class _CurrentUserHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CurrentUserHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_CurrentUserHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// Loading and error states
class _LoadingCurrentUserCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.sm,
      ),
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Text(
              'Failed to load leaderboard',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'No competitors yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'Complete lessons to join the leaderboard',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
