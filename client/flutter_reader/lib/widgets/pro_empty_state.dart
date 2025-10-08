import 'package:flutter/material.dart';
import '../theme/professional_theme.dart';

/// PROFESSIONAL empty states - helpful, not cute
/// Inspired by Linear and GitHub's empty states
class ProEmptyState extends StatelessWidget {
  const ProEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outline, width: 1),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: ProSpacing.xl),

              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: ProSpacing.md),

              // Description
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              // Action
              if (action != null && actionLabel != null) ...[
                const SizedBox(height: ProSpacing.xl),
                FilledButton(onPressed: action, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton for professional look
class ProLoadingSkeleton extends StatelessWidget {
  const ProLoadingSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(ProSpacing.xl),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: ProSpacing.md),
      itemBuilder: (context, index) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ProRadius.lg),
          ),
        );
      },
    );
  }
}

/// Inline loading indicator
class ProLoadingIndicator extends StatelessWidget {
  const ProLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: ProSpacing.lg),
            Text(
              message!,
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

/// Error state
class ProErrorState extends StatelessWidget {
  const ProErrorState({
    super.key,
    required this.title,
    this.description,
    this.onRetry,
  });

  final String title;
  final String? description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 32,
                  color: colorScheme.error,
                ),
              ),

              const SizedBox(height: ProSpacing.xl),

              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              // Description
              if (description != null) ...[
                const SizedBox(height: ProSpacing.md),
                Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Retry action
              if (onRetry != null) ...[
                const SizedBox(height: ProSpacing.xl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Success state for confirmations
class ProSuccessState extends StatelessWidget {
  const ProSuccessState({
    super.key,
    required this.title,
    this.description,
    this.onContinue,
    this.continueLabel,
  });

  final String title;
  final String? description;
  final VoidCallback? onContinue;
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: colorScheme.tertiary,
                ),
              ),

              const SizedBox(height: ProSpacing.xl),

              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              // Description
              if (description != null) ...[
                const SizedBox(height: ProSpacing.md),
                Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Continue action
              if (onContinue != null) ...[
                const SizedBox(height: ProSpacing.xl),
                FilledButton(
                  onPressed: onContinue,
                  child: Text(continueLabel ?? 'Continue'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
