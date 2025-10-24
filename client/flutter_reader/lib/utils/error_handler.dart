import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../widgets/premium_snackbars.dart';

/// Comprehensive error handling system for the Ancient Languages app
///
/// Provides consistent error messages, logging, and user feedback
/// across the entire application.

class AppError {
  const AppError({
    required this.message,
    required this.type,
    this.details,
    this.stackTrace,
    this.isRecoverable = true,
  });

  final String message;
  final ErrorType type;
  final String? details;
  final StackTrace? stackTrace;
  final bool isRecoverable;

  /// User-friendly message to display
  String get userMessage {
    switch (type) {
      case ErrorType.network:
        return 'Network error. Please check your connection and try again.';
      case ErrorType.authentication:
        return 'Authentication failed. Please log in again.';
      case ErrorType.authorization:
        return 'You don\'t have permission to access this resource.';
      case ErrorType.notFound:
        return 'The requested resource was not found.';
      case ErrorType.validation:
        return message;
      case ErrorType.server:
        return 'Server error. Please try again later.';
      case ErrorType.timeout:
        return 'Request timed out. Please try again.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
      case ErrorType.cache:
        return 'Failed to load cached data.';
      case ErrorType.parsing:
        return 'Failed to process server response.';
    }
  }

  /// Technical details for logging
  String get technicalDetails {
    final buffer = StringBuffer();
    buffer.writeln('Error Type: $type');
    buffer.writeln('Message: $message');
    if (details != null) {
      buffer.writeln('Details: $details');
    }
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }
    return buffer.toString();
  }
}

enum ErrorType {
  network,
  authentication,
  authorization,
  notFound,
  validation,
  server,
  timeout,
  unknown,
  cache,
  parsing,
}

/// Global error handler for the app
class ErrorHandler {
  /// Convert various exception types to AppError
  static AppError fromException(Object error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      return error;
    }

    // Network errors
    if (error is SocketException) {
      return AppError(
        message: 'No internet connection',
        type: ErrorType.network,
        details: error.message,
        stackTrace: stackTrace,
      );
    }

    if (error is http.ClientException) {
      return AppError(
        message: 'Network request failed',
        type: ErrorType.network,
        details: error.message,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return AppError(
        message: 'Request timed out',
        type: ErrorType.timeout,
        details: error.message,
        stackTrace: stackTrace,
      );
    }

    // HTTP response errors
    if (error is HttpException) {
      final statusCode = error.statusCode;
      return _fromHttpStatus(statusCode, error.message, stackTrace);
    }

    // Format exceptions (parsing errors)
    if (error is FormatException) {
      return AppError(
        message: 'Invalid data format',
        type: ErrorType.parsing,
        details: error.message,
        stackTrace: stackTrace,
      );
    }

    // Generic error
    return AppError(
      message: error.toString(),
      type: ErrorType.unknown,
      stackTrace: stackTrace,
    );
  }

  /// Create AppError from HTTP status code
  static AppError _fromHttpStatus(
    int statusCode,
    String? message,
    StackTrace? stackTrace,
  ) {
    final details = message ?? 'HTTP $statusCode';

    if (statusCode == 401) {
      return AppError(
        message: 'Authentication required',
        type: ErrorType.authentication,
        details: details,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 403) {
      return AppError(
        message: 'Access forbidden',
        type: ErrorType.authorization,
        details: details,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 404) {
      return AppError(
        message: 'Resource not found',
        type: ErrorType.notFound,
        details: details,
        stackTrace: stackTrace,
      );
    }

    if (statusCode >= 400 && statusCode < 500) {
      return AppError(
        message: 'Invalid request',
        type: ErrorType.validation,
        details: details,
        stackTrace: stackTrace,
      );
    }

    if (statusCode >= 500) {
      return AppError(
        message: 'Server error',
        type: ErrorType.server,
        details: details,
        stackTrace: stackTrace,
        isRecoverable: true,
      );
    }

    return AppError(
      message: 'HTTP error $statusCode',
      type: ErrorType.unknown,
      details: details,
      stackTrace: stackTrace,
    );
  }

  /// Show error to user via SnackBar
  static void showError(BuildContext context, Object error, [StackTrace? stackTrace]) {
    final appError = fromException(error, stackTrace);
    _logError(appError);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appError.userMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: appError.isRecoverable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Caller should handle retry logic
                },
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Show error using premium snackbar
  static void showPremiumError(
    BuildContext context,
    Object error, [
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  ]) {
    final appError = fromException(error, stackTrace);
    _logError(appError);

    PremiumSnackBar.error(
      context,
      message: appError.userMessage,
    );
  }

  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    PremiumSnackBar.success(
      context,
      message: message,
    );
  }

  /// Show info message
  static void showInfo(BuildContext context, String message) {
    PremiumSnackBar.info(
      context,
      message: message,
    );
  }

  /// Show warning message
  static void showWarning(BuildContext context, String message) {
    PremiumSnackBar.warning(
      context,
      message: message,
    );
  }

  /// Log error (in production, this should send to error tracking service)
  static void _logError(AppError error) {
    debugPrint('=== APP ERROR ===');
    debugPrint(error.technicalDetails);
    debugPrint('=================');

    // In production, send to error tracking service like Sentry
    // Sentry.captureException(
    //   error.message,
    //   stackTrace: error.stackTrace,
    // );
  }

  /// Handle async operations with automatic error handling
  static Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? errorMessage,
    VoidCallback? onRetry,
    bool showLoading = false,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      if (context.mounted) {
        if (onRetry != null) {
          showPremiumError(context, error, stackTrace, onRetry);
        } else {
          showError(context, error, stackTrace);
        }
      }
      return null;
    }
  }
}

/// Custom HTTP exception with status code
class HttpException implements Exception {
  const HttpException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'HttpException($statusCode): $message';
}

/// Timeout exception
class TimeoutException implements Exception {
  const TimeoutException([this.message = 'Operation timed out']);

  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}

/// Extension to easily handle errors in widgets
extension ErrorHandlerExtension on BuildContext {
  void showError(Object error, [StackTrace? stackTrace]) {
    ErrorHandler.showError(this, error, stackTrace);
  }

  void showPremiumError(Object error, [StackTrace? stackTrace, VoidCallback? onRetry]) {
    ErrorHandler.showPremiumError(this, error, stackTrace, onRetry);
  }

  void showSuccess(String message) {
    ErrorHandler.showSuccess(this, message);
  }

  void showInfo(String message) {
    ErrorHandler.showInfo(this, message);
  }

  void showWarning(String message) {
    ErrorHandler.showWarning(this, message);
  }
}

/// Widget to wrap error-prone operations
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FlutterError.onError = (details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
        });
        if (details.stack != null && widget.onError != null) {
          widget.onError!(details.exception, details.stack!);
        }
      }
    };
  }
}
