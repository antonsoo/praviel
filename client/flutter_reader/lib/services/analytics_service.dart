/// Analytics service for tracking user events and celebrations
library;

import 'package:flutter/foundation.dart';

/// Service for tracking analytics events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Track a lesson completion event
  void trackLessonComplete({
    required String languageCode,
    required int xpEarned,
    required double accuracy,
    required int wordsLearned,
    required Duration duration,
    bool levelUp = false,
    int? newLevel,
  }) {
    if (kDebugMode) {
      print('[Analytics] Lesson Complete: $languageCode');
      print('  XP: $xpEarned, Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%');
      print('  Words: $wordsLearned, Duration: ${duration.inSeconds}s');
      if (levelUp) print('  Level Up: $newLevel');
    }

    _logEvent('lesson_complete', {
      'language': languageCode,
      'xp_earned': xpEarned,
      'accuracy': accuracy,
      'words_learned': wordsLearned,
      'duration_seconds': duration.inSeconds,
      'level_up': levelUp,
      if (newLevel != null) 'new_level': newLevel,
    });
  }

  /// Track a celebration shown event
  void trackCelebrationShown({
    required String celebrationType,
    required Map<String, dynamic> metadata,
  }) {
    if (kDebugMode) {
      print('[Analytics] Celebration Shown: $celebrationType');
    }

    _logEvent('celebration_shown', {
      'celebration_type': celebrationType,
      ...metadata,
    });
  }

  /// Track a word tap in Reader
  void trackWordTap({
    required String word,
    required String language,
    bool addedToSRS = false,
  }) {
    if (kDebugMode) {
      print('[Analytics] Word Tap: $word ($language)');
      if (addedToSRS) print('  Added to SRS');
    }

    _logEvent('word_tap', {
      'word': word,
      'language': language,
      'added_to_srs': addedToSRS,
    });
  }

  /// Track a page transition
  void trackPageTransition({
    required String from,
    required String to,
    required String transitionType,
  }) {
    if (kDebugMode) {
      print('[Analytics] Page Transition: $from → $to ($transitionType)');
    }

    _logEvent('page_transition', {
      'from': from,
      'to': to,
      'transition_type': transitionType,
    });
  }

  /// Track an achievement unlocked
  void trackAchievementUnlocked({
    required String achievementId,
    required String achievementName,
  }) {
    if (kDebugMode) {
      print('[Analytics] Achievement Unlocked: $achievementName');
    }

    _logEvent('achievement_unlocked', {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
    });
  }

  /// Track a feature usage
  void trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      print('[Analytics] Feature Used: $featureName');
    }

    _logEvent('feature_usage', {
      'feature': featureName,
      if (metadata != null) ...metadata,
    });
  }

  /// Track an error
  void trackError({
    required String errorType,
    required String errorMessage,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('[Analytics] Error: $errorType - $errorMessage');
    }

    _logEvent('error', {
      'error_type': errorType,
      'error_message': errorMessage,
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
    });
  }

  /// Internal method to log events
  /// In production, this would send to analytics backend
  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    // In production, send to analytics service (Firebase, Mixpanel, etc.)
    // For now, just debug logging
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] Event: $eventName');
      parameters.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }

  /// Set user properties
  void setUserProperties({
    required String userId,
    Map<String, dynamic>? properties,
  }) {
    if (kDebugMode) {
      print('[Analytics] Set User Properties: $userId');
    }

    // In production, set user properties in analytics service
  }

  /// Track screen view
  void trackScreenView({
    required String screenName,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      print('[Analytics] Screen View: $screenName');
    }

    _logEvent('screen_view', {
      'screen_name': screenName,
      if (metadata != null) ...metadata,
    });
  }
}
