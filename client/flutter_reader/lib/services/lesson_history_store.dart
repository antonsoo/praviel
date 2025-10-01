import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LessonHistoryEntry {
  LessonHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.textSnippet,
    required this.totalTasks,
    required this.correctCount,
    required this.score,
  });

  final String id;
  final DateTime timestamp;
  final String textSnippet;
  final int totalTasks;
  final int correctCount;
  final double score;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'textSnippet': textSnippet,
        'totalTasks': totalTasks,
        'correctCount': correctCount,
        'score': score,
      };

  factory LessonHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LessonHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      textSnippet: json['textSnippet'] as String,
      totalTasks: json['totalTasks'] as int,
      correctCount: json['correctCount'] as int,
      score: (json['score'] as num).toDouble(),
    );
  }
}

class LessonHistoryStore {
  LessonHistoryStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'lesson_history';
  static const _maxEntries = 50;

  Future<List<LessonHistoryEntry>> load() async {
    final json = await _storage.read(key: _key);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => LessonHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(LessonHistoryEntry entry) async {
    final entries = await load();
    entries.insert(0, entry); // Most recent first

    // Keep only the most recent entries
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }

    await _save(entries);
  }

  Future<void> _save(List<LessonHistoryEntry> entries) async {
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _storage.write(key: _key, value: json);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
