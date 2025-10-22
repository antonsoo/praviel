import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language.dart';
import '../services/language_controller.dart';
import '../theme/vibrant_theme.dart';
import 'ancient_label.dart';

class LanguagePickerSheet extends ConsumerStatefulWidget {
  const LanguagePickerSheet({super.key, required this.currentLanguageCode});

  final String currentLanguageCode;

  static Future<LanguageInfo?> show({
    required BuildContext context,
    required String currentLanguageCode,
  }) {
    return showModalBottomSheet<LanguageInfo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) =>
          LanguagePickerSheet(currentLanguageCode: currentLanguageCode),
    );
  }

  @override
  ConsumerState<LanguagePickerSheet> createState() =>
      _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends ConsumerState<LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = ref.watch(languageMenuSectionsProvider);

    final filtered = sections.allOrdered.where((language) {
      if (_query.isEmpty) return true;
      final query = _query.toLowerCase();
      return language.name.toLowerCase().contains(query) ||
          language.nativeName.toLowerCase().contains(query) ||
          language.code.toLowerCase().contains(query);
    }).toList();

    final available = filtered.where((lang) => lang.isAvailable).toList();
    final upcoming = filtered.where((lang) => !lang.isAvailable).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VibrantSpacing.sm),
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a language',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  'Browse the full catalog in canonical order or search by name.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.md),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by language, native name, or code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.lg,
              ),
              children: [
                if (available.isNotEmpty) ...[
                  _buildSectionHeader(theme, 'Available now', available.length),
                  ...available.map(
                    (language) =>
                        _buildTile(context, theme, language, enabled: true),
                  ),
                ],
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: VibrantSpacing.lg),
                  _buildSectionHeader(theme, 'Coming soon', upcoming.length),
                  ...upcoming.map(
                    (language) =>
                        _buildTile(context, theme, language, enabled: false),
                  ),
                ],
                if (available.isEmpty && upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: VibrantSpacing.xl),
                    child: Center(
                      child: Text(
                        'No languages match "$_query"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: VibrantSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
      child: Text(
        '$title ($count)',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    ThemeData theme,
    LanguageInfo language, {
    required bool enabled,
  }) {
    final colorScheme = theme.colorScheme;
    final isSelected = language.code == widget.currentLanguageCode;
    final status = _statusLabel(language, enabled);

    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.xs),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
        ),
        tileColor: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        onTap: enabled
            ? () => Navigator.of(context).pop(language)
            : () => _showUnavailableMessage(context, language),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          child: Text(language.flag, style: theme.textTheme.titleLarge),
        ),
        title: Text(
          language.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: VibrantSpacing.xxs),
          child: AncientLabel(
            language: language,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.start,
            showTooltip: false,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != null) _StatusBadge(label: status),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: VibrantSpacing.xs),
                child: Icon(Icons.check_circle, color: colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  String? _statusLabel(LanguageInfo language, bool enabled) {
    if (!enabled) {
      return language.comingSoon ? 'Coming soon' : 'Planned';
    }
    if (!language.isFullCourse) {
      return 'Partial course';
    }
    return null;
  }

  void _showUnavailableMessage(BuildContext context, LanguageInfo language) {
    final messenger = ScaffoldMessenger.of(context);
    final statusLabel = _statusLabel(language, false) ?? 'Unavailable';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${language.name} is $statusLabel. Follow our roadmap for release updates.',
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.xs,
        vertical: VibrantSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
