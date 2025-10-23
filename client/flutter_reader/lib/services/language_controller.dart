import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

/// Structured buckets of languages for menu rendering.
class LanguageMenuSections {
  const LanguageMenuSections({
    required this.allOrdered,
    required this.availableFullCourses,
    required this.availablePartialCourses,
    required this.comingSoonFullCourses,
    required this.comingSoonPartialCourses,
  });

  final List<LanguageInfo> allOrdered;
  final List<LanguageInfo> availableFullCourses;
  final List<LanguageInfo> availablePartialCourses;
  final List<LanguageInfo> comingSoonFullCourses;
  final List<LanguageInfo> comingSoonPartialCourses;

  /// Languages that can be selected right now (full + partial courses).
  List<LanguageInfo> get available => [
    ...availableFullCourses,
    ...availablePartialCourses,
  ];

  /// Languages not yet available to learners.
  List<LanguageInfo> get comingSoon => [
    ...comingSoonFullCourses,
    ...comingSoonPartialCourses,
  ];
}

/// Provider for the currently selected language
final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, String>(LanguageController.new);

/// Controller for managing the selected language preference
class LanguageController extends AsyncNotifier<String> {
  static const _key = 'selected_language';
  static const _defaultLanguage = 'grc-cls'; // Classical Greek

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);

    // Migrate old 'grc' to 'grc-cls' for backwards compatibility
    if (stored == 'grc') {
      await prefs.setString(_key, 'grc-cls');
      return 'grc-cls';
    }

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

/// Provider for retrieving all languages in canonical order.
final orderedLanguagesProvider = Provider<List<LanguageInfo>>((ref) {
  return List<LanguageInfo>.unmodifiable(availableLanguages);
});

/// Provider for structured language menu buckets (available vs coming soon).
final languageMenuSectionsProvider = Provider<LanguageMenuSections>((ref) {
  final ordered = ref.watch(orderedLanguagesProvider);
  final availableFull = <LanguageInfo>[];
  final availablePartial = <LanguageInfo>[];
  final comingSoonFull = <LanguageInfo>[];
  final comingSoonPartial = <LanguageInfo>[];

  for (final language in ordered) {
    if (language.isAvailable) {
      if (language.isFullCourse) {
        availableFull.add(language);
      } else {
        availablePartial.add(language);
      }
    } else {
      if (language.isFullCourse) {
        comingSoonFull.add(language);
      } else {
        comingSoonPartial.add(language);
      }
    }
  }

  return LanguageMenuSections(
    allOrdered: ordered,
    availableFullCourses: List<LanguageInfo>.unmodifiable(availableFull),
    availablePartialCourses: List<LanguageInfo>.unmodifiable(availablePartial),
    comingSoonFullCourses: List<LanguageInfo>.unmodifiable(comingSoonFull),
    comingSoonPartialCourses: List<LanguageInfo>.unmodifiable(
      comingSoonPartial,
    ),
  );
});

/// Provider for getting only languages that are currently selectable.
final availableLanguagesOnlyProvider = Provider<List<LanguageInfo>>((ref) {
  final sections = ref.watch(languageMenuSectionsProvider);
  return List<LanguageInfo>.unmodifiable(sections.available);
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
