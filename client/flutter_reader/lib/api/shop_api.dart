import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

/// API client for power-up shop
class ShopApi {
  ShopApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
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
        // Don't retry on API errors (4xx client errors)
        if (e is ApiException && !e.shouldRetry) {
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
    throw ApiException('Max retries exceeded');
  }

  /// Get user's power-up inventory (from progress endpoint)
  Future<ShopInventory> getInventory() async {
    return _retryRequest(() async {
      // Get user progress which includes power-up inventory
      final uri = Uri.parse('$baseUrl/api/v1/progress/me');
      final response = await _client.get(uri, headers: _headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        final progress = jsonDecode(response.body) as Map<String, dynamic>;
        // Convert progress response to shop inventory format
        return ShopInventory.fromProgress(progress);
      } else {
        final String message = _extractErrorMessage(response.body) ?? 'Failed to load shop inventory';
        throw ApiException(message, statusCode: response.statusCode, body: response.body);
      }
    });
  }

  /// Purchase a power-up with coins
  /// Supported types: 'streak_freeze', 'xp_boost_2x', 'hint_reveal', 'time_warp'
  Future<PurchaseResponse> purchase(String powerUpType, {int quantity = 1}) async {
    return _retryRequest(() async {
      // Map to backend endpoints
      String endpoint;
      switch (powerUpType) {
        case 'streak_freeze':
          endpoint = '$baseUrl/api/v1/progress/me/streak-freeze/buy';
          break;
        case 'xp_boost_2x':
          endpoint = '$baseUrl/api/v1/progress/me/power-ups/xp-boost/buy';
          break;
        case 'hint_reveal':
          endpoint = '$baseUrl/api/v1/progress/me/power-ups/hint-reveal/buy';
          break;
        case 'time_warp':
          endpoint = '$baseUrl/api/v1/progress/me/power-ups/time-warp/buy';
          break;
        default:
          throw ApiException('Unknown power-up type: $powerUpType');
      }

      final uri = Uri.parse(endpoint);
      final response = await _client.post(
        uri,
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PurchaseResponse.fromBackendResponse(data);
      } else {
        final String message = _extractErrorMessage(response.body) ?? 'Purchase failed';
        throw ApiException(message, statusCode: response.statusCode, body: response.body);
      }
    });
  }

  /// Use a power-up from inventory
  /// Supported types: 'xp_boost_2x', 'hint_reveal', 'time_warp'
  Future<void> usePowerUp(String powerUpType) async {
    return _retryRequest(() async {
      // Map to backend activation endpoints
      String endpoint;
      switch (powerUpType) {
        case 'xp_boost_2x':
          endpoint = '$baseUrl/api/v1/progress/me/power-ups/xp-boost/activate';
          break;
        case 'hint_reveal':
          endpoint = '$baseUrl/api/v1/progress/me/power-ups/hint/use';
          break;
        case 'time_warp':
          endpoint = '$baseUrl/api/v1/progress/me/power-ups/skip/use';
          break;
        case 'streak_freeze':
          // Streak freeze is auto-applied, no manual use endpoint
          throw ApiException('Streak freeze is automatically applied when needed');
        default:
          throw ApiException('Unknown power-up type: $powerUpType');
      }

      final uri = Uri.parse(endpoint);
      final response = await _client.post(uri, headers: _headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        final String message = _extractErrorMessage(response.body) ?? 'Failed to use power-up';
        throw ApiException(message, statusCode: response.statusCode, body: response.body);
      }
    });
  }

  /// Extract error message from response body
  String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return json['detail'] as String? ??
            json['message'] as String? ??
            (json['error'] is Map ? json['error']['message'] as String? : null);
      }
    } catch (_) {
      // If JSON parsing fails, return null
    }
    return null;
  }

  void close() {
    _client.close();
  }
}

/// Shop inventory response
class ShopInventory {
  final int coins;
  final Map<String, PowerUpItem> powerUps;
  final Map<String, int> inventory;

