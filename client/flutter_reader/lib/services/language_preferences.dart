import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_providers.dart';
import 'music_service.dart';

/// Service for managing user's language preferences
class LanguagePreferences {
  LanguagePreferences({required this.prefs});

  final SharedPreferences prefs;

  static const String _keyLanguage = 'selected_language';

  /// Get the currently selected language (defaults to Classical Latin)
  String get selectedLanguage => prefs.getString(_keyLanguage) ?? 'lat';

  /// Set the selected language
  Future<void> setSelectedLanguage(String languageCode) async {
    await prefs.setString(_keyLanguage, languageCode);
  }
}

/// Provider for language preferences
final languagePreferencesProvider = FutureProvider<LanguagePreferences>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return LanguagePreferences(prefs: prefs);
});

/// Notifier for the currently selected language (syncs with backend when authenticated)
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    // Load initial value from backend (if authenticated) or local storage
    _loadLanguage();
    return 'lat'; // Default while loading (Latin is primary onboarding language)
  }

  Future<void> _loadLanguage() async {
    String? resolvedLanguage;
    try {
      // Try to load from backend first (if authenticated)
      final authService = ref.read(authServiceProvider);
      if (authService.isAuthenticated) {
        try {
          final prefsApi = ref.read(userPreferencesApiProvider);
          final prefs = await prefsApi.getPreferences();
          if (prefs.studyLanguage.isNotEmpty) {
            resolvedLanguage = prefs.studyLanguage;
            state = resolvedLanguage;
            // Update local cache
            final localPrefs = await ref.read(
              languagePreferencesProvider.future,
            );
            await localPrefs.setSelectedLanguage(prefs.studyLanguage);
            return;
          }
        } catch (e) {
          debugPrint('[LanguageNotifier] Failed to load from backend: $e');
          // Fall through to local storage
        }
      }

      // Fall back to local storage
      final localPrefs = await ref.read(languagePreferencesProvider.future);
      resolvedLanguage = localPrefs.selectedLanguage;
      state = resolvedLanguage;
    } catch (e) {
      debugPrint('[LanguageNotifier] Failed to load language: $e');
      // Keep default
    } finally {
      final language = resolvedLanguage ?? state;
      if (language.isNotEmpty) {
        unawaited(
          MusicService.instance.playMusicForLanguage(languageCode: language),
        );
      }
    }
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;

    // Save to local storage immediately
    try {
      final localPrefs = await ref.read(languagePreferencesProvider.future);
      await localPrefs.setSelectedLanguage(languageCode);
    } catch (e) {
      debugPrint('[LanguageNotifier] Failed to save to local storage: $e');
    }

    unawaited(
      MusicService.instance.playMusicForLanguage(languageCode: languageCode),
    );

    // Sync to backend if authenticated (fire and forget)
    final authService = ref.read(authServiceProvider);
    if (authService.isAuthenticated) {
      try {
        final prefsApi = ref.read(userPreferencesApiProvider);
        await prefsApi.updatePreferences(studyLanguage: languageCode);
        debugPrint(
          '[LanguageNotifier] Synced language to backend: $languageCode',
        );
      } catch (e) {
        debugPrint('[LanguageNotifier] Failed to sync language to backend: $e');
        // Don't throw - local save succeeded
      }
    }
  }
}

/// Provider for the currently selected language (reactive)
final selectedLanguageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);
