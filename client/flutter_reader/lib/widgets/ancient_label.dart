import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/language.dart';

/// A widget that renders ancient language text with historically accurate
/// typography, scripts, and text direction (LTR/RTL).
///
/// This widget handles:
/// - Proper text direction (LTR for most, RTL for Hebrew, Aramaic, Avestan)
/// - Font family selection with fallbacks
/// - Ligatures and OpenType features
/// - Tooltips for reconstructed languages
class AncientLabel extends StatelessWidget {
  const AncientLabel({
    super.key,
    required this.language,
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
    this.showTooltip = true,
  });

  final LanguageInfo language;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    // Build the text widget with proper direction and fonts
    final textWidget = Directionality(
      textDirection: language.textDirection,
      child: Text(
        language.nativeName,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: _buildTextStyle(context),
      ),
    );

    // Wrap with tooltip if the language has one and showTooltip is true
    if (showTooltip && language.tooltip != null) {
      return Tooltip(
        message: language.tooltip!,
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextStyle _buildTextStyle(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyLarge;

    return baseStyle!.copyWith(
      fontFamily: language.primaryFont,
      fontFamilyFallback: language.fallbackFonts,
      fontFeatures: const [
        ui.FontFeature.enable('liga'), // Enable ligatures
        ui.FontFeature.enable('clig'), // Enable contextual ligatures
      ],
      height: 1.2, // Line height for better readability
    );
  }
}

/// A more compact version of AncientLabel for use in small spaces like chips
class AncientLabelCompact extends StatelessWidget {
  const AncientLabelCompact({
    super.key,
    required this.language,
    this.fontSize = 14.0,
    this.showTooltip = true,
  });

  final LanguageInfo language;
  final double fontSize;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    return AncientLabel(
      language: language,
      style: TextStyle(fontSize: fontSize),
      showTooltip: showTooltip,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A widget that shows both the flag emoji and the ancient script label
class LanguageChip extends StatelessWidget {
  const LanguageChip({
    super.key,
    required this.language,
    this.onTap,
    this.isSelected = false,
    this.showScript = true,
  });

  final LanguageInfo language;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showScript;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = isSelected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: chipColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flag emoji
              Text(
                language.flag,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              // Language name and script in ancient writing
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // English name
                  Text(
                    language.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showScript) ...[
                    const SizedBox(height: 2),
                    // Native script
                    AncientLabelCompact(
                      language: language,
                      fontSize: 12.0,
                    ),
                  ],
                ],
              ),
              // Coming soon badge
              if (language.comingSoon && !language.isAvailable) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soon',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
