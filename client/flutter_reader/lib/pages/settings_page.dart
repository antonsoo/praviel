import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import '../services/lesson_history_store.dart';
import '../services/progress_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';

class SettingsPage extends frp.ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, frp.WidgetRef ref) {
    final spacing = ReaderTheme.spacingOf(context);
    final themeModeAsync = ref.watch(themeControllerProvider);
    final themeMode = themeModeAsync.value ?? ThemeMode.light;

    return ListView(
      padding: EdgeInsets.all(spacing.md),
      children: [
        _SectionHeader(title: 'Appearance', spacing: spacing),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 16),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 16),
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto, size: 16),
                      label: Text('Auto'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selected) {
                    ref.read(themeControllerProvider.notifier).setTheme(selected.first);
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        _SectionHeader(title: 'Data', spacing: spacing),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear history'),
                subtitle: const Text('Delete all lesson history'),
                onTap: () => _showClearHistoryDialog(context, spacing),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset progress'),
                subtitle: const Text('Clear XP and streak data'),
                onTap: () => _showResetProgressDialog(context, spacing),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        _SectionHeader(title: 'About', spacing: spacing),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Open source'),
                subtitle: const Text('Built with Flutter'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Could open GitHub repo
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showClearHistoryDialog(BuildContext context, ReaderSpacing spacing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This will permanently delete all lesson history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await LessonHistoryStore().clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }

  Future<void> _showResetProgressDialog(BuildContext context, ReaderSpacing spacing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This will reset your XP and streak to zero. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ProgressStore().reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.spacing});

  final String title;
  final ReaderSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: spacing.sm,
        bottom: spacing.xs,
        top: spacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
