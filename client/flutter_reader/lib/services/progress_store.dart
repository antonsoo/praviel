import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore {
  ProgressStore({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;

  Future<Map<String, dynamic>> load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final json = prefs.getString('progress');
    if (json == null) return _defaults();
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return _defaults();
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString('progress', jsonEncode(data));
    } catch (e) {
      // Log but rethrow - caller should handle storage failures
      throw Exception('Failed to save progress: $e');
    }
  }

  Map<String, dynamic> _defaults() => {
    'streakDays': 0,
    'xpTotal': 0,
    'lastLessonAt': null,
    'lastStreakUpdate': null,
  };

  // Dev-only reset
  Future<void> reset() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove('progress');
  }
}
