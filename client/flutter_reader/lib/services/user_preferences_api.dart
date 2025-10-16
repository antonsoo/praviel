import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// API client for user preferences and settings
class UserPreferencesApi {
  UserPreferencesApi({required this.baseUrl});

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

  /// Get user preferences
  Future<UserPreferences> getPreferences() async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/users/me/preferences');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserPreferences.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to load preferences: ${response.body}');
      }
    });
  }

  /// Update user preferences
  Future<UserPreferences> updatePreferences({
    String? primaryLanguage,
    String? studyLanguage,
    String? difficultyLevel,
    int? dailyGoalXp,
    int? dailyGoalMinutes,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    String? notificationTime,
    String? theme,
    double? fontSize,
    bool? showTranslations,
    bool? showGrammarHints,
    String? ttsVoice,
    double? ttsSpeed,
  }) async {
    return _retryRequest(() async {
      final uri = Uri.parse('$baseUrl/api/v1/users/me/preferences');

      final body = <String, dynamic>{
        if (primaryLanguage != null) 'primary_language': primaryLanguage,
        // Map studyLanguage to language_focus for backend compatibility
        if (studyLanguage != null) 'language_focus': studyLanguage,
        if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
        if (dailyGoalXp != null) 'daily_xp_goal': dailyGoalXp,
        if (dailyGoalMinutes != null) 'daily_goal_minutes': dailyGoalMinutes,
        if (soundEnabled != null) 'sound_enabled': soundEnabled,
        if (hapticsEnabled != null) 'haptics_enabled': hapticsEnabled,
        if (notificationsEnabled != null)
          'notifications_enabled': notificationsEnabled,
        if (notificationTime != null) 'notification_time': notificationTime,
        if (theme != null) 'theme': theme,
        if (fontSize != null) 'font_size': fontSize,
        if (showTranslations != null) 'show_translations': showTranslations,
        if (showGrammarHints != null) 'show_grammar_hints': showGrammarHints,
        if (ttsVoice != null) 'tts_voice': ttsVoice,
        if (ttsSpeed != null) 'tts_speed': ttsSpeed,
      };

      final response = await _client
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return UserPreferences.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to update preferences: ${response.body}');
      }
    });
  }

  void close() {
    _client.close();
  }
}

/// User preferences model
class UserPreferences {
  // Language preferences
  final String primaryLanguage; // User's native language
  final String studyLanguage; // Language being studied (greek, latin, hebrew)
  final String difficultyLevel; // beginner, intermediate, advanced

  // Goals
  final int dailyGoalXp;
  final int dailyGoalMinutes;

  // UI preferences
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final String? notificationTime; // HH:mm format
  final String theme; // light, dark, system
  final double fontSize; // 0.8 - 1.5 multiplier

  // Learning preferences
  final bool showTranslations;
  final bool showGrammarHints;

  // TTS preferences
  final String? ttsVoice;
  final double ttsSpeed; // 0.5 - 2.0

