import 'package:flutter/material.dart';
import '../services/lesson_history_store.dart';
import '../theme/professional_theme.dart';

/// PROFESSIONAL history page - clean timeline like GitHub commits
/// No fancy visualizations - just clear, scannable data
class ProHistoryPage extends StatefulWidget {
  const ProHistoryPage({super.key});

  @override
  State<ProHistoryPage> createState() => _ProHistoryPageState();
}

class _ProHistoryPageState extends State<ProHistoryPage> {
  final LessonHistoryStore _store = LessonHistoryStore();
  List<LessonHistoryEntry>? _entries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final entries = await _store.load();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('History', style: theme.textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colorScheme.outline),
        ),
      ),
      body: _loading
          ? _buildLoadingState(theme, colorScheme)
          : _buildContent(theme, colorScheme),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final entries = _entries ?? [];

    if (entries.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    // Calculate stats
    final totalLessons = entries.length;
    final perfectScores = entries.where((e) => e.score == 1.0).length;
    final avgScore =
        entries.map((e) => e.score).reduce((a, b) => a + b) / totalLessons;

    return CustomScrollView(
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(ProSpacing.xl),
            padding: const EdgeInsets.all(ProSpacing.xl),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(ProRadius.lg),
              border: Border.all(color: colorScheme.outline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: theme.textTheme.titleLarge),
                const SizedBox(height: ProSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        colorScheme,
                        '$totalLessons',
                        'Total Lessons',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        colorScheme,
                        '$perfectScores',
                        'Perfect Scores',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        colorScheme,
                        '${(avgScore * 100).toInt()}%',
                        'Average Score',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Activity list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            ProSpacing.xl,
            0,
            ProSpacing.xl,
            ProSpacing.xl,
          ),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: ProSpacing.md),
            itemBuilder: (context, index) {
              return _buildHistoryItem(theme, colorScheme, entries[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    ColorScheme colorScheme,
    String value,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.headlineMedium),
        const SizedBox(height: ProSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(
    ThemeData theme,
    ColorScheme colorScheme,
    LessonHistoryEntry entry,
  ) {
    final scorePercent = (entry.score * 100).toInt();
    final isExcellent = scorePercent >= 90;

    return Container(
      padding: const EdgeInsets.all(ProSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ProRadius.lg),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isExcellent
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: ProSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.textSnippet,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: ProSpacing.sm),
                    Row(
                      children: [
                        Text(
                          '${entry.correctCount}/${entry.totalTasks} correct',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: ProSpacing.md),
                        Text(
                          '•',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: ProSpacing.md),
                        Text(
                          _formatDate(entry.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: ProSpacing.md),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProSpacing.md,
                  vertical: ProSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isExcellent
                      ? colorScheme.tertiaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(ProRadius.sm),
                ),
                child: Text(
                  '$scorePercent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isExcellent
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: ProSpacing.lg),
            Text(
              'No lessons completed yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: ProSpacing.sm),
            Text(
              'Your completed lessons will appear here',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today at $hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
