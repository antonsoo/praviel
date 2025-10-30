/// Error boundary specifically designed for Riverpod AsyncValue errors
/// Prevents cascading provider failures and infinite loading spinners
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/vibrant_theme.dart';
import '../../utils/error_handler.dart';

/// Widget that handles AsyncValue states with proper error boundaries
///
/// Usage:
/// ```dart
/// AsyncErrorBoundary<MyData>(
///   asyncValue: ref.watch(myProvider),
///   builder: (data) => MyWidget(data),
/// )
/// ```
class AsyncErrorBoundary<T> extends StatelessWidget {
  const AsyncErrorBoundary({
    super.key,
    required this.asyncValue,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onRetry,
    this.showLoadingOnRefresh = false,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final Widget Function()? loadingBuilder;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final VoidCallback? onRetry;
  final bool showLoadingOnRefresh;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        // Show data normally
        return builder(data);
      },
      loading: () {
        // Show custom loading or default
        if (loadingBuilder != null) {
          return loadingBuilder!();
        }
        return _buildDefaultLoading(context);
      },
      error: (error, stackTrace) {
        // Show custom error or default with retry
        if (errorBuilder != null) {
          return errorBuilder!(error, stackTrace);
        }
        return _buildDefaultError(context, error, stackTrace);
      },
    );
  }

  Widget _buildDefaultLoading(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Loading...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appError = ErrorHandler.fromException(error, stackTrace);

    // Log the error
    debugPrint('AsyncErrorBoundary caught error: ${appError.technicalDetails}');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getErrorIcon(appError.type),
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: VibrantSpacing.lg),

            // Error title
            Text(
              _getErrorTitle(appError.type),
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.sm),

            // Error message
            Text(
              appError.userMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xl),

            // Retry button (if retryable and onRetry is provided)
            if (appError.isRecoverable && onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.xl,
                    vertical: VibrantSpacing.md,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.authentication:
        return Icons.lock_outline_rounded;
      case ErrorType.authorization:
        return Icons.block_rounded;
      case ErrorType.notFound:
        return Icons.search_off_rounded;
      case ErrorType.timeout:
        return Icons.timer_off_rounded;
      case ErrorType.server:
        return Icons.cloud_off_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'No Connection';
      case ErrorType.authentication:
        return 'Authentication Required';
      case ErrorType.authorization:
        return 'Access Denied';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.server:
        return 'Server Error';
      default:
        return 'Something Went Wrong';
    }
  }
}

/// Extension to easily use AsyncErrorBoundary with AsyncValue
extension AsyncValueErrorBoundaryX<T> on AsyncValue<T> {
  Widget toBoundary({
    required Widget Function(T data) builder,
    Widget Function()? loadingBuilder,
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    VoidCallback? onRetry,
  }) {
    return AsyncErrorBoundary<T>(
      asyncValue: this,
      builder: builder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      onRetry: onRetry,
    );
  }
}

/// Simplified async error handler for common patterns
class AsyncErrorHandler {
  /// Handle AsyncValue with automatic error boundary
  static Widget handle<T>({
    required AsyncValue<T> asyncValue,
    required Widget Function(T data) builder,
    VoidCallback? onRetry,
    String? loadingMessage,
  }) {
    return AsyncErrorBoundary<T>(
      asyncValue: asyncValue,
      builder: builder,
      onRetry: onRetry,
      loadingBuilder: loadingMessage != null
          ? () => _buildLoadingWithMessage(loadingMessage)
          : null,
    );
  }

  static Widget _buildLoadingWithMessage(String message) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: VibrantSpacing.md),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handle list AsyncValue with empty state
  static Widget handleList<T>({
    required AsyncValue<List<T>> asyncValue,
    required Widget Function(List<T> data) builder,
    Widget? emptyState,
    VoidCallback? onRetry,
    String? loadingMessage,
  }) {
    return AsyncErrorBoundary<List<T>>(
      asyncValue: asyncValue,
      builder: (data) {
        if (data.isEmpty && emptyState != null) {
          return emptyState;
        }
        return builder(data);
      },
      onRetry: onRetry,
      loadingBuilder: loadingMessage != null
          ? () => _buildLoadingWithMessage(loadingMessage)
          : null,
    );
  }
}
