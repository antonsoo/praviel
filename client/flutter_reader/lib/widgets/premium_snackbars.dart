import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';

/// Premium snackbar system with beautiful animations and icons
class PremiumSnackBar {
  /// Show success snackbar
  static void success(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _show(
      context,
      message: message,
      title: title,
      duration: duration,
      onTap: onTap,
      type: _SnackBarType.success,
    );
  }

  /// Show error snackbar
  static void error(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _show(
      context,
      message: message,
      title: title,
      duration: duration,
      onTap: onTap,
      type: _SnackBarType.error,
    );
  }

  /// Show warning snackbar
  static void warning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _show(
      context,
      message: message,
      title: title,
      duration: duration,
      onTap: onTap,
      type: _SnackBarType.warning,
    );
  }

  /// Show info snackbar
  static void info(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _show(
      context,
      message: message,
      title: title,
      duration: duration,
      onTap: onTap,
      type: _SnackBarType.info,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    String? title,
    required Duration duration,
    VoidCallback? onTap,
    required _SnackBarType type,
  }) {
    HapticService.light();

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _PremiumSnackBarWidget(
        message: message,
        title: title,
        type: type,
        onTap: onTap,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

enum _SnackBarType { success, error, warning, info }

class _PremiumSnackBarWidget extends StatefulWidget {
  const _PremiumSnackBarWidget({
    required this.message,
    this.title,
    required this.type,
    this.onTap,
  });

  final String message;
  final String? title;
  final _SnackBarType type;
  final VoidCallback? onTap;

  @override
  State<_PremiumSnackBarWidget> createState() =>
      _PremiumSnackBarWidgetState();
}

class _PremiumSnackBarWidgetState extends State<_PremiumSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(ColorScheme colorScheme) {
    switch (widget.type) {
      case _SnackBarType.success:
        return colorScheme.tertiary;
      case _SnackBarType.error:
        return colorScheme.error;
      case _SnackBarType.warning:
        return const Color(0xFFF59E0B);
      case _SnackBarType.info:
        return colorScheme.primary;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case _SnackBarType.success:
        return Icons.check_circle_rounded;
      case _SnackBarType.error:
        return Icons.error_rounded;
      case _SnackBarType.warning:
        return Icons.warning_rounded;
      case _SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _getColor(colorScheme);
    final icon = _getIcon();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.sm),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null) ...[
                            Text(
                              widget.title!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.xxs),
                          ],
                          Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating toast - minimal notification at bottom
class FloatingToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    bool haptic = true,
  }) {
    if (haptic) {
      HapticService.light();
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _FloatingToastWidget(
        message: message,
        icon: icon,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

class _FloatingToastWidget extends StatefulWidget {
  const _FloatingToastWidget({
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  State<_FloatingToastWidget> createState() => _FloatingToastWidgetState();
}

class _FloatingToastWidgetState extends State<_FloatingToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      left: 32,
      right: 32,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.symmetric(
                horizontal: VibrantSpacing.lg,
                vertical: widget.icon != null
                    ? VibrantSpacing.md
                    : VibrantSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: colorScheme.onInverseSurface,
                      size: 20,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
