import 'package:flutter/material.dart';
import '../../utils/haptic_feedback.dart';

/// Accessible button with proper semantics and haptic feedback
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.hapticFeedback = true,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final bool hapticFeedback;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      hint: semanticHint,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () async {
                if (hapticFeedback) {
                  await AppHaptics.light();
                }
                onPressed!();
              },
        style: style,
        child: child,
      ),
    );
  }
}

/// Accessible icon button
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.hint,
    this.hapticFeedback = true,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String label;
  final String? hint;
  final bool hapticFeedback;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      hint: hint,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed == null
            ? null
            : () async {
                if (hapticFeedback) {
                  await AppHaptics.light();
                }
                onPressed!();
              },
        tooltip: tooltip ?? label,
      ),
    );
  }
}

/// Accessible card with tap feedback
class AccessibleCard extends StatelessWidget {
  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.hapticFeedback = true,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final bool hapticFeedback;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: semanticLabel,
      hint: semanticHint,
      child: Card(
        margin: margin,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () async {
                  if (hapticFeedback) {
                    await AppHaptics.light();
                  }
                  onTap!();
                },
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Accessible progress indicator with semantic updates
class AccessibleProgressIndicator extends StatelessWidget {
  const AccessibleProgressIndicator({
    super.key,
    required this.value,
    required this.label,
    this.min = 0,
    this.max = 100,
  });

  final double value;
  final String label;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final percentage = ((value - min) / (max - min) * 100).round();

    return Semantics(
      label: label,
      value: '$percentage%',
      child: LinearProgressIndicator(
        value: (value - min) / (max - min),
      ),
    );
  }
}

/// Accessible toggle button
class AccessibleToggle extends StatelessWidget {
  const AccessibleToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.enabledHint,
    this.disabledHint,
    this.hapticFeedback = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? enabledHint;
  final String? disabledHint;
  final bool hapticFeedback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: label,
      hint: value ? enabledHint : disabledHint,
      child: Switch(
        value: value,
        onChanged: onChanged == null
            ? null
            : (newValue) async {
                if (hapticFeedback) {
                  await AppHaptics.selection();
                }
                onChanged!(newValue);
              },
      ),
    );
  }
}

/// Accessible list tile
class AccessibleListTile extends StatelessWidget {
  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.hapticFeedback = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final bool hapticFeedback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: semanticLabel ?? title,
      hint: semanticHint,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap == null
            ? null
            : () async {
                if (hapticFeedback) {
                  await AppHaptics.light();
                }
                onTap!();
              },
      ),
    );
  }
}
