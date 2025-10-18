import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

/// Provider for the currently selected language
final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, String>(
  LanguageController.new,
);

/// Controller for managing the selected language preference
class LanguageController extends AsyncNotifier<String> {
  static const _key = 'selected_language';
  static const _defaultLanguage = 'grc'; // Classical Greek

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);

    // Validate that the stored language code is in our available languages
    if (stored != null && _isValidLanguageCode(stored)) {
      return stored;
    }

    return _defaultLanguage;
  }

  /// Set the selected language by language code
  Future<void> setLanguage(String languageCode) async {
    if (!_isValidLanguageCode(languageCode)) {
      throw ArgumentError('Invalid language code: $languageCode');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
    state = AsyncValue.data(languageCode);
  }

  /// Check if a language code is valid (exists in availableLanguages)
  bool _isValidLanguageCode(String code) {
    return availableLanguages.any((lang) => lang.code == code);
  }

  /// Get the LanguageInfo for the currently selected language
  LanguageInfo? getCurrentLanguageInfo() {
    return state.whenData((code) {
      try {
        return availableLanguages.firstWhere((lang) => lang.code == code);
      } catch (e) {
        return null;
      }
    }).value;
  }
}

/// Provider for getting the current language info (derived from languageControllerProvider)
final currentLanguageInfoProvider = Provider<LanguageInfo?>((ref) {
  final languageCode = ref.watch(languageControllerProvider).value;
  if (languageCode == null) return null;

  try {
    return availableLanguages.firstWhere((lang) => lang.code == languageCode);
  } catch (e) {
    return null;
  }
});

/// Provider for getting only available languages
final availableLanguagesOnlyProvider = Provider<List<LanguageInfo>>((ref) {
  return availableLanguages.where((lang) => lang.isAvailable).toList();
});

/// Provider for getting coming soon languages
final comingSoonLanguagesProvider = Provider<List<LanguageInfo>>((ref) {
  return availableLanguages.where((lang) => lang.comingSoon).toList();
});

/// Provider for getting full course languages
final fullCourseLanguagesProvider = Provider<List<LanguageInfo>>((ref) {
  return availableLanguages.where((lang) => lang.isFullCourse).toList();
});

/// Provider for getting partial course languages
final partialCourseLanguagesProvider = Provider<List<LanguageInfo>>((ref) {
  return availableLanguages.where((lang) => !lang.isFullCourse).toList();
});
