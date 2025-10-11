import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user's language preferences
class LanguagePreferences {
  LanguagePreferences({required this.prefs});

  final SharedPreferences prefs;

  static const String _keyLanguage = 'lesson_language';

  /// Get the currently selected language (defaults to 'grc')
  String get selectedLanguage => prefs.getString(_keyLanguage) ?? 'grc';

  /// Set the selected language
  Future<void> setSelectedLanguage(String languageCode) async {
    await prefs.setString(_keyLanguage, languageCode);
  }
}

/// Provider for language preferences
final languagePreferencesProvider = FutureProvider<LanguagePreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LanguagePreferences(prefs: prefs);
});

/// Notifier for the currently selected language
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    // Load initial value from preferences
    _loadLanguage();
    return 'grc'; // Default while loading
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await ref.read(languagePreferencesProvider.future);
      state = prefs.selectedLanguage;
    } catch (e) {
      // Keep default
    }
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;
    try {
      final prefs = await ref.read(languagePreferencesProvider.future);
      await prefs.setSelectedLanguage(languageCode);
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Provider for the currently selected language (reactive)
final selectedLanguageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);
