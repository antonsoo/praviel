import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';

/// Glassmorphism effect - modern frosted glass UI
/// Used for overlays, cards, modals with depth and elegance

class GlassMorphism extends StatelessWidget {
  const GlassMorphism({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.border = true,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final bool border;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(VibrantRadius.lg);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: opacity)
                : Colors.white.withValues(alpha: opacity * 0.8),
            borderRadius: radius,
            border: border
                ? Border.all(
                    color:
                        borderColor ??
                        (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.4)),
                    width: borderWidth,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass card - frosted glass card component
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VibrantSpacing.md),
    this.margin,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(VibrantRadius.lg);

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: GlassMorphism(
            blur: blur,
            opacity: opacity,
            borderRadius: radius,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Glass bottom sheet - modern bottom sheet with glass effect
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VibrantSpacing.lg),
    this.showHandle = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return GlassMorphism(
      blur: 15.0,
      opacity: 0.15,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(VibrantRadius.xxl),
      ),
      child: Container(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle) ...[
              const SizedBox(height: VibrantSpacing.xs),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: VibrantSpacing.lg),
            ],
            child,
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(VibrantSpacing.lg),
    bool showHandle = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      builder: (context) => GlassBottomSheet(
        padding: padding,
        showHandle: showHandle,
        child: child,
      ),
    );
  }
}

/// Glass app bar - frosted glass app bar
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.height = kToolbarHeight,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double blur;
  final double opacity;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return GlassMorphism(
      blur: blur,
      opacity: opacity,
      border: false,
      child: SafeArea(
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.sm),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: VibrantSpacing.sm),
              if (title != null) Expanded(child: title!),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass modal - full-screen modal with glass background
class GlassModal extends StatelessWidget {
  const GlassModal({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VibrantSpacing.xl),
    this.blur = 20.0,
    this.opacity = 0.15,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(VibrantSpacing.lg),
      child: GlassMorphism(
        blur: blur,
        opacity: opacity,
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(VibrantSpacing.xl),
    double blur = 20.0,
    double opacity = 0.15,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassModal(
        padding: padding,
        blur: blur,
        opacity: opacity,
        child: child,
      ),
    );
  }
}

/// Glass button - button with glass effect
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.blur = 8.0,
    this.opacity = 0.1,
    this.padding = const EdgeInsets.symmetric(
      horizontal: VibrantSpacing.lg,
      vertical: VibrantSpacing.md,
    ),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        child: GlassMorphism(
          blur: blur,
          opacity: opacity,
          borderRadius: BorderRadius.circular(VibrantRadius.md),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Glass container - reusable glass container
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: GlassMorphism(
        blur: blur,
        opacity: opacity,
        borderRadius: borderRadius,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
