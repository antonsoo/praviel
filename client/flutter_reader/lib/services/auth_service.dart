import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// User authentication service for the Ancient Languages app
///
/// Handles user registration, login, logout, and token management.
/// Uses flutter_secure_storage for encrypted token storage (iOS Keychain, Android Keystore).
/// Integrates with the FastAPI backend authentication endpoints.
class AuthService extends ChangeNotifier {
  AuthService({
    required String baseUrl,
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  }) : _baseUrl = baseUrl,
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _client = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;
  final http.Client _client;
  final bool _ownsClient;

  String? _accessToken;
  String? _refreshToken;
  UserProfile? _currentUser;

  // Storage keys
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';

  bool get isAuthenticated => _accessToken != null && _currentUser != null;
  UserProfile? get currentUser => _currentUser;

  /// Get the current access token (synchronous access for internal use)
  String? get accessToken => _accessToken;

  /// Retry helper for transient network errors with exponential backoff
  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (e) {
        // Don't retry on auth errors - only transient network errors
        if (e is AuthException) {
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

  /// Initialize auth state from secure storage on app start
  Future<void> initialize() async {
    try {
      _accessToken = await _secureStorage.read(key: _keyAccessToken);
      _refreshToken = await _secureStorage.read(key: _keyRefreshToken);

      if (_accessToken != null) {
        // Try to fetch current user profile
        await _fetchCurrentUser();
      }
    } catch (e) {
      debugPrint('[AuthService] Failed to initialize: $e');
      await logout();
    }

    // Auto-login for development/demo (works in both debug and release when using localhost)
    if (!isAuthenticated && _baseUrl.contains('127.0.0.1')) {
      try {
        debugPrint(
          '[AuthService] Auto-logging in as demo_user for development (baseUrl: $_baseUrl)',
        );
        await login(usernameOrEmail: 'demo_user', password: 'DemoPass123!');
        debugPrint('[AuthService] Auto-login successful!');
      } catch (e) {
        debugPrint('[AuthService] Auto-login failed (this is OK): $e');
      }
    }

    notifyListeners();
  }

  /// Register a new user account
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _retryRequest(() async {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        // Registration successful - now log in
        await login(usernameOrEmail: username, password: password);
      } else {
        final message = _extractErrorMessage(
          response.body,
          fallback: 'Registration failed',
        );
        throw AuthException(message);
      }
    });
  }

  /// Login with username/email and password
  Future<void> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    await _retryRequest(() async {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username_or_email': usernameOrEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];

        // Save tokens securely
        await _saveTokens(_accessToken!, _refreshToken!);

        // Fetch user profile
        await _fetchCurrentUser();

        notifyListeners();
      } else {
        final message = _extractErrorMessage(
          response.body,
          fallback: 'Login failed',
        );
        throw AuthException(message);
      }
    });
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);

    notifyListeners();
  }

  /// Get authorization headers for authenticated requests
  Future<Map<String, String>> getAuthHeaders() async {
    if (_accessToken == null) {
      throw AuthException('Not authenticated');
    }
    return {'Authorization': 'Bearer $_accessToken'};
  }

  /// Refresh the access token using the refresh token
  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw AuthException('No refresh token available');
    }

    await _retryRequest(() async {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': _refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];

        await _saveTokens(_accessToken!, _refreshToken!);
        notifyListeners();
      } else {
        // Refresh failed - logout user
        await logout();
        throw AuthException('Session expired. Please login again.');
      }
    });
  }

  /// Make an authenticated HTTP request with automatic token refresh
  Future<http.Response> authenticatedRequest({
    required Future<http.Response> Function(Map<String, String> headers)
    request,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final response = await request(headers);

      // If unauthorized, try to refresh token and retry
      if (response.statusCode == 401) {
        await refreshAccessToken();
        final newHeaders = await getAuthHeaders();
        return await request(newHeaders);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Private methods

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> _fetchCurrentUser() async {
    await _retryRequest(() async {
      final response = await authenticatedRequest(
        request: (headers) => _client
            .get(Uri.parse('$_baseUrl/api/v1/users/me'), headers: headers)
            .timeout(const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.fromJson(data);
      } else {
        throw AuthException('Failed to fetch user profile');
      }
    });
  }

  String _extractErrorMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      final message = _extractDetail(decoded);
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    } catch (_) {
      // ignore parse errors
    }
    return fallback;
  }

  String? _extractDetail(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is String) {
      final trimmed = payload.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (payload is List) {
      final seen = <String>{};
      final parts = <String>[];
      for (final item in payload) {
        final part = _extractDetail(item);
        if (part != null && part.isNotEmpty && seen.add(part)) {
          parts.add(part);
        }
      }
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
      return null;
    }

    if (payload is Map) {
      final map = payload.cast<Object?, Object?>();

      String? readKey(String key) {
        if (!map.containsKey(key)) return null;
        final value = map[key];
        if (identical(value, payload)) {
          return null;
        }
        return _extractDetail(value);
      }

      final direct =
          readKey('detail') ??
          readKey('message') ??
          readKey('msg') ??
          readKey('error');
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }

      final errors = readKey('errors');
      if (errors != null && errors.isNotEmpty) {
        return errors;
      }

      for (final value in map.values) {
        final nested = _extractDetail(value);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }
}

/// User profile model
class UserProfile {
  final int id;
  final String username;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final String? realName;
  final String? discordUsername;
  final String? phone;
  final String? region;
  final String? displayName;
  final String? preferredPronouns;
  final String? ageBracket;
  final String? countryCode;
  final List<String>? interests;
  final String? bio;
  final String profileVisibility;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.isActive,
    required this.createdAt,
    this.realName,
    this.discordUsername,
    this.phone,
    this.region,
    this.displayName,
    this.preferredPronouns,
    this.ageBracket,
    this.countryCode,
    this.interests,
    this.bio,
    required this.profileVisibility,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final interestsRaw = json['interests'];
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      realName: json['real_name'],
      discordUsername: json['discord_username'],
      phone: json['phone'],
      region: json['region'],
      displayName: json['display_name'],
      preferredPronouns: json['preferred_pronouns'],
      ageBracket: json['age_bracket'],
      countryCode: json['country_code'],
      interests: interestsRaw is List
          ? interestsRaw.whereType<String>().toList()
          : null,
      bio: json['bio'],
      profileVisibility: (json['profile_visibility'] as String?) ?? 'friends',
    );
  }
}

/// Authentication exception
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
