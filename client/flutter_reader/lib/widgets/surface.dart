import 'package:flutter/material.dart';

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.elevation = 'medium',
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final String elevation; // 'low', 'medium', 'high'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Premium shadow system based on elevation
    List<BoxShadow> getShadows() {
      final baseColor = isDark ? Colors.black : const Color(0xFF101828);
      switch (elevation) {
        case 'low':
          return [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: baseColor.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];
        case 'high':
          return [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: baseColor.withValues(alpha: 0.08),
              blurRadius: 48,
              offset: const Offset(0, 16),
            ),
          ];
        default: // medium
          return [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: baseColor.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ];
      }
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (backgroundColor ?? theme.colorScheme.surface)
            : null,
        borderRadius: BorderRadius.circular(
          20,
        ), // Increased from 16 for smoother look
        boxShadow: getShadows(),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
