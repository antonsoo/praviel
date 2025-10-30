import 'dart:convert';

import 'package:http/http.dart' as http;

class SupportApiException implements Exception {
  SupportApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SupportApi {
  SupportApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  String? _authToken;

  void setAuthToken(String? token) {
    final trimmed = token?.trim();
    _authToken = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> submitBugReport({
    required String summary,
    required String description,
    String? contactEmail,
    String? appVersion,
    String? platform,
    String? language,
  }) async {
    final uri = Uri.parse(
      _normalize(baseUrl),
    ).resolve('api/v1/support/bug-report');
    final payload = <String, dynamic>{
      'summary': summary,
      'description': description,
      if (contactEmail != null && contactEmail.trim().isNotEmpty)
        'contact_email': contactEmail.trim(),
      if (appVersion != null && appVersion.trim().isNotEmpty)
        'app_version': appVersion.trim(),
      if (platform != null && platform.trim().isNotEmpty)
        'platform': platform.trim(),
      if (language != null && language.trim().isNotEmpty)
        'language': language.trim(),
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));
    } on Exception catch (error) {
      throw SupportApiException('Failed to submit bug report: $error');
    }

    if (response.statusCode >= 400) {
      var message = 'Failed to submit bug report';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final detail = body['detail'] ?? body['message'];
          if (detail is String && detail.trim().isNotEmpty) {
            message = detail.trim();
          }
        }
      } catch (_) {
        // Ignore JSON parsing errors; fall back to generic message.
      }
      throw SupportApiException(message, statusCode: response.statusCode);
    }
  }

  String _normalize(String url) => url.endsWith('/') ? url : '$url/';

  Future<void> close() async {
    if (_ownsClient) {
      _client.close();
    }
  }
}
