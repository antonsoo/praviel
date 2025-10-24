/// Premium text settings modal for Reader
library;

import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';

/// Beautiful text settings modal for reading customization
class PremiumTextSettings extends StatelessWidget {
  const PremiumTextSettings({
    super.key,
    required this.fontSize,
    required this.lineHeight,
    required this.showTransliteration,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onTransliterationToggled,
  });

  final double fontSize;
  final double lineHeight;
  final bool showTransliteration;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<bool> onTransliterationToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xxl),
        ),
      ),
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: VibrantSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'Reading Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Font size
          _buildSettingSection(
            context,
            'Font Size',
            Icons.text_fields_rounded,
            Text(
              '${fontSize.round()}pt',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          Slider(
            value: fontSize,
            min: 14,
            max: 32,
            divisions: 18,
            onChanged: (value) {
              HapticService.selection();
              onFontSizeChanged(value);
            },
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Line height
          _buildSettingSection(
            context,
            'Line Spacing',
            Icons.format_line_spacing_rounded,
            Text(
              '${lineHeight.toStringAsFixed(1)}x',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.secondary,
              ),
            ),
          ),
          Slider(
            value: lineHeight,
            min: 1.2,
            max: 2.5,
            divisions: 13,
            onChanged: (value) {
              HapticService.selection();
              onLineHeightChanged(value);
            },
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Transliteration toggle
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
            ),
            child: SwitchListTile(
              value: showTransliteration,
              onChanged: (value) {
                HapticService.light();
                onTransliterationToggled(value);
              },
              title: Text(
                'Show Transliteration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Display Latin script below Greek text',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(VibrantSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Sample preview
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  colorScheme.secondaryContainer.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  'Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος',
                  style: TextStyle(
                    fontSize: fontSize,
                    height: lineHeight,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (showTransliteration) ...[
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    'Mēnin aeide thea Pēlēiadeō Achilēos',
                    style: TextStyle(
                      fontSize: fontSize * 0.85,
                      height: lineHeight,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Close button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticService.light();
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget trailing,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(VibrantRadius.sm),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: VibrantSpacing.md),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  /// Show the settings modal
  static Future<void> show({
    required BuildContext context,
    required double fontSize,
    required double lineHeight,
    required bool showTransliteration,
    required ValueChanged<double> onFontSizeChanged,
    required ValueChanged<double> onLineHeightChanged,
    required ValueChanged<bool> onTransliterationToggled,
  }) {
    HapticService.light();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumTextSettings(
        fontSize: fontSize,
        lineHeight: lineHeight,
        showTransliteration: showTransliteration,
        onFontSizeChanged: onFontSizeChanged,
        onLineHeightChanged: onLineHeightChanged,
        onTransliterationToggled: onTransliterationToggled,
      ),
    );
  }
}
