import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class SrsApiException implements Exception {
  const SrsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}


/// API client for SRS (Spaced Repetition System) flashcards
class SrsApi {
  SrsApi({required this.baseUrl});

  final String baseUrl;
  final http.Client _client = http.Client();

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

  /// Create a new SRS flashcard
  Future<SrsCard> createCard({
    required String front,
    required String back,
    String deck = 'default',
    List<String> tags = const [],
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/srs/cards');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'front': front,
              'back': back,
              'deck': deck,
              'tags': tags,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return SrsCard.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw SrsApiException(
          'Failed to create card: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Get cards due for review
  Future<List<SrsCard>> getDueCards({String? deck, int limit = 20}) async {
    return _retryRequest(() async {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (deck != null) 'deck': deck,
      };

      final uri = Uri.parse(
        '$baseUrl/api/v1/srs/cards/due',
      ).replace(queryParameters: queryParams);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => SrsCard.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw SrsApiException(
          'Failed to load due cards: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Submit a review for a card
  Future<SrsReviewResponse> reviewCard({
    required int cardId,
    required int quality, // 1=Again, 2=Hard, 3=Good, 4=Easy
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/srs/cards/$cardId/review');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'card_id': cardId, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return SrsReviewResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw SrsApiException(
          'Failed to review card: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Get statistics for all decks
  Future<List<SrsDeckStats>> getStats() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/srs/stats');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => SrsDeckStats.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw SrsApiException(
          'Failed to load stats: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// Get statistics for all decks as a Map (deck name -> stats)
  Future<Map<String, SrsDeckStats>> getDeckStats() async {
    final statsList = await getStats();
    final statsMap = <String, SrsDeckStats>{};
    for (final stats in statsList) {
      statsMap[stats.deck] = stats;
    }
    return statsMap;
  }

  /// Delete a card
  Future<void> deleteCard(int cardId) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/srs/cards/$cardId');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw SrsApiException(
          'Failed to delete card: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    });
  }

  void dispose() {
    _client.close();
  }
}

/// SRS Card model
class SrsCard {
  SrsCard({
    required this.id,
    required this.front,
    required this.back,
    required this.deck,
    required this.tags,
    required this.state,
    required this.dueDate,
    required this.stability,
    required this.difficulty,
    required this.elapsedDays,
    required this.scheduledDays,
    required this.reps,
    required this.lapses,
    this.lastReview,
    required this.createdAt,
  });

  final int id;
  final String front;
  final String back;
  final String deck;
  final List<String> tags;
  final String state; // new, learning, review, relearning
  final DateTime dueDate;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final DateTime? lastReview;
  final DateTime createdAt;

  factory SrsCard.fromJson(Map<String, dynamic> json) {
    return SrsCard(
      id: json['id'] as int,
      front: json['front'] as String,
      back: json['back'] as String,
      deck: json['deck'] as String,
      tags: (json['tags'] as List).cast<String>(),
      state: json['state'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      stability: (json['stability'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      elapsedDays: json['elapsed_days'] as int,
      scheduledDays: json['scheduled_days'] as int,
      reps: json['reps'] as int,
      lapses: json['lapses'] as int,
      lastReview: json['last_review'] != null
          ? DateTime.parse(json['last_review'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Response after reviewing a card
class SrsReviewResponse {
  SrsReviewResponse({
    required this.cardId,
    required this.nextDueDate,
    required this.newStability,
    required this.newDifficulty,
    required this.newState,
    required this.daysUntilNextReview,
  });

  final int cardId;
  final DateTime nextDueDate;
  final double newStability;
  final double newDifficulty;
  final String newState;
  final int daysUntilNextReview;

  factory SrsReviewResponse.fromJson(Map<String, dynamic> json) {
    return SrsReviewResponse(
      cardId: json['card_id'] as int,
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      newStability: (json['new_stability'] as num).toDouble(),
      newDifficulty: (json['new_difficulty'] as num).toDouble(),
      newState: json['new_state'] as String,
      daysUntilNextReview: json['days_until_next_review'] as int,
    );
  }
}

/// Deck statistics
class SrsDeckStats {
  SrsDeckStats({
    required this.deck,
    required this.totalCards,
    required this.newCards,
    required this.learningCards,
    required this.reviewCards,
    required this.dueToday,
    required this.averageRetention,
  });

  final String deck;
  final int totalCards;
  final int newCards;
  final int learningCards;
  final int reviewCards;
  final int dueToday;
  final double averageRetention;

  factory SrsDeckStats.fromJson(Map<String, dynamic> json) {
    return SrsDeckStats(
      deck: json['deck'] as String,
      totalCards: json['total_cards'] as int,
      newCards: json['new_cards'] as int,
      learningCards: json['learning_cards'] as int,
      reviewCards: json['review_cards'] as int,
      dueToday: json['due_today'] as int,
      averageRetention: (json['average_retention'] as num).toDouble(),
    );
  }
}
