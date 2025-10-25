import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/advanced_micro_interactions.dart';

/// Modern empty state designs for 2025 UI standards
/// Engaging, helpful, and actionable

class ModernEmptyState extends StatelessWidget {
  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.animationPath,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? animationPath;
  final Widget? illustration;

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
            // Animation or illustration
            if (animationPath != null)
              SizedBox(
                width: 280,
                height: 280,
                child: Lottie.asset(
                  animationPath!,
                  fit: BoxFit.contain,
                ),
              )
            else if (illustration != null)
              SizedBox(
                width: 280,
                height: 280,
                child: illustration,
              )
            else
              BreathingWidget(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                        colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 80,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            const SizedBox(height: VibrantSpacing.xl),
            // Title
            SlideInFromBottom(
              delay: const Duration(milliseconds: 100),
              child: Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            // Message
            SlideInFromBottom(
              delay: const Duration(milliseconds: 200),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Actions
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: VibrantSpacing.xl),
              SlideInFromBottom(
                delay: const Duration(milliseconds: 300),
                child: PremiumButton(
                  onPressed: onAction,
                  gradient: VibrantTheme.auroraGradient,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(actionLabel!),
                      const SizedBox(width: VibrantSpacing.sm),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: VibrantSpacing.md),
              SlideInFromBottom(
                delay: const Duration(milliseconds: 350),
                child: TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for no search results
class NoSearchResultsState extends StatelessWidget {
  const NoSearchResultsState({
    super.key,
    required this.searchQuery,
    this.onClearSearch,
  });

  final String searchQuery;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    return ModernEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      message:
          'We couldn\'t find anything matching "$searchQuery". Try adjusting your search.',
      actionLabel: 'Clear search',
      onAction: onClearSearch,
    );
  }
}

/// Empty state for no internet connection
class NoConnectionState extends StatelessWidget {
  const NoConnectionState({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ModernEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No internet connection',
      message:
          'Please check your connection and try again. Some features may be unavailable offline.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

/// Empty state for errors
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ModernEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Oops! Something went wrong',
      message: message,
      actionLabel: onRetry != null ? 'Try again' : null,
      onAction: onRetry,
    );
  }
}

/// Empty state with custom illustration
class IllustrationEmptyState extends StatelessWidget {
  const IllustrationEmptyState({
    super.key,
    required this.illustrationPath,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String illustrationPath;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ModernEmptyState(
      icon: Icons.info_outline,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      illustration: Image.asset(
        illustrationPath,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Empty state for no content
class NoContentState extends StatelessWidget {
  const NoContentState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ModernEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Empty state for first time users
class OnboardingEmptyState extends StatelessWidget {
  const OnboardingEmptyState({
    super.key,
    required this.title,
    required this.steps,
    this.onGetStarted,
  });

  final String title;
  final List<OnboardingStep> steps;
  final VoidCallback? onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xxxl),
            for (int i = 0; i < steps.length; i++)
              SlideInFromBottom(
                delay: Duration(milliseconds: 100 * i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: VibrantSpacing.lg),
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: VibrantTheme.auroraGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.xs),
                            Text(
                              steps[i].description,
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
            const SizedBox(height: VibrantSpacing.xl),
            if (onGetStarted != null)
              SlideInFromBottom(
                delay: Duration(milliseconds: 100 * steps.length),
                child: PremiumButton(
                  onPressed: onGetStarted,
                  gradient: VibrantTheme.auroraGradient,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Get started'),
                      SizedBox(width: VibrantSpacing.sm),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
