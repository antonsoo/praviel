import 'dart:convert';
import 'package:http/http.dart' as http;

/// API client for power-up shop
class ShopApi {
  ShopApi({required this.baseUrl});

  final String baseUrl;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Get user's power-up inventory
  Future<ShopInventory> getInventory() async {
    final uri = Uri.parse('$baseUrl/api/v1/shop/inventory');
    final response = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode == 200) {
      return ShopInventory.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load shop inventory: ${response.body}');
    }
  }

  /// Purchase a power-up with coins
  Future<PurchaseResponse> purchase(String powerUpType, {int quantity = 1}) async {
    final uri = Uri.parse('$baseUrl/api/v1/shop/purchase');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'power_up_type': powerUpType,
        'quantity': quantity,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return PurchaseResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Purchase failed');
    }
  }

  /// Use a power-up from inventory
  Future<void> usePowerUp(String powerUpType) async {
    final uri = Uri.parse('$baseUrl/api/v1/shop/use/$powerUpType');
    final response = await http.post(uri, headers: _headers).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to use power-up');
    }
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
}
