import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Comprehensive error handling utility for API calls
class ApiErrorHandler {
  /// Parse and classify an API error
  static ApiError handleError(dynamic error, {StackTrace? stackTrace}) {
    if (error is ApiError) {
      return error;
    }

    if (error is SocketException) {
      return ApiError.network(
        message: 'No internet connection. Please check your network settings.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return ApiError.timeout(
        message: 'Request timed out. Please try again.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is http.ClientException) {
      return ApiError.network(
        message: 'Network error: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return ApiError.parsing(
        message: 'Invalid response format from server.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Extract HTTP error from exception message
    final errorMessage = error.toString();
    if (errorMessage.contains('Failed to')) {
      // Parse status code from error message
      final statusCodeMatch = RegExp(
        r'40[0-9]|50[0-9]',
      ).firstMatch(errorMessage);
      if (statusCodeMatch != null) {
        final statusCode = int.tryParse(statusCodeMatch.group(0) ?? '');
        if (statusCode != null) {
          return _createHttpError(statusCode, errorMessage, error, stackTrace);
        }
      }
    }

    // Generic unknown error
    return ApiError.unknown(
      message: 'An unexpected error occurred: ${error.toString()}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static ApiError _createHttpError(
    int statusCode,
    String message,
    dynamic originalError,
    StackTrace? stackTrace,
  ) {
    if (statusCode >= 400 && statusCode < 500) {
      return ApiError.client(
        statusCode: statusCode,
        message: _getClientErrorMessage(statusCode, message),
        originalError: originalError,
        stackTrace: stackTrace,
      );
    } else if (statusCode >= 500) {
      return ApiError.server(
        statusCode: statusCode,
        message: 'Server error. Please try again later.',
        originalError: originalError,
        stackTrace: stackTrace,
      );
    }

    return ApiError.unknown(
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  static String _getClientErrorMessage(int statusCode, String fallback) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication required. Please log in.';
      case 403:
        return 'Access denied. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. The resource already exists.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please slow down.';
      default:
        return fallback;
    }
  }

  /// Log error for debugging
  static void logError(ApiError error) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('API ERROR: ${error.type}');
    debugPrint('Message: ${error.message}');
    if (error.statusCode != null) {
      debugPrint('Status Code: ${error.statusCode}');
    }
    debugPrint('Retryable: ${error.isRetryable}');
    if (error.originalError != null) {
      debugPrint('Original: ${error.originalError}');
    }
    if (error.stackTrace != null) {
      debugPrint('Stack trace:\n${error.stackTrace}');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}

/// Typed API error with categorization
class ApiError implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  // Named constructors for different error types
  factory ApiError.network({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) => ApiError(
    type: ApiErrorType.network,
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  factory ApiError.timeout({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) => ApiError(
    type: ApiErrorType.timeout,
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  factory ApiError.client({
    required int statusCode,
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) => ApiError(
    type: ApiErrorType.client,
    message: message,
    statusCode: statusCode,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  factory ApiError.server({
    required int statusCode,
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) => ApiError(
    type: ApiErrorType.server,
    message: message,
    statusCode: statusCode,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  factory ApiError.auth({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) => ApiError(
    type: ApiErrorType.auth,
    message: message,
    statusCode: 401,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  factory ApiError.parsing({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) => ApiError(
    type: ApiErrorType.parsing,
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  factory ApiError.unknown({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) => ApiError(
    type: ApiErrorType.unknown,
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  // Error classification helpers
  bool get isRetryable {
    switch (type) {
      case ApiErrorType.network:
      case ApiErrorType.timeout:
      case ApiErrorType.server:
        return true;
      case ApiErrorType.client:
      case ApiErrorType.auth:
      case ApiErrorType.parsing:
      case ApiErrorType.unknown:
        return false;
    }
  }

  bool get isAuthError => type == ApiErrorType.auth || statusCode == 401;
  bool get isNetworkError => type == ApiErrorType.network;
  bool get isServerError => type == ApiErrorType.server;
  bool get isClientError => type == ApiErrorType.client;
  bool get isTimeoutError => type == ApiErrorType.timeout;

  // User-friendly message for display
  String get userMessage {
    switch (type) {
      case ApiErrorType.network:
        return 'No internet connection. Please check your network settings.';
      case ApiErrorType.timeout:
        return 'Request timed out. Please try again.';
      case ApiErrorType.auth:
        return 'Please log in to continue.';
      case ApiErrorType.client:
        return message;
      case ApiErrorType.server:
        return 'Server error. Please try again later.';
      case ApiErrorType.parsing:
        return 'Invalid response from server.';
      case ApiErrorType.unknown:
        return 'An unexpected error occurred.';
    }
  }

  // Technical details for logging
  String get technicalDetails {
    final buffer = StringBuffer();
    buffer.writeln('Type: $type');
    buffer.writeln('Message: $message');
    if (statusCode != null) buffer.writeln('Status Code: $statusCode');
    if (originalError != null) buffer.writeln('Original: $originalError');
    return buffer.toString();
  }

  @override
  String toString() => 'ApiError($type): $message';
}

/// API error type classification
enum ApiErrorType {
  network, // No internet, connection lost
  timeout, // Request timed out
  client, // 4xx errors (bad request, not found, etc.)
  server, // 5xx errors (server error, maintenance)
  auth, // 401 unauthorized
  parsing, // Invalid JSON, format error
  unknown, // Unexpected error
}

/// Extension for easier error handling in UI
extension ApiErrorHandling on ApiError {
  /// Get icon for error type
  String get icon {
    switch (type) {
      case ApiErrorType.network:
        return '📡';
      case ApiErrorType.timeout:
        return '⏱️';
      case ApiErrorType.auth:
        return '🔒';
      case ApiErrorType.client:
        return '⚠️';
      case ApiErrorType.server:
        return '🔧';
      case ApiErrorType.parsing:
        return '📄';
      case ApiErrorType.unknown:
        return '❓';
    }
  }

  /// Get color for error type (as string for UI)
  String get colorName {
    switch (type) {
      case ApiErrorType.network:
      case ApiErrorType.timeout:
        return 'orange';
      case ApiErrorType.auth:
        return 'purple';
      case ApiErrorType.client:
        return 'yellow';
      case ApiErrorType.server:
        return 'red';
      case ApiErrorType.parsing:
        return 'blue';
      case ApiErrorType.unknown:
        return 'grey';
    }
  }

  /// Suggested action for user
  String get suggestedAction {
    switch (type) {
      case ApiErrorType.network:
        return 'Check your internet connection and try again.';
      case ApiErrorType.timeout:
        return 'The request took too long. Try again.';
      case ApiErrorType.auth:
        return 'Please log in again.';
      case ApiErrorType.client:
        if (statusCode == 404) {
          return 'The requested resource was not found.';
        } else if (statusCode == 422) {
          return 'Please check your input and try again.';
        }
        return 'Please review your request and try again.';
      case ApiErrorType.server:
        return 'Our servers are having issues. Please try again later.';
      case ApiErrorType.parsing:
        return 'Please try again or contact support if the problem persists.';
      case ApiErrorType.unknown:
        return 'Please try again or contact support.';
    }
  }
}
