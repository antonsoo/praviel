import 'package:flutter/material.dart';
import '../../theme/vibrant_colors.dart';

/// User-friendly error state widget with recovery actions
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.message,
    this.retryButtonText = 'Try Again',
  });

  final Object error;
  final VoidCallback? onRetry;
  final String? title;
  final String? message;
  final String retryButtonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorInfo = _ErrorInfo.from(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorInfo.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorInfo.icon,
                size: 64,
                color: errorInfo.color,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title ?? errorInfo.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: VibrantColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message ?? errorInfo.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: VibrantColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Retry button
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryButtonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorInfo.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            // Help text
            if (errorInfo.helpText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VibrantColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: VibrantColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: VibrantColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorInfo.helpText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: VibrantColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Information extracted from error for display
class _ErrorInfo {
  const _ErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.helpText,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? helpText;

  factory _ErrorInfo.from(Object error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return const _ErrorInfo(
        title: 'Connection Error',
        message: 'Unable to connect to the server. Please check your internet connection.',
        icon: Icons.wifi_off_rounded,
        color: VibrantColors.error,
        helpText: 'Make sure you\'re connected to the internet and try again.',
      );
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return const _ErrorInfo(
        title: 'Request Timed Out',
        message: 'The server is taking too long to respond.',
        icon: Icons.timer_off_rounded,
        color: VibrantColors.warning,
        helpText: 'This might be due to a slow connection or server issues. Try again in a moment.',
      );
    }

    // Auth errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('authentication')) {
      return const _ErrorInfo(
        title: 'Session Expired',
        message: 'Your session has expired. Please sign in again.',
        icon: Icons.lock_outline_rounded,
        color: VibrantColors.error,
        helpText: 'For security reasons, you\'ll need to sign in again to continue.',
      );
    }

    // Not found errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return const _ErrorInfo(
        title: 'Not Found',
        message: 'The requested content could not be found.',
        icon: Icons.search_off_rounded,
        color: VibrantColors.warning,
      );
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('server error')) {
      return const _ErrorInfo(
        title: 'Server Error',
        message: 'Something went wrong on our end. Our team has been notified.',
        icon: Icons.cloud_off_rounded,
        color: VibrantColors.error,
        helpText: 'Please try again in a few moments. If the problem persists, contact support.',
      );
    }

    // Generic error
    return const _ErrorInfo(
      title: 'Something Went Wrong',
      message: 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline_rounded,
      color: VibrantColors.error,
      helpText: 'If this keeps happening, please contact support.',
    );
  }
}

/// Compact error banner for inline errors
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorInfo = _ErrorInfo.from(error);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorInfo.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            errorInfo.icon,
            color: errorInfo.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorInfo.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: VibrantColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorInfo.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: VibrantColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              color: errorInfo.color,
              tooltip: 'Retry',
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
              color: VibrantColors.textSecondary,
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}
