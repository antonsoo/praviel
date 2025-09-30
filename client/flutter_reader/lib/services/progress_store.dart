import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProgressStore {
  ProgressStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> load() async {
    final json = await _storage.read(key: 'progress');
    if (json == null) return _defaults();
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return _defaults();
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    await _storage.write(key: 'progress', value: jsonEncode(data));
  }

  Map<String, dynamic> _defaults() => {
        'streakDays': 0,
        'xpTotal': 0,
        'lastLessonAt': null,
      };

  // Dev-only reset
  Future<void> reset() async => await _storage.delete(key: 'progress');
}