import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/chat.dart';
import 'byok_controller.dart';

class ChatApiException implements Exception {
  const ChatApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ChatApi {
  ChatApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  Future<ChatConverseResponse> converse(
    ChatConverseRequest request,
    ByokSettings settings,
  ) async {
    return _retryRequest(() => _converseInternal(request, settings));
  }

  /// Internal method with retry logic for transient network errors
  Future<ChatConverseResponse> _retryRequest(
    Future<ChatConverseResponse> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (e) {
        // Don't retry on API errors (4xx/5xx) - only transient network errors
        if (e is ChatApiException) {
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

  Future<ChatConverseResponse> _converseInternal(
    ChatConverseRequest request,
    ByokSettings settings,
  ) async {
    final provider = (request.provider).trim().isEmpty
        ? 'echo'
        : request.provider.trim();
    final uri = Uri.parse(_normalize(baseUrl)).resolve('chat/converse');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (provider != 'echo') {
      final key = settings.apiKey.trim();
      if (key.isNotEmpty) {
        headers['Authorization'] = 'Bearer $key';
      }
    }

    final body = jsonEncode(request.toJson());

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 120)); // Increased for GPT-5 latency

    if (response.statusCode >= 400) {
      final reason = response.reasonPhrase ?? '';
      var message = 'Chat request failed: ${response.statusCode} $reason'
          .trim();
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final error = payload['error'];
          if (error is Map<String, dynamic>) {
            final raw = error['message'];
            if (raw is String && raw.trim().isNotEmpty) {
              message = raw.trim();
            }
          } else {
            final detail = payload['detail'];
            if (detail is String && detail.trim().isNotEmpty) {
              message = detail.trim();
            }
          }
        }
      } catch (_) {
        // Fallback to default message
      }
      throw ChatApiException(message, statusCode: response.statusCode);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatConverseResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON from /chat/converse: ${error.message}');
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /chat/converse: $error');
    }
  }

  String _normalize(String url) => url.endsWith('/') ? url : '$url/';

  Future<void> close() async {
    if (_ownsClient) {
      _client.close();
    }
  }
}
