import 'package:flutter/material.dart';

/// Shared section header used across vibrant and professional screens.
///
/// Provides a consistent title/subtitle layout with optional leading icon and
/// trailing action. Keeps typography aligned with the active theme.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.iconColor,
    this.action,
    this.padding,
    this.dense = false,
  });

  /// Section title displayed with the theme's title style.
  final String title;

  /// Optional supporting copy displayed underneath the title.
  final String? subtitle;

  /// Optional custom leading widget. When provided, [icon] is ignored.
  final Widget? leading;

  /// Optional icon displayed inside a circular container when [leading] is not
  /// supplied.
  final IconData? icon;

  /// Optional color override for the default icon avatar background.
  final Color? iconColor;

  /// Optional trailing action widget (e.g., button, hyperlink).
  final Widget? action;

  /// Optional padding applied around the header block.
  final EdgeInsetsGeometry? padding;

  /// When true, compact spacing is used between elements.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final horizontalGap = dense ? 12.0 : 16.0;
    final verticalGap = dense ? 6.0 : 10.0;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && icon != null) {
      leadingWidget = Container(
        width: dense ? 36 : 44,
        height: dense ? 36 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.12),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: dense ? 18 : 22,
          color: iconColor ?? colorScheme.primary,
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                SizedBox(width: horizontalGap),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (action != null) ...[SizedBox(width: horizontalGap), action!],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: verticalGap),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
