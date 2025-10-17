import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class PasswordResetApiException implements Exception {
  const PasswordResetApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}


/// API client for password reset functionality
class PasswordResetApi {
  PasswordResetApi({required this.baseUrl});

  final String baseUrl;
  final http.Client _client = http.Client();

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  /// Retry helper for transient network errors with exponential backoff
  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (e) {
        // Don't retry on HTTP 4xx errors (client errors)
        if (e.toString().contains('Failed to') &&
            (e.toString().contains('40') ||
                e.toString().contains('41') ||
                e.toString().contains('42') ||
                e.toString().contains('43'))) {
          rethrow;
        }

        // Last attempt - rethrow the error
        if (attempt == maxRetries - 1) {
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 4s
        final delaySeconds = pow(2, attempt).toInt();
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Request a password reset email
  Future<PasswordResetRequestResponse> requestPasswordReset({
    required String email,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/auth/password-reset/request');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode({'email': email}))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return PasswordResetRequestResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to request password reset');
      }
    });
  }

  /// Validate a password reset token
  Future<TokenValidationResponse> validateResetToken({
    required String token,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse(
        '$baseUrl/api/v1/auth/password-reset/validate-token/$token',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return TokenValidationResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Invalid or expired token');
      }
    });
  }

  /// Confirm password reset with token and new password
  Future<PasswordResetConfirmResponse> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/auth/password-reset/confirm');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'token': token, 'new_password': newPassword}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return PasswordResetConfirmResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to reset password');
      }
    });
  }

  void close() {
    _client.close();
  }
}

/// Response after requesting password reset
class PasswordResetRequestResponse {
  final String message;
  final String? email; // May be masked for security

  PasswordResetRequestResponse({required this.message, this.email});

  factory PasswordResetRequestResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequestResponse(
      message: json['message'] as String,
      email: json['email'] as String?,
    );
  }
}

/// Response after validating reset token
class TokenValidationResponse {
  final bool valid;
  final String? message;
  final String? email; // Email associated with token (may be masked)

  TokenValidationResponse({required this.valid, this.message, this.email});

  factory TokenValidationResponse.fromJson(Map<String, dynamic> json) {
    return TokenValidationResponse(
      valid: json['valid'] as bool,
      message: json['message'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Response after confirming password reset
class PasswordResetConfirmResponse {
  final String message;
  final bool success;

  PasswordResetConfirmResponse({required this.message, required this.success});

  factory PasswordResetConfirmResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetConfirmResponse(
      message: json['message'] as String,
      success: json['success'] as bool? ?? true,
    );
  }
}
