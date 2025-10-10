import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../pages/auth/login_page.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/gamification/leaderboard_widget.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../services/leaderboard_service.dart';

/// Full leaderboard page with global, friends, and local rankings
class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboardData(LeaderboardService service) async {
    if (!_hasLoadedData) {
      try {
        await service.loadLeaderboards();
        if (mounted) {
          setState(() {
            _hasLoadedData = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasLoadedData = true;
          });
        }
      }
    }
  }

  Future<void> _handleRefresh(LeaderboardService service) async {
    try {
      await service.refresh();
    } catch (e) {
      // Error handled by service
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressServiceAsync = ref.watch(progressServiceProvider);
    final leaderboardServiceAsync = ref.watch(leaderboardServiceProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomRefreshIndicator(
        onRefresh: () async {
          final service = await leaderboardServiceAsync.when(
            data: (service) async => service,
            loading: () async => null,
            error: (error, stack) async => null,
          );
          if (service != null) {
            await _handleRefresh(service);
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
        slivers: [
          // App Bar with tabs
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Text(
                  'Leaderboard',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.lg,
                  vertical: VibrantSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: VibrantTheme.heroGradient,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Global'),
                    Tab(text: 'Friends'),
                    Tab(text: 'Local'),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.only(
              top: VibrantSpacing.lg,
              bottom: VibrantSpacing.xxxl,
            ),
            sliver: SliverToBoxAdapter(
              child: progressServiceAsync.when(
                data: (progressService) {
                  return leaderboardServiceAsync.when(
                    data: (leaderboardService) {
                        // Load data on first build
                        if (!_hasLoadedData) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadLeaderboardData(leaderboardService);
                          });
                        }

                        return ListenableBuilder(
                        listenable: Listenable.merge([
                          progressService,
                          leaderboardService,
                        ]),
                        builder: (context, _) {
                          final currentUserXP = progressService.xpTotal;
                          final currentUserLevel = progressService.currentLevel;

                            // Show loading indicator while loading
                            if (leaderboardService.isLoading && !_hasLoadedData) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: VibrantSpacing.lg,
                                ),
                                child: Column(
                                  children: [
                                    const SkeletonCard(height: 100),
                                    const SizedBox(height: VibrantSpacing.md),
                                    SkeletonList(
                                      itemCount: 5,
                                      itemHeight: 80,
                                      showImage: true,
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Show error if there's an error
                            if (leaderboardService.error != null) {
                              return _buildErrorState(
                                theme,
                                colorScheme,
                                leaderboardService.error!,
                              );
                            }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildTabContent(
                              leaderboardService,
                              currentUserXP,
                              currentUserLevel,
                            ),
                          );
                        },
                      );
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          const SkeletonCard(height: 100),
                          const SizedBox(height: VibrantSpacing.md),
                          SkeletonList(
                            itemCount: 5,
                            itemHeight: 80,
                            showImage: true,
                          ),
                        ],
                      ),
                    ),
                    error: (error, stack) => _buildErrorState(
                        theme,
                        colorScheme,
                        error.toString(),
                      ),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const SkeletonCard(height: 100),
                      const SizedBox(height: VibrantSpacing.md),
                      SkeletonList(
                        itemCount: 5,
                        itemHeight: 80,
                        showImage: true,
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => _buildErrorState(
                        theme,
                        colorScheme,
                        error.toString(),
                      ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    LeaderboardService service,
    int userXP,
    int userLevel,
  ) {
    List<LeaderboardUser> users;
    String emptyMessage;

    switch (_selectedTab) {
      case 0: // Global
        users = service.globalLeaderboard;
        emptyMessage = 'Be the first on the global leaderboard!';
        break;
      case 1: // Friends
        users = service.friendsLeaderboard;
        emptyMessage = 'Add friends to see them on the leaderboard!';
        break;
      case 2: // Local
        users = service.localLeaderboard;
        emptyMessage = 'No local learners found yet!';
        break;
      default:
        users = [];
        emptyMessage = '';
    }

    if (users.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return SlideInFromBottom(
      key: ValueKey(_selectedTab),
      child: Column(
        children: [
          // User's rank card
          _buildUserRankCard(service, userXP, userLevel),
          const SizedBox(height: VibrantSpacing.xl),
          // Leaderboard
          LeaderboardWidget(
            users: users,
            title: _getTabTitle(_selectedTab),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(
    LeaderboardService service,
    int userXP,
    int userLevel,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rank = service.currentUserRank(_selectedTab);
    final xpToNext = service.xpToNextRank(_selectedTab);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: rank <= 3
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              )
            : LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
              ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        boxShadow: [
          BoxShadow(
            color: rank <= 3
                ? const Color(0xFFFFA500).withValues(alpha: 0.3)
                : colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? Colors.white.withValues(alpha: 0.2)
                  : colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VibrantRadius.md),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: rank <= 3 ? Colors.white : colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: VibrantSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: rank <= 3
                        ? Colors.white.withValues(alpha: 0.9)
                        : colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xxs),
                Text(
                  'Level $userLevel • $userXP XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: rank <= 3
                        ? Colors.white
                        : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (xpToNext > 0) ...[
                  const SizedBox(height: VibrantSpacing.xxs),
                  Text(
                    '+$xpToNext XP to rank ${rank - 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: rank <= 3
                          ? Colors.white.withValues(alpha: 0.8)
                          : colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Icon
          if (rank == 1)
            const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 40,
            )
          else if (rank <= 3)
            const Icon(
              Icons.military_tech,
              color: Colors.white,
              size: 32,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(VibrantSpacing.xxxl),
      padding: const EdgeInsets.all(VibrantSpacing.xxxl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VibrantRadius.xxl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme, String error) {
    // Check if this is an auth error
    final isAuthError = error.contains('Could not validate credentials') ||
        error.contains('401') ||
        error.contains('Unauthorized') ||
        error.contains('Not authenticated');

    if (isAuthError) {
      // Show friendly login prompt instead of cryptic error
      return _buildAuthRequiredState(theme, colorScheme);
    }

    // General error state
    return Container(
      margin: const EdgeInsets.all(VibrantSpacing.xxxl),
      padding: const EdgeInsets.all(VibrantSpacing.xxxl),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(VibrantRadius.xxl),
      ),
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
            'Unable to load leaderboard',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthRequiredState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(VibrantSpacing.xxxl),
      padding: const EdgeInsets.all(VibrantSpacing.xxxl),
      decoration: BoxDecoration(
        gradient: VibrantTheme.heroGradient,
        borderRadius: BorderRadius.circular(VibrantRadius.xxl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.login_rounded,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Text(
            'Sign in to compete!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            'Create a free account to:\n• Compete on global leaderboards\n• Track your progress\n• Earn achievements\n• Challenge friends',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VibrantSpacing.xl),
          FilledButton.icon(
            onPressed: () {
              // Navigate to login page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Sign In / Register'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.xl,
                vertical: VibrantSpacing.md,
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Global Leaderboard';
      case 1:
        return 'Friends Leaderboard';
      case 2:
        return 'Local Leaderboard';
      default:
        return 'Leaderboard';
    }
  }
}
