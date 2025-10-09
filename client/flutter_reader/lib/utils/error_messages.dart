import 'dart:io';

/// User-friendly error messages for common failure scenarios
class ErrorMessages {
  /// Convert technical errors into user-friendly messages
  static String fromException(dynamic error) {
    if (error == null) return 'Something went wrong. Please try again.';

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (error is SocketException || errorString.contains('socket')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'Connection timed out. Please check your internet connection.';
    }

    if (errorString.contains('failed host lookup')) {
      return 'Cannot reach server. Please check your internet connection.';
    }

    // HTTP errors
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. Please contact support.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Resource not found. Please try refreshing.';
    }

    if (errorString.contains('429') || errorString.contains('too many requests')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (errorString.contains('500') || errorString.contains('internal server')) {
      return 'Server error. Our team has been notified. Please try again later.';
    }

    if (errorString.contains('502') || errorString.contains('bad gateway')) {
      return 'Server is temporarily unavailable. Please try again in a moment.';
    }

    if (errorString.contains('503') || errorString.contains('service unavailable')) {
      return 'Service is under maintenance. Please try again later.';
    }

    // Challenge-specific errors
    if (errorString.contains('challenge')) {
      if (errorString.contains('expired')) {
        return 'This challenge has expired. Pull to refresh for new challenges.';
      }
      if (errorString.contains('already completed')) {
        return 'This challenge is already completed!';
      }
      if (errorString.contains('not enough coins')) {
        return 'Not enough coins for this purchase. Keep learning to earn more!';
      }
      return 'Unable to update challenge. Please try again.';
    }

    // Auth errors
    if (errorString.contains('auth') || errorString.contains('token')) {
      return 'Session expired. Please log in again.';
    }

    // Data parsing errors
    if (errorString.contains('json') || errorString.contains('parse')) {
      return 'Data format error. Please update your app.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Get error message for challenge loading failures
  static String forChallengeLoad(dynamic error) {
    if (error is SocketException || error.toString().contains('socket')) {
      return 'Cannot load challenges offline. Showing cached challenges.';
    }
    return fromException(error);
  }

  /// Get error message for challenge update failures
  static String forChallengeUpdate(dynamic error) {
    final msg = fromException(error);
    if (msg.contains('internet') || msg.contains('connection')) {
      return 'Update queued. Will sync when you\'re back online.';
    }
    return msg;
  }

  /// Get error message for purchase failures
  static String forPurchase(dynamic error) {
    if (error.toString().contains('insufficient') || error.toString().contains('not enough')) {
      return 'Not enough coins! Complete challenges to earn more.';
    }
    return fromException(error);
  }
}