  ShopInventory({
    required this.coins,
    required this.powerUps,
    required this.inventory,
  });

  factory ShopInventory.fromJson(Map<String, dynamic> json) {
    return ShopInventory(
      coins: json['coins'] as int,
      powerUps: (json['power_ups'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          PowerUpItem.fromJson(value as Map<String, dynamic>),
        ),
      ),
      inventory: (json['inventory'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }

  /// Create ShopInventory from progress endpoint response
  factory ShopInventory.fromProgress(Map<String, dynamic> progress) {
    // Static power-up catalog with prices from backend
    final powerUpsCatalog = {
      'streak_freeze': PowerUpItem(
        name: 'Streak Shield',
        description: 'Protect your streak if you miss a day',
        icon: '🛡️',
        cost: 100,
        maxStack: 99,
      ),
      'xp_boost_2x': PowerUpItem(
        name: '2x XP Boost',
        description: 'Double XP for 30 minutes',
        icon: '⚡',
        cost: 150,
        maxStack: 99,
      ),
      'hint_reveal': PowerUpItem(
        name: 'Hint Reveal',
        description: 'Get a hint for any exercise',
        icon: '💡',
        cost: 50,
        maxStack: 99,
      ),
      'time_warp': PowerUpItem(
        name: 'Skip Question',
        description: 'Skip any difficult question',
        icon: '⏭️',
        cost: 100,
        maxStack: 99,
      ),
    };

    // Extract inventory from progress response
    final inventory = {
      'streak_freeze': progress['streak_freezes'] as int? ?? 0,
      'xp_boost_2x': progress['xp_boost_2x'] as int? ?? 0,
      'hint_reveal': progress['perfect_protection'] as int? ?? 0,
      'time_warp': progress['time_warp'] as int? ?? 0,
    };

    return ShopInventory(
      coins: progress['coins'] as int? ?? 0,
      powerUps: powerUpsCatalog,
      inventory: inventory,
    );
  }
}

/// Individual power-up item in shop
class PowerUpItem {
  final String name;
  final String description;
  final String icon;
  final int cost;
  final int maxStack;

  PowerUpItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    required this.maxStack,
  });

  factory PowerUpItem.fromJson(Map<String, dynamic> json) {
    return PowerUpItem(
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      cost: json['cost'] as int,
      maxStack: json['max_stack'] as int,
    );
  }
}

/// Purchase response
class PurchaseResponse {
  final String message;
  final int coinsRemaining;
  final int newQuantity;

  PurchaseResponse({
    required this.message,
    required this.coinsRemaining,
    required this.newQuantity,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      message: json['message'] as String,
      coinsRemaining: json['coins_remaining'] as int,
      newQuantity: json['new_quantity'] as int,
    );
  }

  /// Create PurchaseResponse from backend power-up purchase response
  factory PurchaseResponse.fromBackendResponse(Map<String, dynamic> json) {
    // Backend responses have different field names depending on endpoint
    // streak-freeze: {success, coins_remaining, streak_freezes, message}
    // xp-boost: {success, coins_remaining, xp_boosts, message}
    // hint-reveal: {success, coins_remaining, hints_available, message}
    // time-warp: {success, coins_remaining, skips_available, message}

    final coinsRemaining = json['coins_remaining'] as int? ?? 0;
    final message = json['message'] as String? ?? 'Purchase successful';

    // Try to extract quantity from various possible field names
    int newQuantity = 0;
    if (json.containsKey('streak_freezes')) {
      newQuantity = json['streak_freezes'] as int;
    } else if (json.containsKey('xp_boosts')) {
      newQuantity = json['xp_boosts'] as int;
    } else if (json.containsKey('hints_available')) {
      newQuantity = json['hints_available'] as int;
    } else if (json.containsKey('skips_available')) {
      newQuantity = json['skips_available'] as int;
    }

    return PurchaseResponse(
      message: message,
      coinsRemaining: coinsRemaining,
      newQuantity: newQuantity,
    );
  }
}
