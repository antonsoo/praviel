import 'dart:convert';

import 'package:http/http.dart' as http;

class UserProfileApiException implements Exception {
  const UserProfileApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UserProfileApi {
  UserProfileApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  String? _authToken;

  set authToken(String? value) => _authToken = value;
  void setAuthToken(String? value) => _authToken = value;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<void> updateProfile({
    String? realName,
    String? discordUsername,
    String? phone,
    String? region,
    String? displayName,
    String? preferredPronouns,
    String? ageBracket,
    String? countryCode,
    List<String>? interests,
    String? bio,
    String? profileVisibility,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me');
    final body = <String, dynamic>{
      if (realName != null) 'real_name': realName,
      if (discordUsername != null) 'discord_username': discordUsername,
      if (phone != null) 'phone': phone,
      if (region != null) 'region': region,
      if (displayName != null) 'display_name': displayName,
      if (preferredPronouns != null) 'preferred_pronouns': preferredPronouns,
      if (ageBracket != null) 'age_bracket': ageBracket,
      if (countryCode != null) 'country_code': countryCode,
      if (interests != null) 'interests': interests,
      if (bio != null) 'bio': bio,
      if (profileVisibility != null) 'profile_visibility': profileVisibility,
    };

    if (body.isEmpty) {
      return;
    }

    late http.Response response;
    try {
      response = await _client
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } on Exception catch (error) {
      throw UserProfileApiException('Failed to update profile: $error');
    }

    if (response.statusCode >= 400) {
      var message = 'Failed to update profile';
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final detail = payload['detail'] ?? payload['message'];
          if (detail is String && detail.trim().isNotEmpty) {
            message = detail.trim();
          }
        }
      } catch (_) {
        // ignore parse errors
      }
      throw UserProfileApiException(message, statusCode: response.statusCode);
    }
  }

  Future<void> close() async {
    if (_ownsClient) {
      _client.close();
    }
  }
}
