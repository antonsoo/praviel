import 'package:flutter/widgets.dart';

class LanguageInfo {
  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isAvailable,
    this.comingSoon = false,
    this.script,
    this.textDirection = TextDirection.ltr,
    this.primaryFont,
    this.fallbackFonts,
    this.altEndonym,
    this.tooltip,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isAvailable;
  final bool comingSoon;

  // Extended metadata for historically accurate rendering
  final String? script; // Script description (e.g., "Glagolitic", "Cuneiform")
  final TextDirection textDirection; // LTR or RTL
  final String? primaryFont; // Primary font family
  final List<String>? fallbackFonts; // Fallback font families
  final String? altEndonym; // Alternative endonym (e.g., Cyrillic for OCS)
  final String? tooltip; // Tooltip for reconstructed languages
}

const availableLanguages = [
  // 1. Classical Greek - Available now
  LanguageInfo(
    code: 'grc',
    name: 'Classical Greek',
    nativeName: 'ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ', // Epigraphic capitals with proper dialectal form
    flag: '🏺',
    isAvailable: true,
  ),
  // 2. Classical Latin - Available now
  LanguageInfo(
    code: 'lat',
    name: 'Classical Latin',
    nativeName: 'LINGVA LATINA CLASSICA', // Roman capitals
    flag: '🏛️',
    isAvailable: true,
  ),
  // 3. Old Egyptian - Planned
  LanguageInfo(
    code: 'egy-old',
    name: 'Old Egyptian (OK)',
    nativeName: '𓂋𓈖 𓎡𓅓𓏏', // r n kmt (linearized)
    flag: '🔺',
    isAvailable: false,
    comingSoon: true,
  ),
  // 4. Vedic Sanskrit - Planned
  LanguageInfo(
    code: 'san-vedic',
    name: 'Vedic Sanskrit',
    nativeName: 'वैदिक संस्कृतम्', // Devanagari with proper spacing
    flag: '🕉️',
    isAvailable: false,
    comingSoon: true,
  ),
  // 5. Koine Greek - Planned
  LanguageInfo(
    code: 'grc-koine',
    name: 'Hellenistic Koine',
    nativeName: 'ΚΟΙΝΗ ΔΙΑΛΕΚΤΟΣ', // Historical term for the common dialect
    flag: '📖',
    isAvailable: false,
    comingSoon: true,
  ),
  // 6. Ancient Sumerian - Planned
  LanguageInfo(
    code: 'sux',
    name: 'Ancient Sumerian',
    nativeName: '𒅴𒂠',
    flag: '🧱',
    isAvailable: false,
    comingSoon: true,
  ),
  // 7. Paleo-Hebrew - Planned
  LanguageInfo(
    code: 'hbo-proto',
    name: 'Paleo-Hebrew (Old Hebrew)',
    nativeName: '𐤏𐤁𐤓𐤉', // Phoenician/Paleo-Hebrew script
    flag: '🫒',
    isAvailable: false,
    comingSoon: true,
    script: 'Paleo-Hebrew (Unicode Phoenician)',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Phoenician',
    fallbackFonts: ['Segoe UI Historic'],
  ),
  // 8. Old Church Slavonic - Planned
  LanguageInfo(
    code: 'chu',
    name: 'Old Church Slavonic',
    nativeName: 'ⰔⰎⰑⰂⰡⰐⰟ ⰏⰈⰑⰍⰑ', // Glagolitic (preferred historic script)
    flag: '☦️',
    isAvailable: false,
    comingSoon: true,
    script: 'Glagolitic (preferred)',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Glagolitic',
    fallbackFonts: ['Noto Serif Glagolitic'],
    altEndonym: 'СЛОВѢНЬСКЪ ѨЗЫКЪ',
  ),
  // 9. Akkadian - Planned
  LanguageInfo(
    code: 'akk',
    name: 'Akkadian',
    nativeName: '𒀝𒅗𒁺𒌑', // Akkadian in cuneiform (a-ka-du-u)
    flag: '🦁',
    isAvailable: false,
    comingSoon: true,
  ),
  // 10. Hittite - Planned
  LanguageInfo(
    code: 'hit',
    name: 'Hittite',
    nativeName: 'nešili', // Latin scholarly (cuneiform not standardized for labels)
    flag: '🗡️',
    isAvailable: false,
    comingSoon: true,
  ),
  // 11. Avestan - Planned
  LanguageInfo(
    code: 'ave',
    name: 'Avestan',
    nativeName: '𐬀𐬬𐬆𐬯𐬙𐬁', // Avestan script
    flag: '🔥',
    isAvailable: false,
    comingSoon: true,
    script: 'Avestan',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Avestan',
  ),
  // 12. Ancient Aramaic - Planned
  LanguageInfo(
    code: 'arc',
    name: 'Ancient Aramaic',
    nativeName: '𐡀𐡓𐡌𐡉𐡕', // Imperial Aramaic script
    flag: '🗣️',
    isAvailable: false,
    comingSoon: true,
    script: 'Imperial Aramaic',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Imperial Aramaic',
    fallbackFonts: ['Segoe UI Historic'],
  ),
  // 13. Old Persian - Planned
  LanguageInfo(
    code: 'peo',
    name: 'Old Persian',
    nativeName: '𐎱𐎠𐎼𐎿', // Old Persian cuneiform (pārsa)
    flag: '🏹',
    isAvailable: false,
    comingSoon: true,
  ),
  // 14. Classical Nahuatl - Planned
  LanguageInfo(
    code: 'nci',
    name: 'Classical Nahuatl',
    nativeName: 'NĀHUATLĀHTŌLLI', // With macrons for vowel length
    flag: '🐆',
    isAvailable: false,
    comingSoon: true,
  ),
  // 15. Classical Quechua - Planned
  LanguageInfo(
    code: 'qwc',
    name: 'Classical Quechua',
    nativeName: 'RUNA SIMI', // Historic endonym
    flag: '🦙',
    isAvailable: false,
    comingSoon: true,
  ),
  // 16. Classic Maya - Planned
  LanguageInfo(
    code: 'myn',
    name: 'Classic Maya (Chʼoltiʼ)',
    nativeName: "CHʼOLTIʼ", // Glyphic script proxy
    flag: '🌽',
    isAvailable: false,
    comingSoon: true,
  ),
  // 17. Biblical Hebrew - Available now (Beta)
  LanguageInfo(
    code: 'hbo',
    name: 'Biblical Hebrew',
    nativeName: 'עברית מקראית', // Modern pointed Hebrew script
    flag: '🕎',
    isAvailable: true,
    script: 'Hebrew',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Hebrew',
  ),
  // 18. Middle Egyptian - Later
  LanguageInfo(
    code: 'egy',
    name: 'Middle Egyptian (Classical Egyptian)',
    nativeName: '𓂋𓈖 𓎡𓅓𓏏', // r n kmt (linearized)
    flag: '👁️',
    isAvailable: false,
    comingSoon: false,
  ),
  // 19. Classical Sanskrit - Available now (Beta)
  LanguageInfo(
    code: 'san',
    name: 'Classical Sanskrit',
    nativeName: 'संस्कृतम्', // Devanagari
    flag: '🪷',
    isAvailable: true,
  ),
  // 20. Pali - Planned
  LanguageInfo(
    code: 'pli',
    name: 'Pali',
    nativeName: '𑀧𑀸𑀮𑀺', // Brahmi script (historic)
    flag: '☸️',
    isAvailable: false,
    comingSoon: true,
    script: 'Brahmi (historic look)',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Brahmi',
    altEndonym: 'पाली',
  ),
  // 21. Proto-Germanic - Planned (Reconstructed)
  LanguageInfo(
    code: 'gem-pro',
    name: 'Proto-Germanic',
    nativeName: 'ᚷᛖᚱᛗᚨᚾᛁᛊᚲᚨᛉ', // Elder Futhark runic
    flag: '🪓',
    isAvailable: false,
    comingSoon: true,
    script: 'Runic (Elder Futhark, emblematic)',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Runic',
    tooltip: 'Reconstructed name (*Germāniskaz).',
  ),
  // 22. Proto-Norse - Planned (Reconstructed)
  LanguageInfo(
    code: 'non-pro',
    name: 'Proto-Norse',
    nativeName: 'ᚾᛟᚱᚦᚱᚢᚾᚨ', // Elder Futhark runic
    flag: '🏔️',
    isAvailable: false,
    comingSoon: true,
    script: 'Runic (Elder Futhark, emblematic)',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Runic',
    tooltip: 'Reconstructed label for early Norse.',
  ),
];
