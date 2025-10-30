import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/vocabulary.dart';

class VocabularyApiException implements Exception {
  const VocabularyApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class VocabularyApi {
  VocabularyApi({required this.baseUrl, http.Client? client})
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

  /// Generate vocabulary words for learning
  Future<VocabularyGenerationResponse> generate(
    VocabularyGenerationRequest request, {
    String? apiKey,
  }) async {
    final uri = Uri.parse(_normalize(baseUrl)).resolve('vocabulary/generate');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      headers['x-model-key'] = apiKey.trim();
    }

    final body = jsonEncode(request.toJson());

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 120));

    if (response.statusCode >= 400) {
      final reason = response.reasonPhrase ?? '';
      var message =
          'Vocabulary generation failed: ${response.statusCode} $reason'.trim();
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
        // Ignore parse errors and fall back to default message
      }
      throw VocabularyApiException(message, statusCode: response.statusCode);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return VocabularyGenerationResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception(
        'Invalid JSON from /vocabulary/generate: ${error.message}',
      );
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /vocabulary/generate: $error');
    }
  }

  /// Record a vocabulary interaction (correct/incorrect answer)
  Future<VocabularyInteractionResponse> recordInteraction(
    VocabularyInteractionRequest request,
  ) async {
    final uri = Uri.parse(
      _normalize(baseUrl),
    ).resolve('vocabulary/interaction');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final body = jsonEncode(request.toJson());

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      final reason = response.reasonPhrase ?? '';
      var message =
          'Interaction recording failed: ${response.statusCode} $reason'.trim();
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final detail = payload['detail'];
          if (detail is String && detail.trim().isNotEmpty) {
            message = detail.trim();
          }
        }
      } catch (_) {
        // Ignore parse errors
      }
      throw VocabularyApiException(message, statusCode: response.statusCode);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return VocabularyInteractionResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception(
        'Invalid JSON from /vocabulary/interaction: ${error.message}',
      );
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /vocabulary/interaction: $error');
    }
  }

  /// Get vocabulary items due for review
  Future<VocabularyReviewResponse> getReview(
    VocabularyReviewRequest request,
  ) async {
    final uri = Uri.parse(_normalize(baseUrl)).resolve('vocabulary/review');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final body = jsonEncode(request.toJson());

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      final reason = response.reasonPhrase ?? '';
      var message = 'Review fetch failed: ${response.statusCode} $reason'
          .trim();
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final detail = payload['detail'];
          if (detail is String && detail.trim().isNotEmpty) {
            message = detail.trim();
          }
        }
      } catch (_) {
        // Ignore parse errors
      }
      throw VocabularyApiException(message, statusCode: response.statusCode);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return VocabularyReviewResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON from /vocabulary/review: ${error.message}');
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /vocabulary/review: $error');
    }
  }

  String _normalize(String url) => url.endsWith('/') ? url : '$url/';

  Future<void> close() async {
    if (_ownsClient) {
      _client.close();
    }
  }
}
