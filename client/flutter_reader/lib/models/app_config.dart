import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String _dartDefineApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  static Future<AppConfig> load() async {
    final override = _dartDefineApiBaseUrl.trim();
    if (override.isNotEmpty) {
      return AppConfig(apiBaseUrl: override);
    }

    // Use production config in release mode, dev config otherwise
    final configFile = kReleaseMode ? 'assets/config/prod.json' : 'assets/config/dev.json';
    final raw = await rootBundle.loadString(configFile);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final baseUrl = data['apiBaseUrl'] as String? ?? '';
    if (baseUrl.isEmpty) {
      throw StateError('apiBaseUrl missing in config');
    }
    return AppConfig(apiBaseUrl: baseUrl);
  }
}
