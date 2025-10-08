import 'package:flutter/material.dart';
import '../services/progress_store.dart';
import '../theme/professional_theme.dart';
import '../theme/vibrant_animations.dart';

class ProgressDashboard extends StatefulWidget {
  const ProgressDashboard({super.key});

  @override
  State<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard> {
  final ProgressStore _store = ProgressStore();
  Map<String, dynamic>? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final data = await _store.load();
    if (mounted) {
      setState(() {
        _progress = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    final progress = _progress ?? {};
    final xp = progress['xpTotal'] as int? ?? 0;
    final streak = progress['streakDays'] as int? ?? 0;
    final lastLessonAt = progress['lastLessonAt'] as String?;

    if (xp == 0 && streak == 0) {
      // Don't show dashboard if no progress yet
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PulseCard(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(ProRadius.xl),
      padding: const EdgeInsets.all(ProSpacing.lg),
      elevation: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ProRadius.lg),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.emoji_events, color: Colors.white),
              ),
              const SizedBox(width: ProSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: ProSpacing.xs),
                    Text(
                      'Stay consistent to grow streaks and level up faster.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ProSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ProgressMetricCard(
                  icon: Icons.stars,
                  label: 'Total XP',
                  value: xp.toString(),
                  accentColor: colorScheme.primary,
                ),
              ),
              const SizedBox(width: ProSpacing.sm),
              Expanded(
                child: _ProgressMetricCard(
                  icon: Icons.local_fire_department,
                  label: 'Day streak',
                  value: streak.toString(),
                  accentColor: streak > 0
                      ? const Color(0xFFFF8A4C)
                      : colorScheme.outline,
                ),
              ),
            ],
          ),
          if (lastLessonAt != null) ...[
            const SizedBox(height: ProSpacing.sm),
            Text(
              'Last lesson: ${_formatTime(lastLessonAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (_) {
      return 'recently';
    }
  }
}

class _ProgressMetricCard extends StatelessWidget {
  const _ProgressMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(ProSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ProRadius.xl),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: ProSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: ProSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
