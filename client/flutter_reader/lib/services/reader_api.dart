/// API client for Reader feature - browsing and reading classical texts.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/reader.dart';

/// Exception thrown when Reader API requests fail.
class ReaderApiException implements Exception {
  const ReaderApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// API client for the Reader feature endpoints.
class ReaderApi {
  ReaderApi({required this.baseUrl, http.Client? client})
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

  /// Get all available text works for a language.
  ///
  /// Example:
  /// ```dart
  /// final response = await api.getTexts(language: 'grc');
  /// print(response.texts); // List of 5 Greek texts
  /// ```
  Future<TextListResponse> getTexts({String language = 'grc'}) async {
    final uri = Uri.parse(
      _normalize(baseUrl),
    ).resolve('reader/texts').replace(queryParameters: {'language': language});

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      _throwApiException(response, 'Failed to fetch text list');
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return TextListResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON from /reader/texts: ${error.message}');
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /reader/texts: $error');
    }
  }

  /// Get structural metadata for a text work (books/pages).
  ///
  /// Example:
  /// ```dart
  /// final response = await api.getTextStructure(textId: 1);
  /// print(response.structure.books); // 24 books for Iliad
  /// ```
  Future<TextStructureResponse> getTextStructure({required int textId}) async {
    final uri = Uri.parse(
      _normalize(baseUrl),
    ).resolve('reader/texts/$textId/structure');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      _throwApiException(response, 'Failed to fetch text structure');
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return TextStructureResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception(
        'Invalid JSON from /reader/texts/$textId/structure: ${error.message}',
      );
    } on TypeError catch (error) {
      throw Exception(
        'Unexpected schema from /reader/texts/$textId/structure: $error',
      );
    }
  }

  /// Analyze text and get morphological information.
  ///
  /// Example:
  /// ```dart
  /// final response = await api.analyzeText(
  ///   text: 'θεός',
  ///   language: 'grc',
  /// );
  /// print(response.tokens.first.lemma); // 'θεός'
  /// ```
  Future<AnalyzeResponse> analyzeText({
    required String text,
    required String language,
  }) async {
    final uri = Uri.parse(_normalize(baseUrl)).resolve('reader/analyze');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final body = jsonEncode({'text': text, 'language': language});

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      _throwApiException(response, 'Failed to analyze text');
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyzeResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON from /reader/analyze: ${error.message}');
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /reader/analyze: $error');
    }
  }

  /// Get text segments within a reference range.
  ///
  /// Example:
  /// ```dart
  /// final response = await api.getTextSegments(
  ///   textId: 1,
  ///   refStart: 'Il.1.1',
  ///   refEnd: 'Il.1.10',
  /// );
  /// print(response.segments.length); // 10 lines
  /// ```
  Future<TextSegmentsResponse> getTextSegments({
    required int textId,
    required String refStart,
    required String refEnd,
  }) async {
    final uri = Uri.parse(_normalize(baseUrl))
        .resolve('reader/texts/$textId/segments')
        .replace(queryParameters: {'ref_start': refStart, 'ref_end': refEnd});

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      _throwApiException(response, 'Failed to fetch text segments');
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return TextSegmentsResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception(
        'Invalid JSON from /reader/texts/$textId/segments: ${error.message}',
      );
    } on TypeError catch (error) {
      throw Exception(
        'Unexpected schema from /reader/texts/$textId/segments: $error',
      );
    }
  }

  /// Add a word to the SRS (Spaced Repetition System).
  ///
  /// Example:
  /// ```dart
  /// final response = await api.addToSRS(
  ///   word: 'θεός',
  ///   lemma: 'θεός',
  /// );
  /// print(response['id']); // SRS card ID
  /// ```
  Future<Map<String, dynamic>> addToSRS({
    required String word,
    String? lemma,
  }) async {
    final uri = Uri.parse(_normalize(baseUrl)).resolve('api/v1/srs/cards');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final body = jsonEncode({
      'card_type': 'lemma',
      'content_id': lemma ?? word,
    });

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      _throwApiException(response, 'Failed to add word to SRS');
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw Exception('Invalid JSON from /srs/cards: ${error.message}');
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /srs/cards: $error');
    }
  }

  /// Helper method to throw API exceptions with proper error message extraction.
  void _throwApiException(http.Response response, String defaultMessage) {
    final reason = response.reasonPhrase ?? '';
    var message = '$defaultMessage: ${response.statusCode} $reason'.trim();

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
      // Ignore parse errors and fall back to default message.
    }

    throw ReaderApiException(message, statusCode: response.statusCode);
  }

  /// Normalize URL by ensuring it ends with a slash.
  String _normalize(String url) => url.endsWith('/') ? url : '$url/';

  /// Close the HTTP client.
  Future<void> close() async {
    if (_ownsClient) {
      _client.close();
    }
  }
}
