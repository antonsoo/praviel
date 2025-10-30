import 'package:flutter/foundation.dart';

/// Service for tracking combo streaks (consecutive correct answers)
class ComboService extends ChangeNotifier {
  int _currentCombo = 0;
  int _maxCombo = 0;
  int _totalCombos = 0;
  bool _isComboActive = false;

  int get currentCombo => _currentCombo;
  int get maxCombo => _maxCombo;
  int get totalCombos => _totalCombos;
  bool get isComboActive => _isComboActive;

  /// Multiplier for XP based on combo
  double get comboMultiplier {
    if (_currentCombo < 3) return 1.0;
    if (_currentCombo < 5) return 1.2;
    if (_currentCombo < 10) return 1.5;
    if (_currentCombo < 20) return 2.0;
    return 2.5; // 20+ combo
  }

  /// Bonus XP for current combo
  int get bonusXP {
    if (_currentCombo < 3) return 0;
    if (_currentCombo < 5) return 5;
    if (_currentCombo < 10) return 10;
    if (_currentCombo < 20) return 25;
    return 50; // 20+ combo
  }

  /// Get combo tier (for visual effects)
  ComboTier get comboTier {
    if (_currentCombo < 3) return ComboTier.none;
    if (_currentCombo < 5) return ComboTier.bronze;
    if (_currentCombo < 10) return ComboTier.silver;
    if (_currentCombo < 20) return ComboTier.gold;
    return ComboTier.legendary;
  }

  /// Record a correct answer
  void recordCorrect() {
    _currentCombo++;
    _isComboActive = true;

    if (_currentCombo > _maxCombo) {
      _maxCombo = _currentCombo;
    }

    // Track milestone combos
    if (_currentCombo == 5 ||
        _currentCombo == 10 ||
        _currentCombo == 20 ||
        _currentCombo % 50 == 0) {
      _totalCombos++;
    }

    notifyListeners();
  }

  /// Record a wrong answer (breaks combo)
  void recordWrong() {
    if (_currentCombo > 0) {
      _currentCombo = 0;
      _isComboActive = false;
      notifyListeners();
    }
  }

  /// Reset combo (e.g., after lesson ends)
  void reset() {
    _currentCombo = 0;
    _isComboActive = false;
    notifyListeners();
  }

  /// Reset all stats (for testing or user request)
  void resetAll() {
    _currentCombo = 0;
    _maxCombo = 0;
    _totalCombos = 0;
    _isComboActive = false;
    notifyListeners();
  }

  /// Check if combo milestone was reached
  bool isComboMilestone(int combo) {
    return combo == 3 ||
        combo == 5 ||
        combo == 10 ||
        combo == 20 ||
        combo == 50 ||
        combo == 100;
  }

  /// Get message for combo tier
  String getComboMessage() {
    switch (comboTier) {
      case ComboTier.bronze:
        return 'Nice combo!';
      case ComboTier.silver:
        return 'Great streak!';
      case ComboTier.gold:
        return 'Incredible!';
      case ComboTier.legendary:
        return 'LEGENDARY!';
      default:
        return '';
    }
  }

  /// Get emoji for combo tier
  String getComboEmoji() {
    switch (comboTier) {
      case ComboTier.bronze:
        return '✨';
      case ComboTier.silver:
        return '⚡';
      case ComboTier.gold:
        return '🔥';
      case ComboTier.legendary:
        return '💫';
      default:
        return '';
    }
  }
}

/// Combo tier levels
enum ComboTier {
  none, // 0-2
  bronze, // 3-4
  silver, // 5-9
  gold, // 10-19
  legendary, // 20+
}
