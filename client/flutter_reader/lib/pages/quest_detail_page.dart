import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quests_api.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_cards.dart';
import '../widgets/premium_snackbars.dart';

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

class _QuestDetailPageState extends ConsumerState<QuestDetailPage>
    with SingleTickerProviderStateMixin {
  late Quest _quest;
  bool _loading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _quest = widget.quest;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeQuest() async {
    setState(() => _loading = true);

    try {
      final response = await widget.questsApi.completeQuest(_quest.id);

      HapticService.celebrate();

      if (mounted) {
        final achievementText =
            (response.achievementEarned != null &&
                response.achievementEarned!.isNotEmpty)
            ? ' • ${response.achievementEarned} unlocked!'
            : '';

        PremiumSnackBar.success(
          context,
          title: 'Quest Completed! 🎉',
          message: '+${response.coinsEarned} coins, +${response.xpEarned} XP$achievementText',
          duration: const Duration(seconds: 5),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        PremiumSnackBar.error(
          context,
          title: 'Error',
          message: 'Failed to complete quest: $e',
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteQuest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Quest?'),
        content: const Text('This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.light();
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              HapticService.medium();
              Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
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
        PremiumSnackBar.success(
          context,
          title: 'Quest Deleted',
          message: 'Quest has been removed',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        PremiumSnackBar.error(
          context,
          title: 'Error',
          message: 'Failed to delete quest: $e',
        );
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
              onPressed: _loading
                  ? null
                  : () {
                      HapticService.light();
                      _deleteQuest();
                    },
              tooltip: 'Delete Quest',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          children: [
          // Header Card
          GlowCard(
            animated: !_quest.isCompleted,
            glowColor: _getQuestColor(),
            padding: const EdgeInsets.all(VibrantSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(VibrantSpacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getQuestColor(),
                              _getQuestColor().withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(VibrantRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: _getQuestColor().withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getQuestIcon(),
                          color: Colors.white,
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
                  const SizedBox(height: VibrantSpacing.sm),
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      child: Stack(
                        children: [
                          LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getQuestColor(),
                            ),
                            minHeight: 16,
                          ),
                          if (progress >= 1.0)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getQuestColor().withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.3),
                                    _getQuestColor().withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.sm),
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

          const SizedBox(height: VibrantSpacing.lg),

          // Stats Card
          ElevatedCard(
            elevation: 2,
            padding: const EdgeInsets.all(VibrantSpacing.lg),
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

          const SizedBox(height: VibrantSpacing.xxl),

          // Complete button
          if (!_quest.isCompleted &&
              _quest.currentProgress >= _quest.targetValue)
            PremiumButton(
              onPressed: _loading
                  ? null
                  : () {
                      HapticService.heavy();
                      _completeQuest();
                    },
              backgroundColor: Colors.green.shade600,
              height: 64,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 28),
                        SizedBox(width: 12),
                        Text('Complete Quest'),
                      ],
                    ),
            ),
        ],
        ),
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
