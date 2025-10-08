import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/glass_morphism.dart';
import '../widgets/enhanced_buttons.dart' hide SegmentedButton;
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/skeleton_loader.dart';
import '../services/social_api.dart';
import '../app_providers.dart';

/// Challenges page with real-time progress tracking
class ChallengesPage extends ConsumerStatefulWidget {
  const ChallengesPage({super.key});

  @override
  ConsumerState<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends ConsumerState<ChallengesPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<ChallengeResponse> _challenges = [];
  Timer? _refreshTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadChallenges();

    // Auto-refresh every 30 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadChallenges();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;

    setState(() {
      if (_challenges.isEmpty) _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(socialApiProvider);
      final challenges = await api.getChallenges();

      if (!mounted) return;

      setState(() {
        _challenges = challenges;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadChallenges();
  }

  void _showCreateChallengeDialog() {
    GlassBottomSheet.show(
      context: context,
      child: _CreateChallengeSheet(
        onChallengeCreated: () {
          _loadChallenges();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomRefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // App Bar
            _buildAppBar(theme, colorScheme),

            // Content
            SliverPadding(
              padding: const EdgeInsets.only(
                top: VibrantSpacing.lg,
                bottom: VibrantSpacing.xxxl,
              ),
              sliver: _isLoading && _challenges.isEmpty
                  ? _buildLoadingSliver()
                  : _error != null
                      ? _buildErrorSliver(theme, colorScheme)
                      : _buildContentSliver(theme, colorScheme),
            ),
          ],
        ),
      ),
      floatingActionButton: ExtendedFAB(
        icon: Icons.add_circle_outline,
        label: 'New Challenge',
        onPressed: _showCreateChallengeDialog,
        gradient: VibrantTheme.heroGradient,
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
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
                colors: [Color(0xFFEF4444), Color(0xFFF97316)],
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
            'Challenges',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
            child: SkeletonCard(height: 200),
          ),
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildErrorSliver(ThemeData theme, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Container(
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
              'Failed to load challenges',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.lg),
            FilledButton(
              onPressed: _loadChallenges,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver(ThemeData theme, ColorScheme colorScheme) {
    if (_challenges.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    // Group challenges by status
    final activeChallenges = _challenges.where((c) => c.status == 'active').toList();
    final completedChallenges = _challenges.where((c) => c.status == 'completed').toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Active Challenges
          if (activeChallenges.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Active Challenges',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.sm,
                    vertical: VibrantSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(VibrantRadius.full),
                  ),
                  child: Text(
                    '${activeChallenges.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VibrantSpacing.md),
            ...activeChallenges.map((challenge) => Padding(
                  padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                  child: _buildChallengeCard(challenge, theme, colorScheme, isActive: true),
                )),
            const SizedBox(height: VibrantSpacing.xl),
          ],

          // Completed Challenges
          if (completedChallenges.isNotEmpty) ...[
            Text(
              'Completed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            ...completedChallenges.map((challenge) => Padding(
                  padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                  child: _buildChallengeCard(challenge, theme, colorScheme, isActive: false),
                )),
          ],
        ]),
      ),
    );
  }

  Widget _buildChallengeCard(
    ChallengeResponse challenge,
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool isActive,
  }) {
    final now = DateTime.now();
    final timeRemaining = challenge.expiresAt.difference(now);
    final isExpiringSoon = timeRemaining.inHours < 2 && timeRemaining.inSeconds > 0;
    final hasExpired = timeRemaining.isNegative;

    final initiatorProgress = challenge.initiatorProgress / challenge.targetValue;
    final opponentProgress = challenge.opponentProgress / challenge.targetValue;

    return SlideInFromBottom(
      child: GestureDetector(
        onTap: () => _showChallengeDetails(challenge),
        child: Container(
          decoration: BoxDecoration(
            gradient: isActive && !hasExpired
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      isExpiringSoon
                          ? const Color(0xFFFEF3C7)
                          : colorScheme.primaryContainer.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: !isActive || hasExpired ? colorScheme.surface : null,
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            border: isExpiringSoon && isActive
                ? Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 2,
                  )
                : Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
            boxShadow: [
              BoxShadow(
                color: isActive && !hasExpired
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(VibrantSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: _getChallengeGradient(challenge.challengeType),
                            borderRadius: BorderRadius.circular(VibrantRadius.sm),
                          ),
                          child: Icon(
                            _getChallengeIcon(challenge.challengeType),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: VibrantSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getChallengeName(challenge.challengeType),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Target: ${challenge.targetValue}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isExpiringSoon && !hasExpired)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.5 + (_pulseController.value * 0.5),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: VibrantSpacing.sm,
                                    vertical: VibrantSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(VibrantRadius.full),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTimeRemaining(timeRemaining),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        else if (!hasExpired)
                          Text(
                            _formatTimeRemaining(timeRemaining),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.lg),

                    // Progress Bars
                    _buildProgressBar(
                      theme,
                      colorScheme,
                      label: challenge.initiatorUsername,
                      progress: initiatorProgress,
                      value: challenge.initiatorProgress,
                      isLeading: challenge.initiatorProgress > challenge.opponentProgress,
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    _buildProgressBar(
                      theme,
                      colorScheme,
                      label: challenge.opponentUsername,
                      progress: opponentProgress,
                      value: challenge.opponentProgress,
                      isLeading: challenge.opponentProgress > challenge.initiatorProgress,
                      isOpponent: true,
                    ),
                  ],
                ),
              ),

              // Status badge
              if (hasExpired || !isActive)
                Positioned(
                  top: VibrantSpacing.sm,
                  right: VibrantSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.sm,
                      vertical: VibrantSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: hasExpired
                          ? colorScheme.errorContainer
                          : colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(VibrantRadius.full),
                    ),
                    child: Text(
                      hasExpired ? 'EXPIRED' : challenge.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: hasExpired
                            ? colorScheme.onErrorContainer
                            : colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String label,
    required double progress,
    required int value,
    required bool isLeading,
    bool isOpponent = false,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLeading ? Icons.emoji_events : Icons.person,
              size: 16,
              color: isLeading ? const Color(0xFFFFD700) : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: VibrantSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isLeading ? FontWeight.w700 : FontWeight.w600,
                color: isLeading ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '$value',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isLeading ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.xxs),
        ClipRRect(
          borderRadius: BorderRadius.circular(VibrantRadius.full),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(VibrantRadius.full),
                ),
              ),
              AnimatedContainer(
                duration: VibrantDuration.moderate,
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: isLeading
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        )
                      : isOpponent
                          ? const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                            )
                          : LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                  borderRadius: BorderRadius.circular(VibrantRadius.full),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clampedProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(VibrantRadius.full),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Container(
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
              'No challenges yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'Challenge your friends to compete and learn faster!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return 'Expired';
    if (duration.inDays > 0) return '${duration.inDays}d ${duration.inHours % 24}h';
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes % 60}m';
    return '${duration.inMinutes}m';
  }

  IconData _getChallengeIcon(String type) {
    switch (type) {
      case 'xp':
        return Icons.auto_awesome;
      case 'lessons':
        return Icons.school;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.emoji_events;
    }
  }

  String _getChallengeName(String type) {
    switch (type) {
      case 'xp':
        return 'XP Challenge';
      case 'lessons':
        return 'Lessons Challenge';
      case 'streak':
        return 'Streak Challenge';
      default:
        return 'Challenge';
    }
  }

  Gradient _getChallengeGradient(String type) {
    switch (type) {
      case 'xp':
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case 'lessons':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        );
      case 'streak':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
        );
    }
  }

