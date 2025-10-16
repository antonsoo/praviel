import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported ancient languages
enum AncientLanguage {
  greek('grc', 'Ancient Greek', 'ἑλληνική'),
  latin('lat', 'Latin', 'Latīna'),
  hebrew('hbo', 'Biblical Hebrew', 'עברית'),
  sanskrit('san', 'Sanskrit', 'संस्कृतम्');

  const AncientLanguage(this.code, this.englishName, this.nativeName);

  final String code;
  final String englishName;
  final String nativeName;

  String get displayName => '$englishName ($nativeName)';

  static AncientLanguage fromCode(String code) {
    return values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AncientLanguage.greek,
    );
  }
}

final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, AncientLanguage>(
      LanguageController.new,
    );

class LanguageController extends AsyncNotifier<AncientLanguage> {
  static const _key = 'selected_language';

  @override
  Future<AncientLanguage> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      return AncientLanguage.fromCode(stored);
    }
    return AncientLanguage.greek; // Default to Ancient Greek
  }

  Future<void> setLanguage(AncientLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.code);
    state = AsyncValue.data(language);
  }
}
