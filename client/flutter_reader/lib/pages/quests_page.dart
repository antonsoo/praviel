import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quests_api.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_animations.dart';
import 'quest_detail_page.dart';
import 'quest_create_page.dart';

/// Quests Page - Browse and track long-term goals
class QuestsPage extends ConsumerStatefulWidget {
  const QuestsPage({super.key, required this.questsApi});

  final QuestsApi questsApi;

  @override
  ConsumerState<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends ConsumerState<QuestsPage> {
  List<Quest> _quests = [];
  bool _loading = true;
  String? _error;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final quests = await widget.questsApi.listQuests(
        includeCompleted: _showCompleted,
      );
      setState(() {
        _quests = quests;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load quests: $e';
        _loading = false;
      });
    }
  }

  void _navigateToQuest(Quest quest) {
    HapticService.medium();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuestDetailPage(questsApi: widget.questsApi, quest: quest),
      ),
    ).then((_) => _loadQuests());
  }

  void _navigateToCreate() {
    HapticService.medium();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestCreatePage(questsApi: widget.questsApi),
      ),
    ).then((created) {
      if (created == true) {
        _loadQuests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeQuests = _quests.where((q) => !q.isCompleted).toList();
    final completedQuests = _quests.where((q) => q.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            ),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
              _loadQuests();
            },
            tooltip: _showCompleted ? 'Hide Completed' : 'Show Completed',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreate,
            tooltip: 'Create Quest',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme, colorScheme, activeQuests, completedQuests),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Quest> activeQuests,
    List<Quest> completedQuests,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQuests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_quests.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active Quests
          if (activeQuests.isNotEmpty) ...[
            Text(
              'Active Quests',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...activeQuests.map((quest) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuestCard(theme, colorScheme, quest),
              );
            }),
          ],

          // Completed Quests
          if (_showCompleted && completedQuests.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Completed Quests',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...completedQuests.map((quest) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuestCard(theme, colorScheme, quest),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SlideInFromBottom(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'No Quests Yet',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a quest to set long-term goals',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Quest'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Quest quest,
  ) {
    final progress = quest.targetValue > 0
        ? quest.currentProgress / quest.targetValue
        : 0.0;
    final daysLeft = quest.expiresAt?.difference(DateTime.now()).inDays ?? 999;
    final isExpiring = daysLeft <= 3 && !quest.isCompleted;

    return ScaleIn(
      child: Card(
        elevation: quest.isCompleted ? 1 : 2,
        child: InkWell(
          onTap: () => _navigateToQuest(quest),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Quest type icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getQuestColor(
                          quest.questType,
                          colorScheme,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getQuestIcon(quest.questType),
                        color: _getQuestColor(quest.questType, colorScheme),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: quest.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (quest.description != null &&
                              quest.description!.isNotEmpty)
                            Text(
                              quest.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (quest.isCompleted)
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                        size: 28,
                      )
                    else if (isExpiring)
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error,
                        size: 28,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
                if (!quest.isCompleted) ...[
                  SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getQuestColor(quest.questType, colorScheme),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Progress text and time left
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${quest.currentProgress} / ${quest.targetValue} ${_getQuestUnit(quest.questType)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: quest.isCompleted ? colorScheme.primary : null,
                      ),
                    ),
                    if (!quest.isCompleted)
                      Text(
                        daysLeft > 0 ? '$daysLeft days left' : 'Expired',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isExpiring
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isExpiring ? FontWeight.bold : null,
                        ),
                      )
                    else if (quest.isCompleted && quest.completedAt != null)
                      Text(
                        'Completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),

                if (quest.difficultyTier != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      backgroundColor: _difficultyColor(
                        quest.difficultyTier!,
                        colorScheme,
                      ).withOpacity(0.12),
                      avatar: Icon(
                        _difficultyIcon(quest.difficultyTier!),
                        size: 16,
                        color: _difficultyColor(
                          quest.difficultyTier!,
                          colorScheme,
                        ),
                      ),
                      label: Text(
                        _formatDifficultyLabel(quest.difficultyTier!),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _difficultyColor(
                            quest.difficultyTier!,
                            colorScheme,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],

                // Rewards
                if (!quest.isCompleted) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${quest.coinReward} coins',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.bolt, size: 16, color: colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${quest.xpReward} XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getQuestIcon(String type) {
    switch (type) {
      case 'daily_streak':
        return Icons.local_fire_department;
      case 'xp_milestone':
        return Icons.bolt;
      case 'lesson_count':
        return Icons.school;
      case 'skill_mastery':
        return Icons.workspace_premium;
      default:
        return Icons.flag;
    }
  }

  Color _getQuestColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'daily_streak':
        return Colors.orange;
      case 'xp_milestone':
        return colorScheme.secondary;
      case 'lesson_count':
        return colorScheme.primary;
      case 'skill_mastery':
        return Colors.purple;
      default:
        return colorScheme.primary;
    }
  }

  String _getQuestUnit(String type) {
    switch (type) {
      case 'daily_streak':
        return 'days';
      case 'xp_milestone':
        return 'XP';
      case 'lesson_count':
        return 'lessons';
      case 'skill_mastery':
        return 'points';
      default:
        return 'points';
    }
  }

  Color _difficultyColor(String tier, ColorScheme colorScheme) {
    switch (tier) {
      case 'easy':
        return Colors.green.shade600;
      case 'standard':
        return colorScheme.primary;
      case 'hard':
        return Colors.orange.shade600;
      case 'legendary':
        return Colors.purple.shade600;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _difficultyIcon(String tier) {
    switch (tier) {
      case 'easy':
        return Icons.spa;
      case 'standard':
        return Icons.trending_up;
      case 'hard':
        return Icons.local_fire_department;
      case 'legendary':
        return Icons.auto_awesome;
      default:
        return Icons.flag;
    }
  }

  String _formatDifficultyLabel(String tier) {
    switch (tier) {
      case 'easy':
        return 'Easy • Warm-up';
      case 'standard':
        return 'Standard Challenge';
      case 'hard':
        return 'Hard • Heroic Effort';
      case 'legendary':
        return 'Legendary • Epic Quest';
      default:
        if (tier.isEmpty) {
          return 'Custom Quest';
        }
        final capitalized = tier[0].toUpperCase() + tier.substring(1);
        return '$capitalized Quest';
    }
  }
}
