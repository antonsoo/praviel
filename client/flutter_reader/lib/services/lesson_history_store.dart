import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  LessonHistoryStore({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  static const _key = 'lesson_history';
  static const _maxEntries = 50;

  Future<List<LessonHistoryEntry>> load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
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
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, json);
  }

  Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
