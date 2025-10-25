import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/advanced_micro_interactions.dart';

/// Modern toast notifications for 2025 UI standards
/// Glassmorphic, animated, with icons and actions

class ToastNotification {
  static OverlayEntry? _currentToast;

  static void show({
    required BuildContext context,
    required String message,
    String? title,
    IconData? icon,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Remove existing toast
    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        title: title,
        icon: icon,
        type: type,
        position: position,
        onTap: onTap,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          overlayEntry.remove();
          if (_currentToast == overlayEntry) {
            _currentToast = null;
          }
        },
      ),
    );

    _currentToast = overlayEntry;
    overlay.insert(overlayEntry);

    // Auto dismiss
    Future.delayed(duration, () {
      if (_currentToast == overlayEntry) {
        overlayEntry.remove();
        _currentToast = null;
      }
    });

    // Haptic feedback
    switch (type) {
      case ToastType.success:
        AdvancedHaptics.success();
        break;
      case ToastType.error:
        AdvancedHaptics.error();
        break;
      case ToastType.warning:
        AdvancedHaptics.warning();
        break;
      default:
        AdvancedHaptics.light();
    }
  }

  static void dismiss() {
    _currentToast?.remove();
    _currentToast = null;
  }
}

enum ToastType { info, success, warning, error }

enum ToastPosition { top, bottom, center }

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.position,
    required this.onDismiss,
    this.title,
    this.icon,
    this.onTap,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final ToastType type;
  final ToastPosition position;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.moderate,
    );

    final begin = _getBeginOffset();
    _slideAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.playful));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  Offset _getBeginOffset() {
    switch (widget.position) {
      case ToastPosition.top:
        return const Offset(0, -1);
      case ToastPosition.bottom:
        return const Offset(0, 1);
      case ToastPosition.center:
        return const Offset(0, 0.5);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case ToastType.success:
        return colorScheme.tertiaryContainer;
      case ToastType.error:
        return colorScheme.errorContainer;
      case ToastType.warning:
        return Colors.orange.shade100;
      case ToastType.info:
        return colorScheme.primaryContainer;
    }
  }

  Color _getForegroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case ToastType.success:
        return colorScheme.onTertiaryContainer;
      case ToastType.error:
        return colorScheme.onErrorContainer;
      case ToastType.warning:
        return Colors.orange.shade900;
      case ToastType.info:
        return colorScheme.onPrimaryContainer;
    }
  }

  IconData _getDefaultIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    double topPosition;
    double? bottomPosition;

    switch (widget.position) {
      case ToastPosition.top:
        topPosition = topPadding + VibrantSpacing.lg;
        break;
      case ToastPosition.bottom:
        topPosition = 0;
        bottomPosition = bottomPadding + VibrantSpacing.lg;
        break;
      case ToastPosition.center:
        topPosition = mediaQuery.size.height / 2 - 50;
        break;
    }

    return Positioned(
      top: widget.position != ToastPosition.bottom ? topPosition : null,
      bottom: bottomPosition,
      left: VibrantSpacing.lg,
      right: VibrantSpacing.lg,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onHorizontalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx.abs() > 300) {
                _dismiss();
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(context).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    border: Border.all(
                      color: _getForegroundColor(context).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(VibrantSpacing.sm),
                        decoration: BoxDecoration(
                          color: _getForegroundColor(context)
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(VibrantRadius.md),
                        ),
                        child: Icon(
                          widget.icon ?? _getDefaultIcon(),
                          color: _getForegroundColor(context),
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
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _getForegroundColor(context),
                                ),
                              ),
                              const SizedBox(height: VibrantSpacing.xxs),
                            ],
                            Text(
                              widget.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _getForegroundColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.actionLabel != null &&
                          widget.onAction != null) ...[
                        const SizedBox(width: VibrantSpacing.md),
                        TextButton(
                          onPressed: () {
                            widget.onAction!();
                            _dismiss();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: _getForegroundColor(context),
                            padding: const EdgeInsets.symmetric(
                              horizontal: VibrantSpacing.md,
                              vertical: VibrantSpacing.sm,
                            ),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      const SizedBox(width: VibrantSpacing.sm),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: _getForegroundColor(context)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Snackbar-style notification at bottom
class SnackNotification {
  static void show({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: VibrantSpacing.md),
            ],
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }
}
