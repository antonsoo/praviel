import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility for retrying failed API calls with exponential backoff
class ApiRetry {
  /// Retry a future with exponential backoff
  ///
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay in milliseconds (default: 500ms)
  /// [maxDelay] - Maximum delay in milliseconds (default: 10000ms)
  /// [retryIf] - Optional condition to determine if error should be retried
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(milliseconds: 10000),
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (error) {
        // Check if we should retry this error
        final shouldRetry = retryIf?.call(error) ?? _defaultRetryCondition(error);

        if (!shouldRetry || attempt >= maxAttempts) {
          debugPrint('[ApiRetry] Failed after $attempt attempts: $error');
          rethrow;
        }

        debugPrint(
          '[ApiRetry] Attempt $attempt/$maxAttempts failed: $error. '
          'Retrying in ${delay.inMilliseconds}ms...',
        );

        // Wait before retrying
        await Future.delayed(delay);

        // Exponential backoff with jitter
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2)
              .clamp(initialDelay.inMilliseconds, maxDelay.inMilliseconds),
        );
      }
    }
  }

  /// Default retry condition - retry on network errors and 5xx status codes
  static bool _defaultRetryCondition(dynamic error) {
    // Retry on socket exceptions (network errors)
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;

    // Retry on HTTP errors that might be temporary
    if (error is HttpException) return true;

    // Check error message for common retryable patterns
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('connection')) return true;
    if (errorString.contains('timeout')) return true;
    if (errorString.contains('network')) return true;
    if (errorString.contains('failed to load')) return true;

    // Don't retry by default
    return false;
  }

  /// Retry with circuit breaker pattern
  ///
  /// Stops retrying if too many failures occur within a time window
  static Future<T> retryWithCircuitBreaker<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    int failureThreshold = 5,
    Duration resetTimeout = const Duration(minutes: 1),
  }) async {
    final breaker = _CircuitBreaker.instance;

    if (breaker.isOpen(operationName)) {
      throw CircuitBreakerOpenException(
        'Circuit breaker is open for $operationName. '
        'Too many recent failures. Try again later.',
      );
    }

    try {
      final result = await retry(
        operation: operation,
        maxAttempts: maxAttempts,
        initialDelay: initialDelay,
      );

      breaker.recordSuccess(operationName);
      return result;
    } catch (error) {
      breaker.recordFailure(operationName);
      rethrow;
    }
  }
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Simple circuit breaker implementation
class _CircuitBreaker {
  static final _CircuitBreaker instance = _CircuitBreaker._();
  _CircuitBreaker._();

  final Map<String, _CircuitState> _states = {};

  bool isOpen(String operationName) {
    final state = _states[operationName];
    if (state == null) return false;

    // Reset if timeout has passed
    if (DateTime.now().difference(state.lastFailure) > state.resetTimeout) {
      _states.remove(operationName);
      return false;
    }

    return state.failureCount >= state.failureThreshold;
  }

  void recordSuccess(String operationName) {
    _states.remove(operationName);
  }

  void recordFailure(String operationName) {
    final state = _states[operationName] ?? _CircuitState();
    state.failureCount++;
    state.lastFailure = DateTime.now();
    _states[operationName] = state;
  }
}

class _CircuitState {
  int failureCount = 0;
  DateTime lastFailure = DateTime.now();
  final int failureThreshold = 5;
  final Duration resetTimeout = const Duration(minutes: 1);
}
