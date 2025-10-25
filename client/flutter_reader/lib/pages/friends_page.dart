import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/auth/login_page.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/premium_snackbars.dart';
import '../services/social_api.dart';
import '../app_providers.dart';

/// Friends page for managing friend connections
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<FriendResponse> _friends = [];
  List<FriendResponse> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadFriends();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(socialApiProvider);
      final allFriends = await api.getFriends();

      setState(() {
        _friends = allFriends.where((f) => f.status == 'accepted').toList();
        _pendingRequests = allFriends
            .where((f) => f.status == 'pending')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadFriends();
  }

  Future<void> _addFriend() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('Please enter a username', isError: true);
      return;
    }

    try {
      final api = ref.read(socialApiProvider);
      await api.addFriend(username);
      _searchController.clear();
      _showSnackBar('Friend request sent to $username');
      await _loadFriends();
    } catch (e) {
      _showSnackBar('Failed to add friend: ${e.toString()}', isError: true);
    }
  }

  Future<void> _acceptRequest(FriendResponse friend) async {
    // Optimistic update: move from pending to friends immediately
    final acceptedFriend = FriendResponse(
      userId: friend.userId,
      username: friend.username,
      xp: friend.xp,
      level: friend.level,
      status: 'accepted',
      isOnline: friend.isOnline,
    );

    setState(() {
      _pendingRequests.removeWhere((f) => f.userId == friend.userId);
      _friends.add(acceptedFriend);
    });

    try {
      final api = ref.read(socialApiProvider);
      await api.acceptFriendRequest(friend.userId);
      _showSnackBar('${friend.username} is now your friend!');
      // Reload to sync with server
      await _loadFriends();
    } catch (e) {
      // Rollback optimistic update on error
      setState(() {
        _friends.removeWhere((f) => f.userId == friend.userId);
        _pendingRequests.add(friend);
      });
      _showSnackBar('Failed to accept request: ${e.toString()}', isError: true);
    }
  }

  Future<void> _removeFriend(FriendResponse friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove ${friend.username} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic update: remove friend immediately
    setState(() {
      _friends.removeWhere((f) => f.userId == friend.userId);
    });

    try {
      final api = ref.read(socialApiProvider);
      await api.removeFriend(friend.userId);
      _showSnackBar('${friend.username} removed from friends');
      // Reload to sync with server
      await _loadFriends();
    } catch (e) {
      // Rollback optimistic update on error
      setState(() {
        _friends.add(friend);
      });
      _showSnackBar('Failed to remove friend: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      PremiumSnackBar.error(context, title: 'Error', message: message);
    } else {
      PremiumSnackBar.success(context, title: 'Success', message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomRefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
            // App Bar
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
                      gradient: VibrantTheme.heroGradient,
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Text(
                    'Friends',
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
                    tabs: [
                      Tab(text: 'Friends (${_friends.length})'),
                      Tab(text: 'Requests (${_pendingRequests.length})'),
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
                child: _isLoading
                    ? _buildLoading()
                    : _error != null
                    ? _buildError(theme, colorScheme)
                    : _buildContent(theme, colorScheme),
              ),
            ),
          ],
        ),
      ),
        ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      child: SkeletonList(itemCount: 5, itemHeight: 80, showImage: true),
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme colorScheme) {
    // Check if this is an auth error
    final errorText = _error ?? '';
    final isAuthError =
        errorText.contains('Could not validate credentials') ||
        errorText.contains('401') ||
        errorText.contains('Unauthorized') ||
        errorText.contains('Not authenticated');

    if (isAuthError) {
      // Show friendly auth prompt
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
            Icon(Icons.people_rounded, size: 64, color: Colors.white),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'Connect with learners!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'Create a free account to:\n• Add friends and track their progress\n• Challenge friends to learning duels\n• Share achievements\n• Learn together',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: VibrantSpacing.lg),
          Text(
            'Failed to load friends',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VibrantSpacing.lg),
          FilledButton(onPressed: _loadFriends, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Add Friend Section
        _buildAddFriendSection(theme, colorScheme),
        const SizedBox(height: VibrantSpacing.xl),

        // Tab Content
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsList(theme, colorScheme),
              _buildRequestsList(theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddFriendSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Friend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.md,
                      vertical: VibrantSpacing.sm,
                    ),
                  ),
                  onSubmitted: (_) => _addFriend(),
                ),
              ),
              const SizedBox(width: VibrantSpacing.sm),
              FilledButton.icon(
                onPressed: _addFriend,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.lg,
                    vertical: VibrantSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(ThemeData theme, ColorScheme colorScheme) {
    if (_friends.isEmpty) {
      return _buildEmptyState(
        theme,
        colorScheme,
        icon: Icons.people_outline,
        message: 'No friends yet',
        subtitle: 'Add friends to compete and learn together!',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(theme, colorScheme, friend);
        },
      ),
    );
  }

  Widget _buildRequestsList(ThemeData theme, ColorScheme colorScheme) {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        theme,
        colorScheme,
        icon: Icons.inbox_outlined,
        message: 'No pending requests',
        subtitle: 'Friend requests will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildRequestCard(theme, colorScheme, request);
      },
    );
  }

  Widget _buildFriendCard(
    ThemeData theme,
    ColorScheme colorScheme,
    FriendResponse friend,
  ) {
    return SlideInFromBottom(
      child: Container(
        margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(VibrantSpacing.md),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              friend.username[0].toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            friend.username,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            'Level ${friend.level} • ${friend.xp} XP',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'challenge') {
                _showSnackBar('Challenge feature coming soon!');
              } else if (value == 'remove') {
                _removeFriend(friend);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'challenge',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events),
                    SizedBox(width: VibrantSpacing.sm),
                    Text('Challenge'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: VibrantSpacing.sm),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    ThemeData theme,
    ColorScheme colorScheme,
    FriendResponse request,
  ) {
    return SlideInFromBottom(
      child: Container(
        margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(VibrantSpacing.md),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              request.username[0].toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            request.username,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            'Wants to be your friend',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _acceptRequest(request),
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Accept',
              ),
              IconButton(
                onPressed: () => _removeFriend(request),
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: 'Decline',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
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
            child: Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: VibrantSpacing.xl),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
