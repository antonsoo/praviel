import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// API client for managing user API keys (BYOK - Bring Your Own Key)
class ApiKeysApi {
  ApiKeysApi({required this.baseUrl});

  final String baseUrl;
  final http.Client _client = http.Client();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Retry helper for transient network errors with exponential backoff
  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (e) {
        // Don't retry on HTTP 4xx errors (client errors)
        if (e.toString().contains('Failed to') &&
            (e.toString().contains('40') ||
                e.toString().contains('41') ||
                e.toString().contains('42') ||
                e.toString().contains('43'))) {
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

  /// List all configured API keys (metadata only, not the actual keys)
  Future<List<ApiKeyInfo>> listApiKeys() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/api-keys/');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((json) => ApiKeyInfo.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to list API keys: ${response.body}');
      }
    });
  }

  /// Add or update an API key for a provider
  Future<ApiKeyInfo> addOrUpdateApiKey({
    required String provider, // 'openai', 'anthropic', 'google'
    required String apiKey,
    String? label,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/api-keys/');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'provider': provider,
              'api_key': apiKey,
              if (label != null) 'label': label,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return ApiKeyInfo.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to add API key: ${response.body}');
      }
    });
  }

  /// Delete an API key for a provider
  Future<void> deleteApiKey(String provider) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/api-keys/$provider');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete API key: ${response.body}');
      }
    });
  }

  /// Test if an API key is configured for a provider
  Future<ApiKeyTestResponse> testApiKey(String provider) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/api-keys/$provider/test');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return ApiKeyTestResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to test API key: ${response.body}');
      }
    });
  }

  void close() {
    _client.close();
  }
}

/// API key information (metadata only)
class ApiKeyInfo {
  final String provider;
  final String? label;
  final String maskedKey; // e.g., "sk-...abc123"
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  ApiKeyInfo({
    required this.provider,
    this.label,
    required this.maskedKey,
    required this.createdAt,
    this.lastUsedAt,
    required this.isActive,
  });

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) {
    return ApiKeyInfo(
      provider: json['provider'] as String,
      label: json['label'] as String?,
      maskedKey: json['masked_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String get providerDisplayName {
    switch (provider.toLowerCase()) {
      case 'openai':
        return 'OpenAI (GPT-5)';
      case 'anthropic':
        return 'Anthropic (Claude)';
      case 'google':
        return 'Google (Gemini)';
      case 'elevenlabs':
        return 'ElevenLabs (TTS)';
      default:
        return provider;
    }
  }

  bool get hasBeenUsed => lastUsedAt != null;

  String get lastUsedDisplay {
    if (lastUsedAt == null) return 'Never used';

    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

/// API key test response
class ApiKeyTestResponse {
  final String provider;
  final bool isConfigured;
  final String? maskedKey;
  final String? error;

  ApiKeyTestResponse({
    required this.provider,
    required this.isConfigured,
    this.maskedKey,
    this.error,
  });

  factory ApiKeyTestResponse.fromJson(Map<String, dynamic> json) {
    return ApiKeyTestResponse(
      provider: json['provider'] as String,
      isConfigured: json['is_configured'] as bool,
      maskedKey: json['masked_key'] as String?,
      error: json['error'] as String?,
    );
  }

  bool get isValid => isConfigured && error == null;
  bool get hasError => error != null;
}

/// Supported API providers
class ApiProvider {
  static const String openai = 'openai';
  static const String anthropic = 'anthropic';
  static const String google = 'google';
  static const String elevenlabs = 'elevenlabs';

  static const List<String> all = [openai, anthropic, google, elevenlabs];

  static String displayName(String provider) {
    switch (provider) {
      case openai:
        return 'OpenAI (GPT-5)';
      case anthropic:
        return 'Anthropic (Claude 4.5)';
      case google:
        return 'Google (Gemini 2.5)';
      case elevenlabs:
        return 'ElevenLabs (TTS)';
      default:
        return provider;
    }
  }

  static String description(String provider) {
    switch (provider) {
      case openai:
        return 'Use your own OpenAI API key for GPT-5 lesson generation';
      case anthropic:
        return 'Use your own Anthropic API key for Claude 4.5 chat';
      case google:
        return 'Use your own Google API key for Gemini 2.5 features';
      case elevenlabs:
        return 'Use your own ElevenLabs API key for text-to-speech';
      default:
        return 'API key for $provider';
    }
  }
}
