import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quests_api.dart';
import '../services/haptic_service.dart';

/// Quest Detail Page - View and manage a specific quest
class QuestDetailPage extends ConsumerStatefulWidget {
  const QuestDetailPage({
    super.key,
    required this.questsApi,
    required this.quest,
  });

  final QuestsApi questsApi;
  final Quest quest;

  @override
  ConsumerState<QuestDetailPage> createState() => _QuestDetailPageState();
}

class _QuestDetailPageState extends ConsumerState<QuestDetailPage> {
  late Quest _quest;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _quest = widget.quest;
  }

  Future<void> _completeQuest() async {
    setState(() => _loading = true);

    try {
      final response = await widget.questsApi.completeQuest(_quest.id);

      HapticService.success();

      if (mounted) {
        final achievementText =
            (response.achievementEarned != null &&
                response.achievementEarned!.isNotEmpty)
            ? '\nAchievement unlocked: ${response.achievementEarned}'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quest completed! +${response.coinsEarned} coins, +${response.xpEarned} XP$achievementText',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to complete quest: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteQuest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      await widget.questsApi.abandonQuest(_quest.id);

      HapticService.success();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete quest: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _quest.targetValue > 0
        ? _quest.currentProgress / _quest.targetValue
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Details'),
        actions: [
          if (!_quest.isCompleted)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _loading ? null : _deleteQuest,
              tooltip: 'Delete Quest',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getQuestColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getQuestIcon(),
                          color: _getQuestColor(),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _quest.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_quest.description != null &&
                                _quest.description!.isNotEmpty)
                              Text(
                                _quest.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress
                  Text(
                    'Progress',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 12,
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getQuestColor(),
                      ),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_quest.currentProgress} / ${_quest.targetValue} ${_getQuestUnit()}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getQuestColor(),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% complete',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quest Info',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoRow(
                    theme,
                    colorScheme,
                    Icons.category,
                    'Type',
                    _getQuestTypeName(),
                  ),
                  const SizedBox(height: 12),

                  if (_quest.difficultyTier != null) ...[
                    _buildInfoRow(
                      theme,
                      colorScheme,
                      Icons.insights,
                      'Difficulty',
                      _formatDifficultyLabel(_quest.difficultyTier!),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_quest.expiresAt != null)
                    _buildInfoRow(
                      theme,
                      colorScheme,
                      Icons.calendar_today,
                      'Expires',
                      _formatDate(_quest.expiresAt!),
                    ),
                  const SizedBox(height: 12),

                  if (_quest.completedAt != null) ...[
                    _buildInfoRow(
                      theme,
                      colorScheme,
                      Icons.check_circle,
                      'Completed',
                      _formatDate(_quest.completedAt!),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildInfoRow(
                    theme,
                    colorScheme,
                    Icons.stars,
                    'Coin Reward',
                    '${_quest.coinReward} coins',
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    theme,
                    colorScheme,
                    Icons.bolt,
                    'XP Reward',
                    '${_quest.xpReward} XP',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Complete button
          if (!_quest.isCompleted &&
              _quest.currentProgress >= _quest.targetValue)
            FilledButton.icon(
              onPressed: _loading ? null : _completeQuest,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('Complete Quest'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getQuestIcon() {
    switch (_quest.questType) {
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

  Color _getQuestColor() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_quest.questType) {
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

  String _getQuestUnit() {
    switch (_quest.questType) {
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

  String _getQuestTypeName() {
    switch (_quest.questType) {
      case 'daily_streak':
        return 'Daily Streak';
      case 'xp_milestone':
        return 'XP Milestone';
      case 'lesson_count':
        return 'Lesson Count';
      case 'skill_mastery':
        return 'Skill Mastery';
      default:
        return _quest.questType;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return '${difference.inDays.abs()} days ago';
    } else {
      return 'in ${difference.inDays} days';
    }
  }
}
