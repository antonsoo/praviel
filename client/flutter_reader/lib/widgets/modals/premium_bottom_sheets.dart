import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/advanced_micro_interactions.dart';

/// Modern bottom sheet designs for 2025 UI standards
/// Glassmorphic, draggable, with smooth animations

/// Premium bottom sheet with drag handle and blur
class PremiumBottomSheet extends StatelessWidget {
  const PremiumBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.backgroundColor,
    this.maxHeight = 0.9,
    this.initialHeight = 0.6,
    this.enableBlur = true,
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;
  final Color? backgroundColor;
  final double maxHeight;
  final double initialHeight;
  final bool enableBlur;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showDragHandle = true,
    Color? backgroundColor,
    double maxHeight = 0.9,
    double initialHeight = 0.6,
    bool enableBlur = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => PremiumBottomSheet(
        title: title,
        showDragHandle: showDragHandle,
        backgroundColor: backgroundColor,
        maxHeight: maxHeight,
        initialHeight: initialHeight,
        enableBlur: enableBlur,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: initialHeight,
      minChildSize: 0.3,
      maxChildSize: maxHeight,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.xxl),
            ),
            boxShadow: VibrantShadow.xl(colorScheme),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.xxl),
            ),
            child: enableBlur
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: _buildContent(
                      context,
                      theme,
                      colorScheme,
                      scrollController,
                    ),
                  )
                : _buildContent(
                    context,
                    theme,
                    colorScheme,
                    scrollController,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    ScrollController scrollController,
  ) {
    return Column(
      children: [
        // Drag handle
        if (showDragHandle)
          Padding(
            padding: const EdgeInsets.only(top: VibrantSpacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        // Title
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VibrantSpacing.xl,
              VibrantSpacing.lg,
              VibrantSpacing.xl,
              VibrantSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              VibrantSpacing.xl,
              VibrantSpacing.md,
              VibrantSpacing.xl,
              VibrantSpacing.xxxl,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Expandable bottom sheet with sections
class ExpandableBottomSheet extends StatefulWidget {
  const ExpandableBottomSheet({
    super.key,
    required this.sections,
    this.title,
  });

  final List<BottomSheetSection> sections;
  final String? title;

  @override
  State<ExpandableBottomSheet> createState() => _ExpandableBottomSheetState();
}

class _ExpandableBottomSheetState extends State<ExpandableBottomSheet> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),
        ],
        for (int i = 0; i < widget.sections.length; i++)
          AnimatedContainer(
            duration: VibrantDuration.normal,
            curve: VibrantCurve.smooth,
            margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedIndex = _expandedIndex == i ? null : i;
                    });
                    AdvancedHaptics.light();
                  },
                  borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(VibrantSpacing.lg),
                    child: Row(
                      children: [
                        if (widget.sections[i].icon != null) ...[
                          Icon(
                            widget.sections[i].icon,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: VibrantSpacing.md),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.sections[i].title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.sections[i].subtitle != null) ...[
                                const SizedBox(height: VibrantSpacing.xxs),
                                Text(
                                  widget.sections[i].subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          duration: VibrantDuration.normal,
                          turns: _expandedIndex == i ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VibrantSpacing.lg,
                      0,
                      VibrantSpacing.lg,
                      VibrantSpacing.lg,
                    ),
                    child: widget.sections[i].content,
                  ),
                  crossFadeState: _expandedIndex == i
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: VibrantDuration.normal,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class BottomSheetSection {
  const BottomSheetSection({
    required this.title,
    required this.content,
    this.icon,
    this.subtitle,
  });

  final String title;
  final Widget content;
  final IconData? icon;
  final String? subtitle;
}

/// Success bottom sheet with celebration
class SuccessBottomSheet extends StatefulWidget {
  const SuccessBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.check_circle_rounded,
    this.actionLabel = 'Continue',
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String actionLabel;
  final VoidCallback? onAction;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle_rounded,
    String actionLabel = 'Continue',
    VoidCallback? onAction,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SuccessBottomSheet(
        title: title,
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  @override
  State<SuccessBottomSheet> createState() => _SuccessBottomSheetState();
}

class _SuccessBottomSheetState extends State<SuccessBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.celebration,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: VibrantCurve.playful),
    );
    _controller.forward();
    AdvancedHaptics.success();
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        VibrantSpacing.xl,
        VibrantSpacing.xl,
        VibrantSpacing.xl,
        MediaQuery.of(context).padding.bottom + VibrantSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),
          Text(
            widget.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            widget.message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VibrantSpacing.xl),
          PremiumButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAction?.call();
            },
            gradient: VibrantTheme.successGradient,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.actionLabel),
                const SizedBox(width: VibrantSpacing.sm),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action bottom sheet with multiple options
class ActionBottomSheet extends StatelessWidget {
  const ActionBottomSheet({
    super.key,
    required this.title,
    required this.actions,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<BottomSheetAction> actions;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<BottomSheetAction> actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ActionBottomSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        VibrantSpacing.lg,
        VibrantSpacing.xl,
        VibrantSpacing.lg,
        MediaQuery.of(context).padding.bottom + VibrantSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: VibrantSpacing.lg),
          for (final action in actions)
            SlideInFromBottom(
              delay: Duration(milliseconds: 50 * actions.indexOf(action)),
              child: ListTile(
                leading: action.icon != null
                    ? Container(
                        padding: const EdgeInsets.all(VibrantSpacing.sm),
                        decoration: BoxDecoration(
                          color: (action.isDestructive
                                  ? colorScheme.errorContainer
                                  : colorScheme.primaryContainer)
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(VibrantRadius.md),
                        ),
                        child: Icon(
                          action.icon,
                          color: action.isDestructive
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      )
                    : null,
                title: Text(
                  action.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: action.isDestructive ? colorScheme.error : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: action.subtitle != null
                    ? Text(action.subtitle!)
                    : null,
                trailing: action.trailing,
                onTap: () {
                  AdvancedHaptics.light();
                  Navigator.of(context).pop();
                  action.onTap();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class BottomSheetAction {
  const BottomSheetAction({
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.trailing,
    this.isDestructive = false,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final bool isDestructive;
}
