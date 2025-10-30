import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../api/achievements_api.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/animations/achievement_unlock_overlay.dart';
import '../services/sound_service.dart';
import '../services/haptic_service.dart';
import '../widgets/error/async_error_boundary.dart';
import '../widgets/error/provider_error_widgets.dart';

/// State provider for achievements data
final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((
  ref,
) async {
  final authService = ref.read(authServiceProvider);
  if (!authService.isAuthenticated) {
    throw Exception('Please log in to view your achievements');
  }

  final api = ref.read(achievementsApiProvider);
  return await api.getUserAchievements();
});

/// Enhanced achievements showcase page with premium animations and error handling
class AchievementsPageEnhanced extends ConsumerStatefulWidget {
  const AchievementsPageEnhanced({super.key});

  @override
  ConsumerState<AchievementsPageEnhanced> createState() =>
      _AchievementsPageEnhancedState();
}

class _AchievementsPageEnhancedState
    extends ConsumerState<AchievementsPageEnhanced>
    with SingleTickerProviderStateMixin {
  String _filterType = 'all'; // all, badge, milestone, collection
  String _statusFilter = 'all'; // all, unlocked, progress, locked
  late AnimationController _heroAnimationController;
  late Animation<double> _heroScaleAnimation;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heroScaleAnimation = CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutBack,
    );
    _heroAnimationController.forward();
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticService.light();
              SoundService.instance.tap();
              ref.invalidate(achievementsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: AsyncErrorBoundary(
        asyncValue: achievementsAsync,
        builder: (achievements) => ProviderRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(achievementsProvider);
            await ref.read(achievementsProvider.future);
          },
          child: _buildContent(achievements, theme, colorScheme),
        ),
        onRetry: () => ref.invalidate(achievementsProvider),
        loadingBuilder: () => _buildShimmerLoading(colorScheme),
      ),
    );
  }

  Widget _buildShimmerLoading(ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        // Shimmer hero card
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(VibrantSpacing.lg),
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(VibrantRadius.xl),
            ),
          ),
        ),
        // Shimmer filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
            child: Row(
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.only(right: VibrantSpacing.sm),
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Shimmer grid
        SliverPadding(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: VibrantSpacing.md,
              crossAxisSpacing: VibrantSpacing.md,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(VibrantRadius.lg),
                ),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    List<Achievement> achievements,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (achievements.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.emoji_events_outlined,
        title: 'No Achievements Yet',
        message: 'Complete lessons to unlock achievements!',
        action: FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.school_rounded),
          label: const Text('Start Learning'),
        ),
      );
    }

    final filteredAchievements = _applyFilters(achievements);

    return CustomScrollView(
      slivers: [
        // Animated hero stats card
        SliverToBoxAdapter(
          child: ScaleTransition(
            scale: _heroScaleAnimation,
            child: _buildHeroStatsCard(achievements, theme, colorScheme),
          ),
        ),

        // Type filter chips
        SliverToBoxAdapter(child: _buildFilterChips(theme, colorScheme)),

        // Status filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: VibrantSpacing.lg,
              right: VibrantSpacing.lg,
              bottom: VibrantSpacing.md,
            ),
            child: _buildStatusFilterChips(achievements, theme, colorScheme),
          ),
        ),

        // Achievements grid
        if (filteredAchievements.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt_off_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    'No $_filterType achievements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._buildTierSections(filteredAchievements, theme, colorScheme),
      ],
    );
  }

  Widget _buildHeroStatsCard(
    List<Achievement> achievements,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final progressCount = achievements
        .where((a) => a.isInProgress && !a.isUnlocked)
        .length;
    final lockedCount = achievements.length - unlockedCount;
    final rareUnlocked = achievements
        .where((a) => a.isUnlocked && a.tier >= 3)
        .length;
    final rarestUnlocked = achievements
        .where((a) => a.isUnlocked && (a.rarityPercent ?? 100) < 100)
        .fold<Achievement?>(
          null,
          (prev, element) => prev == null
              ? element
              : ((element.rarityPercent ?? 101) < (prev.rarityPercent ?? 101)
                    ? element
                    : prev),
        );

    return Container(
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
          // Total count with pulsing animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: achievements.length.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                value.toInt().toString(),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
          const SizedBox(height: VibrantSpacing.xs),
          Text(
            'Achievements Unlocked',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VibrantSpacing.lg),
          // Tier breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTierStat(1, achievements, theme),
              _buildTierStat(2, achievements, theme),
              _buildTierStat(3, achievements, theme),
              _buildTierStat(4, achievements, theme),
            ],
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Wrap(
            spacing: VibrantSpacing.sm,
            runSpacing: VibrantSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _buildStatusPill(
                label: 'Unlocked',
                value: unlockedCount,
                icon: Icons.emoji_events_rounded,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
              _buildStatusPill(
                label: 'In Progress',
                value: progressCount,
                icon: Icons.hourglass_top_rounded,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
              _buildStatusPill(
                label: 'Locked',
                value: lockedCount,
                icon: Icons.lock_rounded,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
              _buildStatusPill(
                label: 'Legendary',
                value: rareUnlocked,
                icon: Icons.stars_rounded,
                backgroundColor: Colors.amberAccent.withValues(alpha: 0.2),
              ),
            ],
          ),
          if (rarestUnlocked != null) ...[
            const SizedBox(height: VibrantSpacing.md),
            Text(
              'Rarest unlocked: ${rarestUnlocked.title} • ${rarestUnlocked.rarityDisplay}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Achievement> _applyFilters(List<Achievement> achievements) {
    Iterable<Achievement> filtered = achievements;

    if (_filterType != 'all') {
      filtered = filtered.where((a) => a.achievementType == _filterType);
    }

    switch (_statusFilter) {
      case 'unlocked':
        filtered = filtered.where((a) => a.isUnlocked);
        break;
      case 'progress':
        filtered = filtered.where((a) => a.isInProgress);
        break;
      case 'locked':
        filtered = filtered.where((a) => !a.isUnlocked);
        break;
    }

    return filtered.toList();
  }

  Widget _buildStatusFilterChips(
    List<Achievement> achievements,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final progressCount = achievements
        .where((a) => a.isInProgress && !a.isUnlocked)
        .length;
    final lockedCount = achievements.length - unlockedCount;

    Widget buildChip(String value, String label, IconData icon, int? count) {
      final selected = _statusFilter == value;
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: VibrantSpacing.xxs),
            Text(
              count != null ? '$label ($count)' : label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: (_) {
          HapticService.light();
          setState(() => _statusFilter = value);
        },
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        selectedColor: colorScheme.primary,
        elevation: selected ? 3 : 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          side: BorderSide(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Wrap(
      spacing: VibrantSpacing.sm,
      runSpacing: VibrantSpacing.sm,
      children: [
        buildChip(
          'all',
          'All',
          Icons.all_inclusive_rounded,
          achievements.length,
        ),
        buildChip(
          'unlocked',
          'Unlocked',
          Icons.emoji_events_rounded,
          unlockedCount,
        ),
        buildChip(
          'progress',
          'In Progress',
          Icons.hourglass_top_rounded,
          progressCount,
        ),
        buildChip('locked', 'Locked', Icons.lock_rounded, lockedCount),
      ],
    );
  }

  Widget _buildStatusPill({
    required String label,
    required int value,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: VibrantSpacing.xxs),
          Text(
            '$label • $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierStat(
    int tier,
    List<Achievement> achievements,
    ThemeData theme,
  ) {
    final count = achievements.where((a) => a.tier == tier).length;
    final color = _getTierColor(tier);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (tier * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.emoji_events_rounded, color: color, size: 24),
              ),
              const SizedBox(height: VibrantSpacing.xs),
              Text(
                '$count',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _getTierName(tier),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.md,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All', Icons.grid_view, colorScheme),
            const SizedBox(width: VibrantSpacing.sm),
            _buildFilterChip(
              'badge',
              'Badges',
              Icons.shield_rounded,
              colorScheme,
            ),
            const SizedBox(width: VibrantSpacing.sm),
            _buildFilterChip(
              'milestone',
              'Milestones',
              Icons.flag_rounded,
              colorScheme,
            ),
            const SizedBox(width: VibrantSpacing.sm),
            _buildFilterChip(
              'collection',
              'Collections',
              Icons.collections_bookmark_rounded,
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String type,
    String label,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isSelected = _filterType == type;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: VibrantSpacing.xs),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          HapticService.light();
          SoundService.instance.tap();
          setState(() {
            _filterType = type;
          });
        },
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
      ),
    );
  }

  List<Widget> _buildTierSections(
    List<Achievement> achievements,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final achievementsByTier = <int, List<Achievement>>{};
    for (final achievement in achievements) {
      achievementsByTier
          .putIfAbsent(achievement.tier, () => [])
          .add(achievement);
    }

    final sections = <Widget>[];
    for (final tier in [4, 3, 2, 1]) {
      final tierAchievements = achievementsByTier[tier];
      if (tierAchievements == null || tierAchievements.isEmpty) continue;

      sections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              VibrantSpacing.lg,
              VibrantSpacing.xl,
              VibrantSpacing.lg,
              VibrantSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.sm),
                  decoration: BoxDecoration(
                    color: _getTierColor(tier).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    border: Border.all(color: _getTierColor(tier), width: 2),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: _getTierColor(tier),
                    size: 20,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Text(
                  '${_getTierName(tier)} (${tierAchievements.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      sections.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: VibrantSpacing.md,
              crossAxisSpacing: VibrantSpacing.md,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAchievementCard(
                tierAchievements[index],
                theme,
                colorScheme,
              ),
              childCount: tierAchievements.length,
            ),
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final tierColor = _getTierColor(achievement.tier);
    final unlocked = achievement.isUnlocked;
    final inProgress = achievement.isInProgress;

    final backgroundGradient = unlocked
        ? [tierColor.withValues(alpha: 0.18), tierColor.withValues(alpha: 0.08)]
        : [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ];

    final borderColor = unlocked
        ? tierColor.withValues(alpha: 0.35)
        : colorScheme.outline.withValues(alpha: 0.2);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.92 + value * 0.08,
          child: Opacity(opacity: value, child: child!),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticService.medium();
          _showAchievementDetails(achievement);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: backgroundGradient,
            ),
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: unlocked
                    ? tierColor.withValues(alpha: 0.18)
                    : colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.sm,
                          vertical: VibrantSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? tierColor.withValues(alpha: 0.22)
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.5,
                                ),
                          borderRadius: BorderRadius.circular(VibrantRadius.sm),
                        ),
                        child: Text(
                          achievement.rarityLabel.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: unlocked
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            tierColor.withValues(alpha: unlocked ? 0.35 : 0.18),
                            tierColor.withValues(alpha: unlocked ? 0.15 : 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: unlocked
                              ? tierColor
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      achievement.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.sm,
                        vertical: VibrantSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _getTierName(achievement.tier),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tierColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (achievement.xpReward > 0 ||
                        achievement.coinReward > 0) ...[
                      const SizedBox(height: VibrantSpacing.xs),
                      Wrap(
                        spacing: VibrantSpacing.xs,
                        runSpacing: VibrantSpacing.xxs,
                        alignment: WrapAlignment.center,
                        children: [
                          if (achievement.xpReward > 0)
                            _buildRewardBadge(
                              '+${achievement.xpReward} XP',
                              Icons.flash_on_rounded,
                              Colors.amber,
                            ),
                          if (achievement.coinReward > 0)
                            _buildRewardBadge(
                              '+${achievement.coinReward}',
                              Icons.monetization_on_rounded,
                              Colors.yellow.shade700,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: VibrantSpacing.sm),
                    if (inProgress)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              VibrantRadius.sm,
                            ),
                            child: LinearProgressIndicator(
                              value: achievement.completionPercent,
                              minHeight: 6,
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tierColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.xxs),
                          Text(
                            'Progress ${(achievement.completionPercent * 100).clamp(0, 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else if (!unlocked)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: VibrantSpacing.xxs),
                          Text(
                            'Locked',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else if (achievement.unlockedAt != null)
                      Text(
                        'Unlocked • ${achievement.unlockedAt!.toLocal().toString().split(" ").first}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (!unlocked)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: tierColor.withValues(alpha: 0.45),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    if (achievement.isUnlocked) {
      switch (achievement.tier) {
        case 4:
          SoundService.instance.badgeUnlock();
          break;
        case 3:
          SoundService.instance.achievement();
          break;
        case 2:
          SoundService.instance.sparkle();
          break;
        default:
          SoundService.instance.tap();
      }

      showAchievementUnlock(
        context,
        achievementId: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        tier: achievement.tier,
        xpReward: achievement.xpReward,
        coinReward: achievement.coinReward,
      );
    } else {
      SoundService.instance.sparkle();
      _showAchievementPreviewSheet(achievement);
    }
  }

  void _showAchievementPreviewSheet(Achievement achievement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tierColor = _getTierColor(achievement.tier);
    final criteria = _criteriaDescriptions(achievement);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: VibrantSpacing.lg,
            right: VibrantSpacing.lg,
            top: VibrantSpacing.lg,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom +
                VibrantSpacing.lg,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(VibrantRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              tierColor.withValues(alpha: 0.35),
                              tierColor.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(color: tierColor, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            achievement.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.xxs),
                            Text(
                              achievement.rarityDisplay,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.8,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    children: [
                      _buildInfoChip(
                        icon: Icons.layers_rounded,
                        label: _getTierName(achievement.tier),
                        color: tierColor,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      _buildInfoChip(
                        icon: Icons.category_rounded,
                        label: achievement.category,
                        color: colorScheme.secondary,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      if (achievement.xpReward > 0)
                        _buildInfoChip(
                          icon: Icons.flash_on_rounded,
                          label: '+${achievement.xpReward} XP',
                          color: Colors.amber,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      if (achievement.coinReward > 0)
                        _buildInfoChip(
                          icon: Icons.monetization_on_rounded,
                          label: '+${achievement.coinReward}',
                          color: Colors.yellow.shade700,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  if (achievement.isInProgress) ...[
                    Text(
                      'Current Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      child: LinearProgressIndicator(
                        value: achievement.completionPercent,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      '${achievement.progressCurrent ?? 0} / ${achievement.progressTarget ?? '?'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                  ],
                  if (criteria.isNotEmpty) ...[
                    Text(
                      'How to unlock',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    ...criteria.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: VibrantSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: tierColor,
                            ),
                            const SizedBox(width: VibrantSpacing.xs),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).maybePop(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.lg,
                          vertical: VibrantSpacing.sm,
                        ),
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.brown.shade400; // Bronze
      case 2:
        return Colors.grey.shade400; // Silver
      case 3:
        return const Color(0xFFFFD700); // Gold
      case 4:
        return const Color(0xFFE5E4E2); // Platinum
      default:
        return Colors.blue;
    }
  }

  String _getTierName(int tier) {
    switch (tier) {
      case 1:
        return 'Bronze';
      case 2:
        return 'Silver';
      case 3:
        return 'Gold';
      case 4:
        return 'Platinum';
      default:
        return 'Common';
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: VibrantSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _criteriaDescriptions(Achievement achievement) {
    final criteria = achievement.unlockCriteria;
    if (criteria.isEmpty) return [];

    final List<String> items = [];

    void add(String text) {
      if (text.isNotEmpty) items.add(text);
    }

    final lessonsCompleted =
        criteria['lessons_completed'] ?? criteria['lessonsCompleted'];
    if (lessonsCompleted is num) {
      add('Complete ${lessonsCompleted.toInt()} lessons.');
    }

    final perfectLessons = criteria['perfect_lessons'];
    if (perfectLessons is num) {
      add('Earn a perfect score in ${perfectLessons.toInt()} lessons.');
    }

    final streakDays = criteria['streak_days'];
    if (streakDays is num) {
      add('Maintain a ${streakDays.toInt()}-day learning streak.');
    }

    final xpTotal = criteria['xp_total'];
    if (xpTotal is num) {
      add('Reach ${xpTotal.toInt()} total XP.');
    }

    final level = criteria['level'];
    if (level is num) {
      add('Reach level ${level.toInt()}.');
    }

    final languagesCount = criteria['languages_count'];
    if (languagesCount is num) {
      add('Study ${languagesCount.toInt()} different languages.');
    }

    final language = criteria['language'];
    if (language is String) {
      final lessonsInLanguage =
          criteria['lessons'] ?? criteria['lessons_completed'];
      if (lessonsInLanguage is num) {
        add(
          'Complete ${lessonsInLanguage.toInt()} lessons in ${_languageDisplayName(language)}.',
        );
      } else {
        add('Practice ${_languageDisplayName(language)} consistently.');
      }
    }

    final coins = criteria['coins'];
    if (coins is num) {
      add('Collect ${coins.toInt()} coins.');
    }

    final completionTime = criteria['completion_time_seconds'];
    if (completionTime is num) {
      final minutes = (completionTime / 60).ceil();
      add('Finish a lesson in under $minutes minutes.');
    }

    final special = criteria['special'];
    if (special is String) {
      add(_describeSpecialAchievement(special));
    }

    return items;
  }

  String _describeSpecialAchievement(String code) {
    switch (code) {
      case 'early_morning':
        return 'Complete a lesson before 7 AM.';
      case 'late_night':
        return 'Complete a lesson after 11 PM.';
      case 'weekend':
        return 'Study during the weekend.';
      case 'holiday':
        return 'Study on a major holiday.';
      default:
        return 'Complete a special challenge.';
    }
  }

  String _languageDisplayName(String code) {
    const knownLanguages = {
      'grc': 'Classical Greek',
      'lat': 'Latin',
      'hbo': 'Biblical Hebrew',
      'egy': 'Middle Egyptian',
      'san': 'Sanskrit',
    };
    return knownLanguages[code] ?? code.toUpperCase();
  }
}
