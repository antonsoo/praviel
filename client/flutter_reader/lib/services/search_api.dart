import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class SearchApiException implements Exception {
  const SearchApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// API client for searching lexicon, grammar, and texts
class SearchApi {
  SearchApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  bool _closed = false;

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

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

  /// Universal search across lexicon, grammar, and texts
  Future<SearchResponse> search({
    required String query,
    List<String>? types, // ['lexicon', 'grammar', 'text']
    String? language, // 'greek', 'latin', 'hebrew'
    int limit = 20,
    int? workId,
  }) async {
    return _retryRequest(() async {
      final queryParams = <String, String>{
        'q': query,
        'limit': limit.toString(),
        if (types != null && types.isNotEmpty) 'types': types.join(','),
        if (language != null) 'language': language,
        if (workId != null) 'work_id': workId.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/search',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return SearchResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw SearchApiException(
          'Failed to search: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Search lexicon entries (words/lemmas)
  Future<List<LexiconEntry>> searchLexicon({
    required String query,
    String? language,
    int limit = 20,
  }) async {
    final response = await search(
      query: query,
      types: ['lexicon'],
      language: language,
      limit: limit,
    );
    return response.lexiconResults;
  }

  /// Search grammar topics
  Future<List<GrammarEntry>> searchGrammar({
    required String query,
    String? language,
    int limit = 20,
  }) async {
    final response = await search(
      query: query,
      types: ['grammar'],
      language: language,
      limit: limit,
    );
    return response.grammarResults;
  }

  /// Search text passages
  Future<List<TextPassage>> searchTexts({
    required String query,
    String? language,
    int? workId,
    int limit = 20,
  }) async {
    final response = await search(
      query: query,
      types: ['text'],
      language: language,
      limit: limit,
      workId: workId,
    );
    return response.textResults;
  }

  /// Fetch available works (optionally filtered by language)
  Future<List<SearchWork>> fetchWorks({
    String? language,
    int limit = 50,
  }) async {
    return _retryRequest(() async {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (language != null && language.trim().isNotEmpty)
          'language': language.trim().toLowerCase(),
      };

      final uri = Uri.parse(
        '$baseUrl/search/works',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => SearchWork.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw SearchApiException(
          'Failed to load works: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  void close() {
    if (_closed) {
      return;
    }
    if (_ownsClient) {
      _client.close();
    }
    _closed = true;
  }

  void dispose() => close();
}

/// Universal search response
class SearchResponse {
  final String query;
  final int totalResults;
  final List<LexiconEntry> lexiconResults;
  final List<GrammarEntry> grammarResults;
  final List<TextPassage> textResults;

  SearchResponse({
    required this.query,
    required this.totalResults,
    required this.lexiconResults,
    required this.grammarResults,
    required this.textResults,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] as String,
      totalResults: json['total_results'] as int,
      lexiconResults:
          (json['lexicon_results'] as List?)
              ?.map((e) => LexiconEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      grammarResults:
          (json['grammar_results'] as List?)
              ?.map((e) => GrammarEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      textResults:
          (json['text_results'] as List?)
              ?.map((e) => TextPassage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasResults => totalResults > 0;
  bool get hasLexiconResults => lexiconResults.isNotEmpty;
  bool get hasGrammarResults => grammarResults.isNotEmpty;
  bool get hasTextResults => textResults.isNotEmpty;
}

class SearchWork {
  final int id;
  final String title;
  final String author;
  final String language;

  SearchWork({
    required this.id,
    required this.title,
    required this.author,
    required this.language,
  });

  factory SearchWork.fromJson(Map<String, dynamic> json) {
    return SearchWork(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String,
      language: json['language'] as String,
    );
  }
}

/// Lexicon entry (word/lemma)
class LexiconEntry {
  final int id;
  final String lemma;
  final String language;
  final String? partOfSpeech;
  final String? shortDefinition;
  final String? fullDefinition;
  final List<String> forms;
  final double relevanceScore;

  LexiconEntry({
    required this.id,
    required this.lemma,
    required this.language,
    this.partOfSpeech,
    this.shortDefinition,
    this.fullDefinition,
    required this.forms,
    required this.relevanceScore,
  });

  factory LexiconEntry.fromJson(Map<String, dynamic> json) {
    return LexiconEntry(
      id: json['id'] as int,
      lemma: json['lemma'] as String,
      language: json['language'] as String,
      partOfSpeech: json['part_of_speech'] as String?,
      shortDefinition: json['short_definition'] as String?,
      fullDefinition: json['full_definition'] as String?,
      forms: (json['forms'] as List?)?.cast<String>() ?? [],
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Grammar topic entry
class GrammarEntry {
  final int id;
  final String title;
  final String category;
  final String language;
  final String? summary;
  final String? content;
  final List<String> tags;
  final double relevanceScore;

  GrammarEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.language,
    this.summary,
    this.content,
    required this.tags,
    required this.relevanceScore,
  });

  factory GrammarEntry.fromJson(Map<String, dynamic> json) {
    return GrammarEntry(
      id: json['id'] as int,
      title: json['title'] as String,
      category: json['category'] as String,
      language: json['language'] as String,
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Text passage result
class TextPassage {
  final int id;
  final int workId;
  final String workTitle;
  final String author;
  final String passage;
  final String? translation;
  final int lineNumber;
  final String? book;
  final String? chapter;
  final double relevanceScore;

  TextPassage({
    required this.id,
    required this.workId,
    required this.workTitle,
    required this.author,
    required this.passage,
    this.translation,
    required this.lineNumber,
    this.book,
    this.chapter,
    required this.relevanceScore,
  });

  factory TextPassage.fromJson(Map<String, dynamic> json) {
    return TextPassage(
      id: json['id'] as int,
      workId: json['work_id'] as int,
      workTitle: json['work_title'] as String,
      author: json['author'] as String,
      passage: json['passage'] as String,
      translation: json['translation'] as String?,
      lineNumber: json['line_number'] as int,
      book: json['book'] as String?,
      chapter: json['chapter'] as String?,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get reference {
    final parts = <String>[workTitle];
    if (book != null) parts.add(book!);
    if (chapter != null) parts.add(chapter!);
    parts.add(lineNumber.toString());
    return parts.join(' ');
  }
}
