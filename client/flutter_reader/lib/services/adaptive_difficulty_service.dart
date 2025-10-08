import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

/// AI-driven adaptive difficulty system
/// Analyzes user performance and adjusts lesson difficulty dynamically
/// Based on 2025 research: adaptive learning increases engagement by 100-150%
class AdaptiveDifficultyService extends ChangeNotifier {
  static const String _performanceKey = 'adaptive_performance_history';
  static const String _difficultyKey = 'adaptive_current_difficulty';
  static const String _skillsKey = 'adaptive_skill_levels';

  // Current difficulty level (0.0 = easiest, 1.0 = hardest)
  double _currentDifficulty = 0.3; // Start at beginner-friendly level

  // Performance tracking
  final List<PerformanceDataPoint> _performanceHistory = [];
  final Map<SkillCategory, double> _skillLevels = {};

  // Tuning parameters
  static const int _historyWindowSize = 20; // Last 20 exercises
  static const double _targetAccuracy = 0.75; // Aim for 75% success rate
  static const double _adjustmentRate = 0.05; // How fast to adapt

  bool _loaded = false;

  double get currentDifficulty => _currentDifficulty;
  bool get isLoaded => _loaded;
  Map<SkillCategory, double> get skillLevels => Map.unmodifiable(_skillLevels);

  /// Get difficulty as user-friendly label
  String get difficultyLabel {
    if (_currentDifficulty < 0.2) return 'Beginner';
    if (_currentDifficulty < 0.4) return 'Easy';
    if (_currentDifficulty < 0.6) return 'Medium';
    if (_currentDifficulty < 0.8) return 'Hard';
    return 'Expert';
  }

  /// Get skill level for specific category
  double getSkillLevel(SkillCategory category) {
    return _skillLevels[category] ?? 0.5;
  }

  /// Load saved data
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load difficulty
      _currentDifficulty = prefs.getDouble(_difficultyKey) ?? 0.3;

      // Load performance history
      final historyJson = prefs.getString(_performanceKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _performanceHistory.clear();
        _performanceHistory.addAll(
          decoded.map((e) => PerformanceDataPoint.fromJson(e)),
        );
      }

