import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';

/// Premium empty state widget - transforms "no data" into delight
class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
    this.gradient,
    this.showAnimation = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;
  final Gradient? gradient;
  final bool showAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveGradient = gradient ?? VibrantTheme.heroGradient;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            if (showAnimation)
              BounceIn(
                delay: const Duration(milliseconds: 100),
                child: _buildIconContainer(
                  colorScheme,
                  effectiveGradient,
                ),
              )
            else
              _buildIconContainer(colorScheme, effectiveGradient),

            const SizedBox(height: VibrantSpacing.xl),

            // Title
            if (showAnimation)
              SlideInFromBottom(
                delay: const Duration(milliseconds: 200),
                child: _buildTitle(theme),
              )
            else
              _buildTitle(theme),

            const SizedBox(height: VibrantSpacing.md),

            // Message
            if (showAnimation)
              SlideInFromBottom(
                delay: const Duration(milliseconds: 300),
                child: _buildMessage(theme, colorScheme),
              )
            else
              _buildMessage(theme, colorScheme),

            // Action button
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: VibrantSpacing.xxl),
              if (showAnimation)
                ScaleIn(
                  delay: const Duration(milliseconds: 400),
                  child: _buildActionButton(theme, colorScheme),
                )
              else
                _buildActionButton(theme, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(ColorScheme colorScheme, Gradient gradient) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 56,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(ThemeData theme, ColorScheme colorScheme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, ColorScheme colorScheme) {
    return FilledButton.icon(
      onPressed: action,
      icon: const Icon(Icons.add_rounded),
      label: Text(actionLabel!),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.xl,
          vertical: VibrantSpacing.md,
        ),
      ),
    );
  }
}

/// Empty state with illustration placeholder
class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
    this.secondaryAction,
    this.secondaryActionLabel,
  });

  final Widget illustration;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback? secondaryAction;
  final String? secondaryActionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            ScaleIn(
              duration: VibrantDuration.slow,
              child: SizedBox(
                width: 240,
                height: 240,
                child: illustration,
              ),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Title
            SlideInFromBottom(
              delay: const Duration(milliseconds: 200),
              child: Text(
                title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: VibrantSpacing.lg),

            // Message
            SlideInFromBottom(
              delay: const Duration(milliseconds: 300),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Actions
            ScaleIn(
              delay: const Duration(milliseconds: 400),
              child: Wrap(
                spacing: VibrantSpacing.md,
                runSpacing: VibrantSpacing.md,
                alignment: WrapAlignment.center,
                children: [
                  if (action != null && actionLabel != null)
                    FilledButton.icon(
                      onPressed: action,
                      icon: const Icon(Icons.explore_rounded),
                      label: Text(actionLabel!),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.xl,
                          vertical: VibrantSpacing.md,
                        ),
                      ),
                    ),
                  if (secondaryAction != null && secondaryActionLabel != null)
                    OutlinedButton.icon(
                      onPressed: secondaryAction,
                      icon: const Icon(Icons.help_outline_rounded),
                      label: Text(secondaryActionLabel!),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.xl,
                          vertical: VibrantSpacing.md,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact empty state for cards/sections
class CompactEmptyState extends StatelessWidget {
  const CompactEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null && actionLabel != null) ...[
            const SizedBox(height: VibrantSpacing.lg),
            TextButton.icon(
              onPressed: action,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Search empty state - for "no results"
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.searchTerm,
    this.suggestions = const [],
    this.onClearSearch,
    this.onSuggestionTap,
  });

  final String searchTerm;
  final List<String> suggestions;
  final VoidCallback? onClearSearch;
  final Function(String)? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BounceIn(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surfaceContainerHigh,
                      colorScheme.surfaceContainer,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            Text(
              'No results found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: VibrantSpacing.sm),

            Text(
              'We couldn\'t find anything for "$searchTerm"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            if (onClearSearch != null) ...[
              const SizedBox(height: VibrantSpacing.lg),
              TextButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear search'),
              ),
            ],

            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: VibrantSpacing.xxl),
              Text(
                'Try searching for:',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.md),
              Wrap(
                spacing: VibrantSpacing.sm,
                runSpacing: VibrantSpacing.sm,
                alignment: WrapAlignment.center,
                children: suggestions
                    .map((suggestion) => ActionChip(
                          label: Text(suggestion),
                          onPressed: () => onSuggestionTap?.call(suggestion),
                          avatar: Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error empty state - for failed loads
class ErrorEmptyState extends StatelessWidget {
  const ErrorEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BounceIn(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.errorContainer,
                      colorScheme.errorContainer.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.xl),

            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.md),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: VibrantSpacing.xxl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.xl,
                    vertical: VibrantSpacing.md,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
