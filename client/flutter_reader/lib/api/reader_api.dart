import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/feature_flags.dart';
import 'api_exception.dart';

class AnalyzeToken {
  const AnalyzeToken({
    required this.text,
    required this.start,
    required this.end,
    this.lemma,
    this.morph,
  });

  final String text;
  final int start;
  final int end;
  final String? lemma;
  final String? morph;

  factory AnalyzeToken.fromJson(Map<String, dynamic> json) {
    return AnalyzeToken(
      text: json['text'] as String? ?? '',
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
      lemma: json['lemma'] as String?,
      morph: json['morph'] as String?,
    );
  }
}

class LexiconEntry {
  const LexiconEntry({required this.lemma, this.gloss, this.citation});

  final String lemma;
  final String? gloss;
  final String? citation;

  factory LexiconEntry.fromJson(Map<String, dynamic> json) {
    return LexiconEntry(
      lemma: json['lemma'] as String? ?? '',
      gloss: json['gloss'] as String?,
      citation: json['citation'] as String?,
    );
  }
}

class GrammarEntry {
  const GrammarEntry({
    required this.anchor,
    required this.title,
    required this.score,
  });

  final String anchor;
  final String title;
  final double score;

  factory GrammarEntry.fromJson(Map<String, dynamic> json) {
    return GrammarEntry(
      anchor: json['anchor'] as String? ?? '',
      title: json['title'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HybridHit {
  const HybridHit({
    required this.segmentId,
    required this.workRef,
    required this.textNfc,
    required this.score,
    required this.reasons,
  });

  final int segmentId;
  final String workRef;
  final String textNfc;
  final double score;
  final List<String> reasons;

  factory HybridHit.fromJson(Map<String, dynamic> json) {
    return HybridHit(
      segmentId: json['segment_id'] as int? ?? 0,
      workRef: json['work_ref'] as String? ?? '',
      textNfc: json['text_nfc'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      reasons: (json['reasons'] as List<dynamic>? ?? [])
          .map((reason) => reason.toString())
          .toList(growable: false),
    );
  }
}

class AnalyzeResult {
  const AnalyzeResult({
    required this.tokens,
    required this.retrieval,
    this.lexicon = const [],
    this.grammar = const [],
  });

  final List<AnalyzeToken> tokens;
  final List<HybridHit> retrieval;
  final List<LexiconEntry> lexicon;
  final List<GrammarEntry> grammar;

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    final tokensJson = json['tokens'] as List<dynamic>? ?? const [];
    final retrievalJson = json['retrieval'] as List<dynamic>? ?? const [];
    final lexiconJson = json['lexicon'] as List<dynamic>?;
    final grammarJson = json['grammar'] as List<dynamic>?;

    return AnalyzeResult(
      tokens: tokensJson
          .map((item) => AnalyzeToken.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      retrieval: retrievalJson
          .map((item) => HybridHit.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      lexicon: lexiconJson == null
          ? const []
          : lexiconJson
                .map(
                  (item) => LexiconEntry.fromJson(item as Map<String, dynamic>),
                )
                .toList(growable: false),
      grammar: grammarJson == null
          ? const []
          : grammarJson
                .map(
                  (item) => GrammarEntry.fromJson(item as Map<String, dynamic>),
                )
                .toList(growable: false),
    );
  }
}

class ReaderApi {
  ReaderApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<AnalyzeResult> analyze(
    String q, {
    bool lsj = false,
    bool smyth = false,
  }) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      throw const ApiException('Query cannot be empty.');
    }

    final uri = _buildUri(_includeParams(lsj: lsj, smyth: smyth));
    final body = jsonEncode({'q': trimmed});

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ApiException('Request to /reader/analyze timed out.');
    } on Exception catch (error) {
      throw ApiException(
        'Request to /reader/analyze failed: $error',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to analyze text',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyzeResult.fromJson(payload);
    } on FormatException catch (error) {
      throw ApiException(
        'Invalid JSON payload from analyzer: $error',
      );
    } on TypeError catch (error) {
      throw ApiException(
        'Unexpected response schema from analyzer: $error',
      );
    }
  }

  Future<FeatureFlags> featureFlags() async {
    final uri = Uri.parse(_normalizeBase(baseUrl)).resolve('health');
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        return FeatureFlags.none;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return FeatureFlags.fromHealth(payload);
    } catch (_) {
      return FeatureFlags.none;
    }
  }

  Uri _buildUri(Map<String, String>? queryParameters) {
    final normalizedBase = _normalizeBase(baseUrl);
    final uri = Uri.parse(normalizedBase).resolve('reader/analyze');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParameters},
    );
  }

  String _normalizeBase(String url) => url.endsWith('/') ? url : '$url/';

  Map<String, String>? _includeParams({
    required bool lsj,
    required bool smyth,
  }) {
    if (!lsj && !smyth) {
      return null;
    }
    return {
      'include': jsonEncode({'lsj': lsj, 'smyth': smyth}),
    };
  }

  Future<void> close() async => _client.close();
}
