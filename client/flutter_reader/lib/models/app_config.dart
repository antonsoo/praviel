import 'dart:convert';

import 'package:flutter/services.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  static Future<AppConfig> load() async {
    final raw = await rootBundle.loadString('assets/config/dev.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final baseUrl = data['apiBaseUrl'] as String? ?? '';
    if (baseUrl.isEmpty) {
      throw StateError('apiBaseUrl missing in config');
    }
    return AppConfig(apiBaseUrl: baseUrl);
  }
}
