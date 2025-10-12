import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/power_up.dart';
import 'backend_progress_service.dart';
import '../api/progress_api.dart';

/// Service for managing power-ups and boosters
class PowerUpService extends ChangeNotifier {
  PowerUpService(BackendProgressService progressService, {ProgressApi? progressApi})
      : _progressService = progressService,
        _progressApi = progressApi;

  final BackendProgressService _progressService;
  final ProgressApi? _progressApi;

  static const String _inventoryKey = 'power_up_inventory';
  static const String _activeKey = 'active_power_ups';
  static const String _coinsKey = 'coins';

  Map<PowerUpType, int> _inventory = {};
  List<ActivePowerUp> _activePowerUps = [];
  int _coins = 0;
  bool _loaded = false;

  Map<PowerUpType, int> get inventory => Map.unmodifiable(_inventory);
  List<ActivePowerUp> get activePowerUps => List.unmodifiable(_activePowerUps);
  int get coins => _coins;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load inventory
      final inventoryJson = prefs.getString(_inventoryKey);
      if (inventoryJson != null) {
        final decoded = json.decode(inventoryJson) as Map<String, dynamic>;
        _inventory = decoded.map(
          (key, value) => MapEntry(
            PowerUpType.values.firstWhere((e) => e.name == key),
            value as int,
          ),
        );
      }

      // Load active power-ups
      final activeJson = prefs.getString(_activeKey);
      if (activeJson != null) {
        final decoded = json.decode(activeJson) as List;
        _activePowerUps = decoded
            .map((item) => _activePowerUpFromJson(item))
            .where((p) => p.isActive) // Filter expired
            .toList();
      }

      // Load coins
      _coins = prefs.getInt(_coinsKey) ?? 0;

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[PowerUpService] Failed to load: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  /// Add coins (earned from lessons, achievements, etc.)
  Future<void> addCoins(int amount) async {
    _coins += amount;
    await _save();
    notifyListeners();
  }

  /// Purchase a power-up
  Future<bool> purchase(PowerUp powerUp) async {
    if (_coins < powerUp.cost) {
      return false; // Not enough coins
    }

    _coins -= powerUp.cost;
    _inventory[powerUp.type] = (_inventory[powerUp.type] ?? 0) + 1;
    await _save();
    notifyListeners();
    return true;
  }

  /// Activate a power-up
  Future<bool> activate(PowerUp powerUp) async {
    if (!hasInInventory(powerUp.type)) {
      return false; // Don't have this power-up
    }

    // Check if already active (prevent duplicates for some types)
    if (_isAlreadyActive(powerUp.type)) {
      return false;
    }

    // Validate with backend if API is available
    if (_progressApi != null && _progressService.isUsingBackend) {
      try {
        final api = _progressApi;
        switch (powerUp.type) {
          case PowerUpType.xpBoost:
            await api.activateXpBoost();
            break;
          case PowerUpType.hint:
            await api.useHint();
            break;
          case PowerUpType.skipQuestion:
            await api.useSkip();
            break;
          default:
            // Other power-ups don't need backend validation
            break;
        }

        // Sync progress after backend update
        await _progressService.refresh();
      } catch (e) {
        debugPrint('[PowerUpService] Backend activation failed: $e');
        // If backend fails, don't activate locally either
        return false;
      }
    }

    _inventory[powerUp.type] = _inventory[powerUp.type]! - 1;
    if (_inventory[powerUp.type]! <= 0) {
      _inventory.remove(powerUp.type);
    }

    _activePowerUps.add(
      ActivePowerUp(
        powerUp: powerUp,
        activatedAt: DateTime.now(),
        usesRemaining: _getUsesForPowerUp(powerUp.type),
      ),
    );

    await _save();
    notifyListeners();
    return true;
  }

