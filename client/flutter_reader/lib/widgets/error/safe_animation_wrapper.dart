/// Error boundary wrapper for animations to prevent crashes
library;

import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';

/// Safely wraps animations to catch and handle errors gracefully
class SafeAnimationWrapper extends StatelessWidget {
  const SafeAnimationWrapper({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  final Widget child;
  final Widget? fallback;
  final void Function(Object error, StackTrace stack)? onError;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: onError,
      fallback: fallback,
      child: child,
    );
  }
}

/// Error boundary widget that catches errors and shows fallback
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  final Widget child;
  final Widget? fallback;
  final void Function(Object error, StackTrace stack)? onError;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _buildDefaultFallback(context);
    }

    return ErrorCatcher(
      onError: (error, stackTrace) {
        if (mounted) {
          setState(() {
            _error = error;
          });
          widget.onError?.call(error, stackTrace);
        }
      },
      child: widget.child,
    );
  }

  Widget _buildDefaultFallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: VibrantSpacing.md),
            Text(
              'Animation Error',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'The animation encountered an error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that catches errors from its child
class ErrorCatcher extends StatefulWidget {
  const ErrorCatcher({
    super.key,
    required this.child,
    required this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<ErrorCatcher> {
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      widget.onError(details.exception, details.stack ?? StackTrace.current);
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
