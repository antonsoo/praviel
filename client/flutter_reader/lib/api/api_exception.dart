/// Common API exception for consistent error handling across all API clients
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get shouldRetry => !isClientError;

  @override
  String toString() {
    if (body != null && body!.isNotEmpty) {
      return '$message (HTTP $statusCode): $body';
    } else if (statusCode != null) {
      return '$message (HTTP $statusCode)';
    } else {
      return message;
    }
  }
}
