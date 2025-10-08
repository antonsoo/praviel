import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_reader/theme/vibrant_theme.dart';

/// Destination data used by [ReaderShell] to render navigation controls.
class ReaderShellDestination {
  const ReaderShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// High-level layout widget that provides a vibrant background, adaptive
/// navigation (bottom bar vs. navigation rail), and a glassmorphic top bar.
class ReaderShell extends StatelessWidget {
  const ReaderShell({
    super.key,
    required this.title,
    required this.actions,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.fab,
  });

  final String title;
  final List<Widget> actions;
  final List<ReaderShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final bool useRail = constraints.maxWidth >= 1100;
        final bool extendRail = constraints.maxWidth >= 1320;
        final bool compactTopBar = constraints.maxWidth < 720;
        final double horizontalPadding;
        if (constraints.maxWidth < 520) {
          horizontalPadding = VibrantSpacing.md;
        } else if (constraints.maxWidth < 960) {
          horizontalPadding = VibrantSpacing.lg;
        } else {
          horizontalPadding = VibrantSpacing.xl;
        }
        final double topPadding = useRail
            ? VibrantSpacing.xl
            : VibrantSpacing.lg;
        final double bottomPadding = useRail
            ? VibrantSpacing.xl
            : VibrantSpacing.lg;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              // Soft gradient backdrop with a subtle halo for visual depth.
              _BackgroundHalo(colorScheme: colorScheme),
              Positioned.fill(
                child: SafeArea(
                  bottom: !useRail,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: useRail
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReaderNavigationRail(
                                destinations: destinations,
                                selectedIndex: selectedIndex,
                                onDestinationSelected: onDestinationSelected,
                                extended: extendRail,
                              ),
                              const SizedBox(width: VibrantSpacing.xl),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ReaderTopBar(
                                      title: title,
                                      actions: actions,
                                      compact: false,
                                    ),
                                    const SizedBox(height: VibrantSpacing.lg),
                                    Expanded(
                                      child: _SurfaceContainer(child: body),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              ReaderTopBar(
                                title: title,
                                actions: actions,
                                compact: compactTopBar,
                              ),
                              const SizedBox(height: VibrantSpacing.lg),
                              Expanded(child: _SurfaceContainer(child: body)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : ReaderBottomNavigation(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                ),
          floatingActionButton: fab,
          floatingActionButtonLocation: useRail
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}

class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.title,
    required this.actions,
    required this.compact,
  });

  final String title;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Interleave spacing between actions without trailing gaps.
    final effectiveActions = <Widget>[];
    for (final action in actions) {
      if (effectiveActions.isNotEmpty) {
        effectiveActions.add(const SizedBox(width: VibrantSpacing.sm));
      }
      effectiveActions.add(action);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        compact ? VibrantRadius.lg : VibrantRadius.xl,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: compact ? 64 : 72,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? VibrantSpacing.lg : VibrantSpacing.xl,
            vertical: VibrantSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: compact ? 0.95 : 0.8),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
            boxShadow: VibrantShadow.md(colorScheme),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact)
                      Text(
                        'Keep exploring ancient mastery.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (effectiveActions.isNotEmpty) ...[
                const SizedBox(width: VibrantSpacing.md),
                Row(children: effectiveActions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ReaderBottomNavigation extends StatelessWidget {
  const ReaderBottomNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<ReaderShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navBar = NavigationBar(
      backgroundColor: Colors.transparent,
      height: 72,
      selectedIndex: selectedIndex,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      animationDuration: const Duration(milliseconds: 450),
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        VibrantSpacing.lg,
        0,
        VibrantSpacing.lg,
        VibrantSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.85),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
              boxShadow: VibrantShadow.lg(colorScheme),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: Theme.of(context).navigationBarTheme
                    .copyWith(
                      backgroundColor: Colors.transparent,
                      indicatorColor: colorScheme.primaryContainer.withValues(alpha:
                        0.4,
                      ),
                    ),
              ),
              child: navBar,
            ),
          ),
        ),
      ),
    );
  }
}

class ReaderNavigationRail extends StatelessWidget {
  const ReaderNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.extended,
  });

  final List<ReaderShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(VibrantRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.75),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
            boxShadow: VibrantShadow.lg(colorScheme),
          ),
          child: NavigationRailTheme(
            data: NavigationRailTheme.of(context).copyWith(
              backgroundColor: Colors.transparent,
              selectedIconTheme: IconThemeData(
                color: colorScheme.primary,
                size: 28,
              ),
              unselectedIconTheme: IconThemeData(
                color: colorScheme.onSurfaceVariant,
                size: 26,
              ),
              selectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
            ),
            child: NavigationRail(
              extended: extended,
              minWidth: extended ? 92 : 80,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceContainer extends StatelessWidget {
  const _SurfaceContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(VibrantRadius.xxl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.88),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.04)),
          boxShadow: VibrantShadow.xl(colorScheme),
        ),
        child: child,
      ),
    );
  }
}

class _BackgroundHalo extends StatelessWidget {
  const _BackgroundHalo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.28),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -180,
            left: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  radius: 0.85,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -160,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  radius: 0.9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
