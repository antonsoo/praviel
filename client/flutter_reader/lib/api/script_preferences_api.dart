/// API client for script display preferences.
///
/// Handles communication with the backend for getting and updating
/// user script display preferences.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/script_preferences.dart';
import 'api_exception.dart';

class ScriptPreferencesAPI {
  ScriptPreferencesAPI({required this.baseUrl, http.Client? client})
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

  /// Get current user's script preferences
  Future<ScriptPreferences> getScriptPreferences() async {
    if (_authToken == null) {
      throw ApiException('Not authenticated');
    }

    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/v1/users/me/script-preferences'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ScriptPreferences.fromJson(json);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized - please log in', statusCode: 401);
    } else {
      throw ApiException(
        'Failed to load script preferences',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  /// Update script preferences
  Future<ScriptPreferences> updateScriptPreferences(
    ScriptPreferences preferences,
  ) async {
    if (_authToken == null) {
      throw ApiException('Not authenticated');
    }

    final response = await _client
        .put(
          Uri.parse('$baseUrl/api/v1/users/me/script-preferences'),
          headers: _headers,
          body: jsonEncode(preferences.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ScriptPreferences.fromJson(json);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized - please log in', statusCode: 401);
    } else {
      throw ApiException(
        'Failed to update script preferences',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  /// Reset script preferences to defaults
  Future<ScriptPreferences> resetScriptPreferences() async {
    if (_authToken == null) {
      throw ApiException('Not authenticated');
    }

    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/v1/users/me/script-preferences/reset'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ScriptPreferences.fromJson(json);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized - please log in', statusCode: 401);
    } else {
      throw ApiException(
        'Failed to reset script preferences',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