      // Load skill levels
      final skillsJson = prefs.getString(_skillsKey);
      if (skillsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(skillsJson);
        _skillLevels.clear();
        decoded.forEach((key, value) {
          final category = SkillCategory.values.firstWhere(
            (e) => e.toString() == key,
            orElse: () => SkillCategory.vocabulary,
          );
          _skillLevels[category] = value as double;
        });
      } else {
        // Initialize all skills at beginner level
        for (var category in SkillCategory.values) {
          _skillLevels[category] = 0.3;
        }
      }

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AdaptiveDifficultyService] Failed to load: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  /// Record exercise result and adapt difficulty
  Future<void> recordPerformance({
    required bool correct,
    required double timeSpent, // seconds
    required SkillCategory category,
    required String exerciseType,
    double? currentDifficulty,
  }) async {
    // Create data point
    final dataPoint = PerformanceDataPoint(
      timestamp: DateTime.now(),
      correct: correct,
      timeSpent: timeSpent,
      category: category,
      exerciseType: exerciseType,
      difficulty: currentDifficulty ?? _currentDifficulty,
    );

    // Add to history (keep only last N)
    _performanceHistory.add(dataPoint);
    if (_performanceHistory.length > _historyWindowSize) {
      _performanceHistory.removeAt(0);
    }

    // Update skill level for this category
    _updateSkillLevel(category, correct, timeSpent);

    // Adapt overall difficulty
    _adaptDifficulty();

    // Save and notify
    await _save();
    notifyListeners();
  }

  /// Update skill level for specific category
  void _updateSkillLevel(
    SkillCategory category,
    bool correct,
    double timeSpent,
  ) {
    final currentLevel = _skillLevels[category] ?? 0.5;

    // Simple ELO-like adjustment
    // Correct answer + fast = increase skill
    // Wrong answer = decrease skill
    final speedFactor = timeSpent < 10 ? 1.2 : (timeSpent < 20 ? 1.0 : 0.8);
    final delta = correct ? 0.03 * speedFactor : -0.05;

    _skillLevels[category] = (currentLevel + delta).clamp(0.0, 1.0);
  }

  /// Adapt overall difficulty based on recent performance
  void _adaptDifficulty() {
    if (_performanceHistory.length < 5) return; // Need minimum data

    // Calculate recent accuracy (last 10 exercises)
    final recentWindow = min(10, _performanceHistory.length);
    final recent = _performanceHistory.sublist(
      _performanceHistory.length - recentWindow,
    );

    final correctCount = recent.where((p) => p.correct).length;
    final accuracy = correctCount / recent.length;

    // Calculate average time spent
    final avgTime =
        recent.map((p) => p.timeSpent).reduce((a, b) => a + b) / recent.length;

    // Adapt difficulty
    // If accuracy too high AND fast answers = increase difficulty
    // If accuracy too low = decrease difficulty
    if (accuracy > _targetAccuracy + 0.1 && avgTime < 15) {
      _currentDifficulty = min(1.0, _currentDifficulty + _adjustmentRate);
    } else if (accuracy < _targetAccuracy - 0.1) {
      _currentDifficulty = max(0.0, _currentDifficulty - _adjustmentRate);
    } else if (accuracy > _targetAccuracy + 0.05) {
      _currentDifficulty = min(1.0, _currentDifficulty + _adjustmentRate / 2);
    }

    debugPrint(
      '[AdaptiveDifficulty] Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%, '
      'AvgTime: ${avgTime.toStringAsFixed(1)}s, '
      'NewDifficulty: ${(_currentDifficulty * 100).toStringAsFixed(1)}%',
    );
  }

  /// Get recommended difficulty for next exercise
  /// Takes into account skill category
  double getRecommendedDifficulty(SkillCategory category) {
    final skillLevel = _skillLevels[category] ?? 0.5;
    final globalDifficulty = _currentDifficulty;

    // Weighted average: 60% global, 40% category-specific
    return (globalDifficulty * 0.6 + skillLevel * 0.4).clamp(0.0, 1.0);
  }

  /// Get performance insights
  PerformanceInsights getInsights() {
    if (_performanceHistory.isEmpty) {
      return PerformanceInsights(
        overallAccuracy: 0.0,
        averageTime: 0.0,
        totalExercises: 0,
        strongestSkill: null,
        weakestSkill: null,
        recentTrend: Trend.stable,
      );
    }

    // Overall accuracy
    final correctCount = _performanceHistory.where((p) => p.correct).length;
    final overallAccuracy = correctCount / _performanceHistory.length;

    // Average time
    final avgTime =
        _performanceHistory.map((p) => p.timeSpent).reduce((a, b) => a + b) /
        _performanceHistory.length;

    // Find strongest/weakest skills
    SkillCategory? strongest;
    SkillCategory? weakest;
    double maxSkill = 0.0;
    double minSkill = 1.0;

    _skillLevels.forEach((category, level) {
      if (level > maxSkill) {
        maxSkill = level;
        strongest = category;
      }
      if (level < minSkill) {
        minSkill = level;
        weakest = category;
      }
    });

    // Recent trend (last 5 vs previous 5)
    Trend trend = Trend.stable;
    if (_performanceHistory.length >= 10) {
      final recent5 = _performanceHistory.sublist(
        _performanceHistory.length - 5,
      );
      final previous5 = _performanceHistory.sublist(
        _performanceHistory.length - 10,
        _performanceHistory.length - 5,
      );

      final recentAccuracy =
          recent5.where((p) => p.correct).length / recent5.length;
      final previousAccuracy =
          previous5.where((p) => p.correct).length / previous5.length;

      if (recentAccuracy > previousAccuracy + 0.15) {
        trend = Trend.improving;
      } else if (recentAccuracy < previousAccuracy - 0.15) {
        trend = Trend.declining;
      }
    }

    return PerformanceInsights(
      overallAccuracy: overallAccuracy,
      averageTime: avgTime,
      totalExercises: _performanceHistory.length,
      strongestSkill: strongest,
      weakestSkill: weakest,
      recentTrend: trend,
    );
  }

  /// Save data
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save difficulty
      await prefs.setDouble(_difficultyKey, _currentDifficulty);

      // Save performance history
      final historyJson = jsonEncode(
        _performanceHistory.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_performanceKey, historyJson);

      // Save skill levels
      final skillsJson = jsonEncode(
        _skillLevels.map((key, value) => MapEntry(key.toString(), value)),
      );
      await prefs.setString(_skillsKey, skillsJson);
    } catch (e) {
      debugPrint('[AdaptiveDifficultyService] Failed to save: $e');
    }
  }

  /// Reset to defaults
  Future<void> reset() async {
    _currentDifficulty = 0.3;
    _performanceHistory.clear();
    _skillLevels.clear();
    for (var category in SkillCategory.values) {
      _skillLevels[category] = 0.3;
    }
    await _save();
    notifyListeners();
  }
}

/// Performance data point
class PerformanceDataPoint {
  final DateTime timestamp;
  final bool correct;
  final double timeSpent;
  final SkillCategory category;
  final String exerciseType;
  final double difficulty;

  PerformanceDataPoint({
    required this.timestamp,
    required this.correct,
    required this.timeSpent,
    required this.category,
    required this.exerciseType,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'correct': correct,
    'timeSpent': timeSpent,
    'category': category.toString(),
    'exerciseType': exerciseType,
    'difficulty': difficulty,
  };

  factory PerformanceDataPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      correct: json['correct'],
      timeSpent: json['timeSpent'],
      category: SkillCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => SkillCategory.vocabulary,
      ),
      exerciseType: json['exerciseType'],
      difficulty: json['difficulty'],
    );
  }
}

/// Skill categories for targeted learning
enum SkillCategory {
  vocabulary,
  grammar,
  translation,
  comprehension,
  morphology,
  syntax,
}

/// Performance insights
class PerformanceInsights {
  final double overallAccuracy;
  final double averageTime;
  final int totalExercises;
  final SkillCategory? strongestSkill;
  final SkillCategory? weakestSkill;
  final Trend recentTrend;

  PerformanceInsights({
    required this.overallAccuracy,
    required this.averageTime,
    required this.totalExercises,
    required this.strongestSkill,
    required this.weakestSkill,
    required this.recentTrend,
  });
}

enum Trend { improving, stable, declining }
