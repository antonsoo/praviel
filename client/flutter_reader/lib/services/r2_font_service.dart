import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:flutter/material.dart';

/// Custom DynamicFontsFile implementation for R2-hosted fonts
class R2FontFile extends DynamicFontsFile {
  R2FontFile(
    this.variant,
    this.fontUrl,
  ) : super(
          // SHA256 hash - empty for now, can be added later for security
          '',
          // Expected file length - 0 means no validation
          0,
        );

  final DynamicFontsVariant variant;
  final String fontUrl;

  @override
  String get url => fontUrl;
}

/// Service for loading large font files from Cloudflare R2 storage.
/// This reduces the initial app bundle size by loading fonts on-demand.
class R2FontService {
  static const String _baseUrl = String.fromEnvironment(
    'FONT_CDN_URL',
    defaultValue:
        'https://pub-35bade2f40a5430084e55e747f9c5d27.r2.dev/index-primus',
  );

  static final Map<String, bool> _loadedFonts = {};

  static String _getFontUrl(String fontFamily) {
    // Use WOFF2 format for better compression
    return '$_baseUrl/$fontFamily-VF.woff2';
  }

  /// Load a CJK font family from R2 storage
  static Future<void> loadFont(String fontFamily) async {
    if (_loadedFonts[fontFamily] == true) {
      return;
    }

    try {
      final variant = const DynamicFontsVariant(
        fontWeight: FontWeight.normal,
        fontStyle: FontStyle.normal,
      );

      final fontFile = R2FontFile(
        variant,
        _getFontUrl(fontFamily),
      );

      final fontMap = <DynamicFontsVariant, DynamicFontsFile>{
        variant: fontFile,
      };

      DynamicFonts.register(
        fontFamily,
        fontMap,
      );

      _loadedFonts[fontFamily] = true;
    } catch (e) {
      _loadedFonts[fontFamily] = false;
      rethrow;
    }
  }

  /// Preload all CJK fonts (call on app startup if needed)
  static Future<void> preloadAllFonts() async {
    await Future.wait([
      loadFont('NotoSerifCJKsc'),
      loadFont('NotoSerifCJKjp'),
    ]);
  }

  /// Get TextStyle with R2-loaded font
  /// Call this after loadFont() has completed
  static TextStyle? getTextStyle(String fontFamily) {
    if (_loadedFonts[fontFamily] != true) {
      return null;
    }
    return DynamicFonts.getFont(fontFamily);
  }

  /// Check if a font is currently loaded
  static bool isFontLoaded(String fontFamily) {
    return _loadedFonts[fontFamily] == true;
  }

  /// Get font family for a language code
  static String? getFontFamilyForLanguage(String languageCode) {
    switch (languageCode) {
      case 'lzh': // Classical Chinese
        return 'NotoSerifCJKsc';
      case 'ojp': // Old Japanese
        return 'NotoSerifCJKjp';
      default:
        return null;
    }
  }

  /// Load font for a specific language code
  static Future<void> loadFontForLanguage(String languageCode) async {
    final fontFamily = getFontFamilyForLanguage(languageCode);
    if (fontFamily != null) {
      await loadFont(fontFamily);
    }
  }
}
