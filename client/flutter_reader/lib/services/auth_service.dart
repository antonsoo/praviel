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
  AuthService({required String baseUrl, FlutterSecureStorage? secureStorage})
    : _baseUrl = baseUrl,
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;

  String? _accessToken;
  String? _refreshToken;
  UserProfile? _currentUser;

  // Storage keys
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';

  bool get isAuthenticated => _accessToken != null && _currentUser != null;
  UserProfile? get currentUser => _currentUser;

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
    notifyListeners();
  }

  /// Register a new user account
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _retryRequest(() async {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        // Registration successful - now log in
        await login(usernameOrEmail: username, password: password);
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['detail'] ?? 'Registration failed');
      }
    });
  }

  /// Login with username/email and password
  Future<void> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    await _retryRequest(() async {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username_or_email': usernameOrEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

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
        final error = jsonDecode(response.body);
        throw AuthException(error['detail'] ?? 'Login failed');
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
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      ).timeout(const Duration(seconds: 30));

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
        request: (headers) =>
            http.get(Uri.parse('$_baseUrl/api/v1/users/me'), headers: headers)
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

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.isActive,
    required this.createdAt,
    this.realName,
    this.discordUsername,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      realName: json['real_name'],
      discordUsername: json['discord_username'],
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