  void _showChallengeDetails(ChallengeResponse challenge) {
    GlassBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  gradient: _getChallengeGradient(challenge.challengeType),
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Icon(
                  _getChallengeIcon(challenge.challengeType),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getChallengeName(challenge.challengeType),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'Target: ${challenge.targetValue}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Text(
            'Started: ${_formatDate(challenge.startsAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Expires: ${_formatDate(challenge.expiresAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Text(
            'Current Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          _buildProgressBar(
            Theme.of(context),
            Theme.of(context).colorScheme,
            label: challenge.initiatorUsername,
            progress: challenge.initiatorProgress / challenge.targetValue,
            value: challenge.initiatorProgress,
            isLeading: challenge.initiatorProgress > challenge.opponentProgress,
          ),
          const SizedBox(height: VibrantSpacing.sm),
          _buildProgressBar(
            Theme.of(context),
            Theme.of(context).colorScheme,
            label: challenge.opponentUsername,
            progress: challenge.opponentProgress / challenge.targetValue,
            value: challenge.opponentProgress,
            isLeading: challenge.opponentProgress > challenge.initiatorProgress,
            isOpponent: true,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}

/// Create challenge bottom sheet
class _CreateChallengeSheet extends ConsumerStatefulWidget {
  const _CreateChallengeSheet({required this.onChallengeCreated});

  final VoidCallback onChallengeCreated;

  @override
  ConsumerState<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<_CreateChallengeSheet> {
  String _selectedType = 'xp';
  int _targetValue = 100;
  int _duration = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Challenge',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: VibrantSpacing.lg),
        Text('Challenge Type', style: theme.textTheme.labelLarge),
        const SizedBox(height: VibrantSpacing.sm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'xp', label: Text('XP')),
            ButtonSegment(value: 'lessons', label: Text('Lessons')),
            ButtonSegment(value: 'streak', label: Text('Streak')),
          ],
          selected: {_selectedType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedType = newSelection.first;
            });
          },
        ),
        const SizedBox(height: VibrantSpacing.lg),
        Text('Target Value: $_targetValue', style: theme.textTheme.labelLarge),
        Slider(
          value: _targetValue.toDouble(),
          min: 10,
          max: 500,
          divisions: 49,
          label: '$_targetValue',
          onChanged: (value) {
            setState(() {
              _targetValue = value.toInt();
            });
          },
        ),
        const SizedBox(height: VibrantSpacing.md),
        Text('Duration: ${_duration}h', style: theme.textTheme.labelLarge),
        Slider(
          value: _duration.toDouble(),
          min: 1,
          max: 72,
          divisions: 71,
          label: '${_duration}h',
          onChanged: (value) {
            setState(() {
              _duration = value.toInt();
            });
          },
        ),
        const SizedBox(height: VibrantSpacing.xl),
        GradientButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onChallengeCreated();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Challenge feature coming soon!')),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle, color: Colors.white),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                'Create Challenge',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