  UserPreferences({
    required this.primaryLanguage,
    required this.studyLanguage,
    required this.difficultyLevel,
    required this.dailyGoalXp,
    required this.dailyGoalMinutes,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.notificationsEnabled,
    this.notificationTime,
    required this.theme,
    required this.fontSize,
    required this.showTranslations,
    required this.showGrammarHints,
    this.ttsVoice,
    required this.ttsSpeed,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      primaryLanguage: json['primary_language'] as String? ?? 'en',
      // Map language_focus from backend to studyLanguage in Flutter
      studyLanguage:
          json['language_focus'] as String? ??
          json['study_language'] as String? ??
          'grc',
      difficultyLevel: json['difficulty_level'] as String? ?? 'beginner',
      dailyGoalXp:
          json['daily_xp_goal'] as int? ?? json['daily_goal_xp'] as int? ?? 50,
      dailyGoalMinutes: json['daily_goal_minutes'] as int? ?? 15,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      hapticsEnabled: json['haptics_enabled'] as bool? ?? true,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      notificationTime: json['notification_time'] as String?,
      theme: json['theme'] as String? ?? 'system',
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 1.0,
      showTranslations: json['show_translations'] as bool? ?? true,
      showGrammarHints: json['show_grammar_hints'] as bool? ?? true,
      ttsVoice: json['tts_voice'] as String?,
      ttsSpeed: (json['tts_speed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_language': primaryLanguage,
      'study_language': studyLanguage,
      'difficulty_level': difficultyLevel,
      'daily_goal_xp': dailyGoalXp,
      'daily_goal_minutes': dailyGoalMinutes,
      'sound_enabled': soundEnabled,
      'haptics_enabled': hapticsEnabled,
      'notifications_enabled': notificationsEnabled,
      'notification_time': notificationTime,
      'theme': theme,
      'font_size': fontSize,
      'show_translations': showTranslations,
      'show_grammar_hints': showGrammarHints,
      'tts_voice': ttsVoice,
      'tts_speed': ttsSpeed,
    };
  }

  UserPreferences copyWith({
    String? primaryLanguage,
    String? studyLanguage,
    String? difficultyLevel,
    int? dailyGoalXp,
    int? dailyGoalMinutes,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    String? notificationTime,
    String? theme,
    double? fontSize,
    bool? showTranslations,
    bool? showGrammarHints,
    String? ttsVoice,
    double? ttsSpeed,
  }) {
    return UserPreferences(
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      studyLanguage: studyLanguage ?? this.studyLanguage,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      dailyGoalXp: dailyGoalXp ?? this.dailyGoalXp,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      showTranslations: showTranslations ?? this.showTranslations,
      showGrammarHints: showGrammarHints ?? this.showGrammarHints,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
    );
  }

  // Convenience getters
  bool get isDarkMode => theme == 'dark';
  bool get isLightMode => theme == 'light';
  bool get isSystemMode => theme == 'system';

  bool get isBeginnerLevel => difficultyLevel == 'beginner';
  bool get isIntermediateLevel => difficultyLevel == 'intermediate';
  bool get isAdvancedLevel => difficultyLevel == 'advanced';

  bool get isStudyingGreek => studyLanguage == 'greek';
  bool get isStudyingLatin => studyLanguage == 'latin';
  bool get isStudyingHebrew => studyLanguage == 'hebrew';
}

/// Preference constants
class PreferenceConstants {
  // Languages
  static const List<String> studyLanguages = ['greek', 'latin', 'hebrew'];
  static const List<String> primaryLanguages = ['en', 'es', 'fr', 'de', 'it'];

  // Difficulty levels
  static const List<String> difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  // Themes
  static const List<String> themes = ['light', 'dark', 'system'];

  // Font size ranges
  static const double minFontSize = 0.8;
  static const double maxFontSize = 1.5;
  static const double defaultFontSize = 1.0;

  // TTS speed ranges
  static const double minTtsSpeed = 0.5;
  static const double maxTtsSpeed = 2.0;
  static const double defaultTtsSpeed = 1.0;

  // Daily goal ranges
  static const int minDailyGoalXp = 10;
  static const int maxDailyGoalXp = 500;
  static const int defaultDailyGoalXp = 50;

  static const int minDailyGoalMinutes = 5;
  static const int maxDailyGoalMinutes = 120;
  static const int defaultDailyGoalMinutes = 15;

  // Display names
  static String studyLanguageDisplayName(String language) {
    switch (language) {
      case 'greek':
        return 'Ancient Greek';
      case 'latin':
        return 'Latin';
      case 'hebrew':
        return 'Ancient Hebrew';
      default:
        return language;
    }
  }

  static String difficultyDisplayName(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return difficulty;
    }
  }

  static String themeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System';
      default:
        return theme;
    }
  }
}