  /// Use an active power-up (decrements uses)
  Future<void> use(PowerUpType type) async {
    final index = _activePowerUps.indexWhere((p) => p.powerUp.type == type);
    if (index == -1) return;

    final powerUp = _activePowerUps[index];
    final newUses = powerUp.usesRemaining - 1;

    if (newUses <= 0) {
      _activePowerUps.removeAt(index);
    } else {
      _activePowerUps[index] = ActivePowerUp(
        powerUp: powerUp.powerUp,
        activatedAt: powerUp.activatedAt,
        usesRemaining: newUses,
      );
    }

    await _save();
    notifyListeners();
  }

  /// Check if a power-up is active
  bool isActive(PowerUpType type) {
    _cleanupExpired();
    return _activePowerUps.any((p) => p.powerUp.type == type && p.isActive);
  }

  /// Get active power-up of a type
  ActivePowerUp? getActive(PowerUpType type) {
    _cleanupExpired();
    return _activePowerUps
                .firstWhere(
                  (p) => p.powerUp.type == type && p.isActive,
                  orElse: () => ActivePowerUp(
                    powerUp: PowerUp.hint,
                    activatedAt: DateTime.now(),
                    usesRemaining: 0,
                  ),
                )
                .usesRemaining >
            0
        ? _activePowerUps.firstWhere((p) => p.powerUp.type == type)
        : null;
  }

  /// Check if power-up is in inventory
  bool hasInInventory(PowerUpType type) {
    return (_inventory[type] ?? 0) > 0;
  }

  /// Get count of power-up in inventory
  int getCount(PowerUpType type) {
    return _inventory[type] ?? 0;
  }

  bool _isAlreadyActive(PowerUpType type) {
    // Allow multiple hints/skips, but not multiple XP boosts
    switch (type) {
      case PowerUpType.xpBoost:
      case PowerUpType.freezeStreak:
      case PowerUpType.slowTime:
        return isActive(type);
      default:
        return false;
    }
  }

  int _getUsesForPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.skipQuestion:
      case PowerUpType.hint:
      case PowerUpType.autoComplete:
        return 1; // Single use
      case PowerUpType.xpBoost:
      case PowerUpType.slowTime:
        return 999; // Duration-based, effectively unlimited uses
      case PowerUpType.freezeStreak:
        return 1; // Protects for duration
    }
  }

  void _cleanupExpired() {
    _activePowerUps.removeWhere((p) => p.isExpired);
  }

  ActivePowerUp _activePowerUpFromJson(Map<String, dynamic> json) {
    final type = PowerUpType.values.firstWhere((e) => e.name == json['type']);
    final powerUp = PowerUp.all.firstWhere((p) => p.type == type);

    return ActivePowerUp(
      powerUp: powerUp,
      activatedAt: DateTime.parse(json['activatedAt']),
      usesRemaining: json['usesRemaining'],
    );
  }

  Map<String, dynamic> _activePowerUpToJson(ActivePowerUp powerUp) {
    return {
      'type': powerUp.powerUp.type.name,
      'activatedAt': powerUp.activatedAt.toIso8601String(),
      'usesRemaining': powerUp.usesRemaining,
    };
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save inventory
      final inventoryMap = _inventory.map(
        (key, value) => MapEntry(key.name, value),
      );
      await prefs.setString(_inventoryKey, json.encode(inventoryMap));

      // Save active power-ups
      _cleanupExpired();
      final activeList = _activePowerUps.map(_activePowerUpToJson).toList();
      await prefs.setString(_activeKey, json.encode(activeList));

      // Save coins
      await prefs.setInt(_coinsKey, _coins);
    } catch (e) {
      debugPrint('[PowerUpService] Failed to save: $e');
    }
  }

  Future<void> reset() async {
    _inventory.clear();
    _activePowerUps.clear();
    _coins = 0;
    await _save();
    notifyListeners();
  }

  /// Grant free starter power-ups for new users
  Future<void> grantStarterPowerUps() async {
    _inventory[PowerUpType.hint] = 3;
    _inventory[PowerUpType.skipQuestion] = 1;
    _coins = 50;
    await _save();
    notifyListeners();
  }
}
