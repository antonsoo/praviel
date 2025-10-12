import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../api/achievements_api.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/animations/achievement_unlock_overlay.dart';

/// Full achievements showcase page showing all unlocked and locked achievements
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  List<Achievement>? _achievements;
  bool _loading = true;
  String? _error;
  String _filterType = 'all'; // all, badge, milestone, collection

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(achievementsApiProvider);
      final achievements = await api.getUserAchievements();
      if (mounted) {
        setState(() {
          _achievements = achievements;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Achievement> get _filteredAchievements {
    if (_achievements == null) return [];
    if (_filterType == 'all') return _achievements!;
    return _achievements!
        .where((a) => a.achievementType == _filterType)
        .toList();
  }

  Map<int, List<Achievement>> get _achievementsByTier {
    final filtered = _filteredAchievements;
    return {
      for (var tier in [1, 2, 3, 4])
        tier: filtered.where((a) => a.tier == tier).toList(),
    };
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            onPressed: _loadAchievements,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                        'Failed to load achievements',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: VibrantSpacing.sm),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: VibrantSpacing.xl),
                      FilledButton.icon(
                        onPressed: _loadAchievements,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAchievements,
                  child: CustomScrollView(
                    slivers: [
                      // Header stats
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(VibrantSpacing.lg),
                          padding: const EdgeInsets.all(VibrantSpacing.xl),
                          decoration: BoxDecoration(
                            gradient: VibrantTheme.heroGradient,
                            borderRadius:
                                BorderRadius.circular(VibrantRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_achievements?.length ?? 0}',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildTierStat(1, theme),
                                  _buildTierStat(2, theme),
                                  _buildTierStat(3, theme),
                                  _buildTierStat(4, theme),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.lg,
                            vertical: VibrantSpacing.md,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('all', 'All', Icons.grid_view),
                                const SizedBox(width: VibrantSpacing.sm),
                                _buildFilterChip(
                                  'badge',
                                  'Badges',
                                  Icons.shield_rounded,
                                ),
                                const SizedBox(width: VibrantSpacing.sm),
                                _buildFilterChip(
                                  'milestone',
                                  'Milestones',
                                  Icons.flag_rounded,
                                ),
                                const SizedBox(width: VibrantSpacing.sm),
                                _buildFilterChip(
                                  'collection',
                                  'Collections',
                                  Icons.collections_bookmark_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Achievements by tier
                      if (_achievements == null || _achievements!.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 80,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: VibrantSpacing.lg),
                                Text(
                                  'No achievements yet',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: VibrantSpacing.sm),
                                Text(
                                  'Complete lessons to unlock achievements!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._buildTierSections(theme, colorScheme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTierStat(int tier, ThemeData theme) {
    final count =
        _achievements?.where((a) => a.tier == tier).length ?? 0;
    final color = _getTierColor(tier);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.md),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            color: color,
            size: 24,
          ),
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
    );
  }

  Widget _buildFilterChip(String type, String label, IconData icon) {
    final isSelected = _filterType == type;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
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
        setState(() {
          _filterType = type;
        });
      },
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
    );
  }

  List<Widget> _buildTierSections(ThemeData theme, ColorScheme colorScheme) {
    final sections = <Widget>[];
    final achievementsByTier = _achievementsByTier;

    for (final tier in [4, 3, 2, 1]) {
      // Show highest tiers first
      final achievements = achievementsByTier[tier] ?? [];
      if (achievements.isEmpty) continue;

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
                    border: Border.all(
                      color: _getTierColor(tier),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: _getTierColor(tier),
                    size: 20,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Text(
                  '${_getTierName(tier)} (${achievements.length})',
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
              (context, index) {
                return _buildAchievementCard(
                  achievements[index],
                  theme,
                  colorScheme,
                );
              },
              childCount: achievements.length,
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

    return GestureDetector(
      onTap: () {
        _showAchievementDetails(achievement);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tierColor.withValues(alpha: 0.1),
              tierColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: tierColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: tierColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tierColor.withValues(alpha: 0.3),
                      tierColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: tierColor,
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

              // Title
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: VibrantSpacing.xs),

              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.sm,
                  vertical: VibrantSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  border: Border.all(color: tierColor),
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

              // Rewards
              if (achievement.xpReward > 0 || achievement.coinReward > 0) ...[
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
    showAchievementUnlock(
      context,
      achievementId: achievement.achievementId,
      title: achievement.title,
      description: achievement.description,
      icon: achievement.icon,
      tier: achievement.tier,
      xpReward: achievement.xpReward,
      coinReward: achievement.coinReward,
    );
  }
}
