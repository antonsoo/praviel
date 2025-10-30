import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class CoachApiException implements Exception {
  const CoachApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// API client for AI Coach (RAG-based tutoring assistant)
class CoachApi {
  CoachApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;

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

  /// Chat with AI coach using RAG (Retrieval Augmented Generation)
  ///
  /// The coach can answer questions about:
  /// - Grammar rules and explanations
  /// - Vocabulary and word usage
  /// - Historical context
  /// - Reading comprehension
  /// - Study tips and strategies
  Future<CoachResponse> chat({
    required String message,
    String? language, // 'greek', 'latin', 'hebrew'
    String? context, // Optional context (e.g., current lesson, text being read)
    List<CoachMessage>? conversationHistory,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/coach/chat');

      final body = {
        'message': message,
        if (language != null) 'language': language,
        if (context != null) 'context': context,
        if (conversationHistory != null && conversationHistory.isNotEmpty)
          'conversation_history': conversationHistory
              .map((m) => m.toJson())
              .toList(),
      };

      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 60)); // Longer timeout for AI

      if (response.statusCode == 200) {
        return CoachResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw CoachApiException(
          'Failed to chat with coach: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Quick question with no context (simpler API)
  Future<String> ask(String question, {String? language}) async {
    final response = await chat(message: question, language: language);
    return response.message;
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Coach conversation message
class CoachMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  CoachMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// Coach response
class CoachResponse {
  final String message;
  final List<String> sources; // Source documents used for RAG
  final List<String>? suggestedFollowUps;
  final String? grammarTopicId;
  final String? lexiconEntryId;

  CoachResponse({
    required this.message,
    required this.sources,
    this.suggestedFollowUps,
    this.grammarTopicId,
    this.lexiconEntryId,
  });

  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    return CoachResponse(
      message: json['message'] as String,
      sources: (json['sources'] as List?)?.cast<String>() ?? [],
      suggestedFollowUps: (json['suggested_follow_ups'] as List?)
          ?.cast<String>(),
      grammarTopicId: json['grammar_topic_id'] as String?,
      lexiconEntryId: json['lexicon_entry_id'] as String?,
    );
  }

  bool get hasSources => sources.isNotEmpty;
  bool get hasSuggestedFollowUps =>
      suggestedFollowUps != null && suggestedFollowUps!.isNotEmpty;
  bool get hasGrammarReference => grammarTopicId != null;
  bool get hasLexiconReference => lexiconEntryId != null;
}

/// Coach conversation state (for UI)
class CoachConversation {
  final List<CoachMessage> messages;
  final String? language;
  final String? context;

  CoachConversation({required this.messages, this.language, this.context});

  CoachConversation copyWith({
    List<CoachMessage>? messages,
    String? language,
    String? context,
  }) {
    return CoachConversation(
      messages: messages ?? this.messages,
      language: language ?? this.language,
      context: context ?? this.context,
    );
  }

  CoachConversation addMessage(CoachMessage message) {
    return copyWith(messages: [...messages, message]);
  }

  CoachConversation addUserMessage(String content) {
    return addMessage(
      CoachMessage(role: 'user', content: content, timestamp: DateTime.now()),
    );
  }

  CoachConversation addAssistantMessage(String content) {
    return addMessage(
      CoachMessage(
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      ),
    );
  }

  List<CoachMessage> get last10Messages {
    if (messages.length <= 10) return messages;
    return messages.sublist(messages.length - 10);
  }

  bool get isEmpty => messages.isEmpty;
  bool get isNotEmpty => messages.isNotEmpty;
  int get messageCount => messages.length;
}
