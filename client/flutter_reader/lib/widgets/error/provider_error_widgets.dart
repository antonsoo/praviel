/// Specialized error widgets for provider failures
/// Prevents cascading errors and infinite loading states
library;

import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Multi-provider error boundary helper
///
/// Note: Due to Riverpod's type system, use individual AsyncErrorBoundary
/// widgets for each provider instead of this helper.
///
/// Example:
/// ```dart
/// final provider1 = ref.watch(myProvider1);
/// final provider2 = ref.watch(myProvider2);
///
/// if (provider1.hasError) {
///   return AsyncErrorBoundary(asyncValue: provider1, ...);
/// }
/// if (provider2.hasError) {
///   return AsyncErrorBoundary(asyncValue: provider2, ...);
/// }
/// if (provider1.isLoading || provider2.isLoading) {
///   return const CircularProgressIndicator();
/// }
///
/// // All loaded successfully
/// return MyWidget(provider1.value, provider2.value);
/// ```

/// Retry button with loading state
class RetryButton extends StatefulWidget {
  const RetryButton({
    super.key,
    required this.onRetry,
    this.label = 'Try Again',
  });

  final Future<void> Function() onRetry;
  final String label;

  @override
  State<RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<RetryButton> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isRetrying ? null : _handleRetry,
      icon: _isRetrying
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.refresh_rounded, size: 20),
      label: Text(_isRetrying ? 'Retrying...' : widget.label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.xl,
          vertical: VibrantSpacing.md,
        ),
      ),
    );
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }
}

/// Empty state widget for when data loads successfully but is empty
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: VibrantSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay for refresh operations
class RefreshLoadingOverlay extends StatelessWidget {
  const RefreshLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(VibrantSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: VibrantSpacing.md),
                      Text('Refreshing...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shimmer loading placeholder for list items
class ShimmerListLoader extends StatelessWidget {
  const ShimmerListLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(VibrantSpacing.md),
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

/// Provider-aware pull to refresh
///
/// Usage:
/// ```dart
/// ProviderRefreshIndicator(
///   onRefresh: () async {
///     ref.invalidate(myProvider);
///     await ref.read(myProvider.future);
///   },
///   child: MyListView(),
/// )
/// ```
class ProviderRefreshIndicator extends StatelessWidget {
  const ProviderRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}

/// Error banner that can be dismissed
class DismissibleErrorBanner extends StatefulWidget {
  const DismissibleErrorBanner({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  State<DismissibleErrorBanner> createState() => _DismissibleErrorBannerState();
}

class _DismissibleErrorBannerState extends State<DismissibleErrorBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(VibrantSpacing.md),
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 24,
          ),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Text(
              widget.error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (widget.onRetry != null)
            TextButton(onPressed: widget.onRetry, child: const Text('Retry')),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () {
              setState(() {
                _isDismissed = true;
              });
            },
            color: colorScheme.onErrorContainer,
          ),
        ],
      ),
    );
  }
}
