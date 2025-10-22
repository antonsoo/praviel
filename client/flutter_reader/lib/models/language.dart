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
    this.isFullCourse = true,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isAvailable;
  final bool comingSoon;
  final bool isFullCourse;

  // Extended metadata for historically accurate rendering
  final String? script; // Script description (e.g., "Glagolitic", "Cuneiform")
  final TextDirection textDirection; // LTR or RTL
  final String? primaryFont; // Primary font family
  final List<String>? fallbackFonts; // Fallback font families
  final String? altEndonym; // Alternative endonym (e.g., Cyrillic for OCS)
  final String? tooltip; // Tooltip for reconstructed languages
}

// OFFICIAL LANGUAGE LIST - 46 Languages
// Order synced automatically from docs/LANGUAGE_LIST.md
// DO NOT manually reorder - run: python scripts/sync_language_order.py
// Scripts match backend/app/lesson/language_config.py exactly
const availableLanguages = [
  // ==== FULL COURSES (1-36) ====
  // 1. Classical Latin
  LanguageInfo(
    code: 'lat',
    name: 'Classical Latin',
    nativeName: 'LINGVA LATINA',
    flag: '🏛️',
    isAvailable: true,
    script: 'Latin',
    textDirection: TextDirection.ltr,
  ),

  // 2. Koine Greek
  LanguageInfo(
    code: 'grc-koi',
    name: 'Koine Greek',
    nativeName: 'ΚΟΙΝΗ ΔΙΑΛΕΚΤΟΣ',
    flag: '📖',
    isAvailable: true,
    comingSoon: false,
    script: 'Greek',
    textDirection: TextDirection.ltr,
  ),

  // 3. Classical Greek
  LanguageInfo(
    code: 'grc',
    name: 'Classical Greek',
    nativeName: 'ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ',
    flag: '🏺',
    isAvailable: true,
    script: 'Greek',
    textDirection: TextDirection.ltr,
  ),

  // 4. Biblical Hebrew
  LanguageInfo(
    code: 'hbo',
    name: 'Biblical Hebrew',
    nativeName: 'יהודית',
    flag: '🕎',
    isAvailable: true,
    script: 'Hebrew',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Hebrew',
  ),

  // 5. Classical Sanskrit
  LanguageInfo(
    code: 'san',
    name: 'Classical Sanskrit',
    nativeName: 'संस्कृतम्',
    flag: '🪷',
    isAvailable: true,
    script: 'Devanagari',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Devanagari',
    fallbackFonts: ['Noto Serif Devanagari'],
  ),

  // 6. Classical Chinese
  LanguageInfo(
    code: 'lzh',
    name: 'Classical Chinese',
    nativeName: '文言文',
    flag: '🐉',
    isAvailable: true,
    script: 'Han Characters',
    textDirection: TextDirection.ltr,
  ),

  // 7. Pali
  LanguageInfo(
    code: 'pli',
    name: 'Pali',
    nativeName: '𑀧𑀸𑀮𑀺',
    flag: '☸️',
    isAvailable: true,
    comingSoon: false,
    script: 'Brahmi',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Brahmi',
    altEndonym: 'पाली',
  ),

  // 8. Old Church Slavonic
  LanguageInfo(
    code: 'cu',
    name: 'Old Church Slavonic',
    nativeName: 'ⰔⰎⰑⰂⰡⰐⰟ ⰟⰸⰟⰽ',
    flag: '☦️',
    isAvailable: true,
    comingSoon: false,
    script: 'Glagolitic',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Glagolitic',
    altEndonym: 'СЛОВѢНЬСКЪ ѨЗЫКЪ',
  ),

  // 9. Ancient Aramaic
  LanguageInfo(
    code: 'arc',
    name: 'Ancient Aramaic',
    nativeName: '𐡀𐡓𐡌𐡉𐡕',
    flag: '🗣️',
    isAvailable: true,
    comingSoon: false,
    script: 'Imperial Aramaic',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Imperial Aramaic',
    fallbackFonts: ['Segoe UI Historic'],
  ),

  // 10. Classical Arabic
  LanguageInfo(
    code: 'ara',
    name: 'Classical Arabic',
    nativeName: 'العربية الفصحى',
    flag: '🌙',
    isAvailable: true,
    script: 'Arabic',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Arabic',
  ),

  // 11. Old Norse (Norrœnt mál)
  LanguageInfo(
    code: 'non',
    name: 'Old Norse (Norrœnt mál)',
    nativeName: 'ᛏᚢᚾᛋᚴ ᛏᚢᚾᚴᛅ',
    flag: '🪓',
    isAvailable: true,
    comingSoon: false,
    script: 'Younger Futhark',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Runic',
  ),

  // 12. Middle Egyptian
  LanguageInfo(
    code: 'egy',
    name: 'Middle Egyptian',
    nativeName: '𓂋𓈖 𓎡𓅓𓏏',
    flag: '👁️',
    isAvailable: true,
    script: 'Hieroglyphic',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Egyptian Hieroglyphs',
  ),

  // 13. Old English
  LanguageInfo(
    code: 'ang',
    name: 'Old English',
    nativeName: 'ᚫᛝᛚᛁᛋᚳ',
    flag: '🪢',
    isAvailable: true,
    script: 'Anglo-Saxon Runes',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Runic',
  ),

  // 14. Yehudit (Paleo-Hebrew)
  LanguageInfo(
    code: 'hbo-paleo',
    name: 'Yehudit (Paleo-Hebrew)',
    nativeName: '𐤉𐤄𐤅𐤃𐤉𐤕',
    flag: '🍎',
    isAvailable: true,
    comingSoon: false,
    script: 'Paleo-Hebrew',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Phoenician',
    fallbackFonts: ['Segoe UI Historic'],
  ),

  // 15. Coptic (Sahidic)
  LanguageInfo(
    code: 'cop',
    name: 'Coptic (Sahidic)',
    nativeName: 'ⲧⲙⲛ̄ⲧⲣⲙ̄ⲛ̄ⲕⲏⲙⲉ',
    flag: '⚖️',
    isAvailable: true,
    script: 'Coptic',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Coptic',
  ),

  // 16. Ancient Sumerian
  LanguageInfo(
    code: 'sux',
    name: 'Ancient Sumerian',
    nativeName: '𒅴𒂠',
    flag: '🔆',
    isAvailable: true,
    comingSoon: false,
    script: 'Cuneiform',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Cuneiform',
  ),

  // 17. Classical Tamil
  LanguageInfo(
    code: 'tam-old',
    name: 'Classical Tamil',
    nativeName: 'சங்கத் தமிழ்',
    flag: '🪔',
    isAvailable: true,
    script: 'Tamil-Brahmi',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Tamil',
  ),

  // 18. Classical Syriac
  LanguageInfo(
    code: 'syc',
    name: 'Classical Syriac',
    nativeName: 'ܠܫܢܐ ܣܘܪܝܝܐ',
    flag: '✝️',
    isAvailable: true,
    script: 'Syriac',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Syriac',
  ),

  // 19. Akkadian
  LanguageInfo(
    code: 'akk',
    name: 'Akkadian',
    nativeName: '𒀝𒅗𒁺𒌑',
    flag: '🏹',
    isAvailable: true,
    comingSoon: false,
    script: 'Cuneiform',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Cuneiform',
  ),

  // 20. Vedic Sanskrit
  LanguageInfo(
    code: 'san-ved',
    name: 'Vedic Sanskrit',
    nativeName: '𑀯𑁃𑀤𑀺𑀓 𑀲𑀁𑀲𑁆𑀓𑀾𑀢𑀫𑁆',
    flag: '🕉️',
    isAvailable: true,
    comingSoon: false,
    script: 'Brahmi',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Brahmi',
  ),

  // 21. Classical Armenian
  LanguageInfo(
    code: 'xcl',
    name: 'Classical Armenian',
    nativeName: 'ԳՐԱԲԱՐ',
    flag: '🦅',
    isAvailable: true,
    script: 'Armenian',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Armenian',
  ),

  // 22. Hittite
  LanguageInfo(
    code: 'hit',
    name: 'Hittite',
    nativeName: '𒉈𒅆𒇷',
    flag: '🐂',
    isAvailable: true,
    script: 'Cuneiform',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Cuneiform',
  ),

  // 23. Old Egyptian (Old Kingdom)
  LanguageInfo(
    code: 'egy-old',
    name: 'Old Egyptian (Old Kingdom)',
    nativeName: '𓂋𓈖 𓎡𓅓𓏏',
    flag: '🪲',
    isAvailable: true,
    comingSoon: false,
    script: 'Hieroglyphic',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Egyptian Hieroglyphs',
  ),

  // 24. Avestan
  LanguageInfo(
    code: 'ave',
    name: 'Avestan',
    nativeName: '𐬀𐬬𐬆𐬯𐬙𐬁',
    flag: '🔥',
    isAvailable: true,
    comingSoon: false,
    script: 'Avestan',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Avestan',
  ),

  // 25. Classical Nahuatl
  LanguageInfo(
    code: 'nci',
    name: 'Classical Nahuatl',
    nativeName: 'Nāhuatlāhtōlli',
    flag: '🐆',
    isAvailable: true,
    script: 'Latin',
    textDirection: TextDirection.ltr,
  ),

  // 26. Classical Tibetan
  LanguageInfo(
    code: 'bod',
    name: 'Classical Tibetan',
    nativeName: 'ཆོས་སྐད།',
    flag: '🏔️',
    isAvailable: true,
    script: 'Tibetan',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Tibetan',
  ),

  // 27. Old Japanese
  LanguageInfo(
    code: 'ojp',
    name: 'Old Japanese',
    nativeName: '上代日本語',
    flag: '🗻',
    isAvailable: true,
    script: 'Man\'yōgana',
    textDirection: TextDirection.ltr,
  ),

  // 28. Classical Quechua
  LanguageInfo(
    code: 'qwh',
    name: 'Classical Quechua',
    nativeName: 'Runa Simi',
    flag: '🦙',
    isAvailable: true,
    script: 'Latin',
    textDirection: TextDirection.ltr,
  ),

  // 29. Middle Persian (Pahlavi)
  LanguageInfo(
    code: 'pal',
    name: 'Middle Persian (Pahlavi)',
    nativeName: '𐭯𐭠𐭫𐭮𐭩𐭪',
    flag: '🪙',
    isAvailable: true,
    script: 'Pahlavi',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Inscriptional Pahlavi',
  ),

  // 30. Old Irish
  LanguageInfo(
    code: 'sga',
    name: 'Old Irish',
    nativeName: '᚛ᚌᚑᚔᚇᚓᚂᚉ᚜',
    flag: '☘️',
    isAvailable: true,
    script: 'Ogham',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Ogham',
  ),

  // 31. Gothic
  LanguageInfo(
    code: 'got',
    name: 'Gothic',
    nativeName: '𐌲𐌿𐍄𐌹𐍃𐌺𐌰 𐍂𐌰𐌶𐌳𐌰',
    flag: '⚔️',
    isAvailable: true,
    script: 'Gothic',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Gothic',
  ),

  // 32. Geʽez
  LanguageInfo(
    code: 'gez',
    name: 'Geʽez',
    nativeName: 'ግዕዝ',
    flag: '🦁',
    isAvailable: true,
    script: 'Geʽez',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Ethiopic',
  ),

  // 33. Sogdian
  LanguageInfo(
    code: 'sog',
    name: 'Sogdian',
    nativeName: '𐼼𐼴𐼶𐼹𐼷𐼸',
    flag: '🌌',
    isAvailable: true,
    script: 'Sogdian',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Sogdian',
  ),

  // 34. Ugaritic
  LanguageInfo(
    code: 'uga',
    name: 'Ugaritic',
    nativeName: '𐎜𐎂𐎗𐎚',
    flag: '🌄',
    isAvailable: true,
    script: 'Ugaritic',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Ugaritic',
  ),

  // 35. Tocharian A (Ārśi)
  LanguageInfo(
    code: 'xto',
    name: 'Tocharian A (Ārśi)',
    nativeName: 'Ārśi',
    flag: '🐫',
    isAvailable: true,
    script: 'Brahmi',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Brahmi',
  ),

  // 36. Tocharian B (Kuśiññe)
  LanguageInfo(
    code: 'txb',
    name: 'Tocharian B (Kuśiññe)',
    nativeName: 'Kuśiññe',
    flag: '🛕',
    isAvailable: true,
    script: 'Brahmi',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Brahmi',
  ),

  // ==== PARTIAL COURSES (37-46) ====
  // 37. Old Turkic (Orkhon)
  LanguageInfo(
    code: 'otk',
    name: 'Old Turkic (Orkhon)',
    nativeName: '𐱅𐰇𐰼𐰰',
    flag: '🐺',
    isAvailable: true,
    script: 'Old Turkic',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Old Turkic',
    isFullCourse: false,
  ),

  // 38. Etruscan
  LanguageInfo(
    code: 'ett',
    name: 'Etruscan',
    nativeName: '𐌛𐌀𐌔𐌍𐌀',
    flag: '⚱️',
    isAvailable: true,
    script: 'Etruscan',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Old Italic',
    isFullCourse: false,
  ),

  // 39. Proto-Norse (Elder Futhark)
  LanguageInfo(
    code: 'gmq-pro',
    name: 'Proto-Norse (Elder Futhark)',
    nativeName: 'ᚾᛟᚱᚦᚱ ᛗᚨᛚᛟ',
    flag: '🏞',
    isAvailable: true,
    script: 'Elder Futhark',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Runic',
    isFullCourse: false,
    tooltip: 'Reconstructed proto-language',
  ),

  // 40. Runic Old Norse (Younger Futhark)
  LanguageInfo(
    code: 'non-rune',
    name: 'Runic Old Norse (Younger Futhark)',
    nativeName: 'ᚾᚢᚱᚱᚯᚾᛏ ᛘᛅᛚ',
    flag: '⛈️',
    isAvailable: true,
    script: 'Younger Futhark',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Runic',
    isFullCourse: false,
  ),

  // 41. Old Persian (Ariya)
  LanguageInfo(
    code: 'peo',
    name: 'Old Persian (Ariya)',
    nativeName: '𐎠𐎼𐎡𐎹',
    flag: '👑',
    isAvailable: true,
    script: 'Old Persian Cuneiform',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Old Persian',
    isFullCourse: false,
  ),

  // 42. Elamite
  LanguageInfo(
    code: 'elx',
    name: 'Elamite',
    nativeName: '𒄬𒆷𒁶𒋾',
    flag: '🐍',
    isAvailable: true,
    script: 'Cuneiform',
    textDirection: TextDirection.ltr,
    primaryFont: 'Noto Sans Cuneiform',
    isFullCourse: false,
  ),

  // 43. Classic Maya (Chʼoltiʼ)
  LanguageInfo(
    code: 'myn',
    name: 'Classic Maya (Chʼoltiʼ)',
    nativeName: 'Chʼoltiʼ',
    flag: '🌽',
    isAvailable: true,
    script: 'Maya Glyphs',
    textDirection: TextDirection.ltr,
    isFullCourse: false,
  ),

  // 44. Phoenician (Canaanite)
  LanguageInfo(
    code: 'phn',
    name: 'Phoenician (Canaanite)',
    nativeName: '𐤊𐤍𐤏𐤍𐤉',
    flag: '⛵',
    isAvailable: true,
    script: 'Phoenician',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Phoenician',
    isFullCourse: false,
  ),

  // 45. Moabite
  LanguageInfo(
    code: 'obm',
    name: 'Moabite',
    nativeName: '𐤌𐤀𐤁𐤉',
    flag: '🐏',
    isAvailable: true,
    script: 'Phoenician',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Phoenician',
    isFullCourse: false,
  ),

  // 46. Punic (Carthaginian)
  LanguageInfo(
    code: 'xpu',
    name: 'Punic (Carthaginian)',
    nativeName: '𐤊𐤍𐤏𐤍𐤉',
    flag: '⚓',
    isAvailable: true,
    script: 'Phoenician',
    textDirection: TextDirection.rtl,
    primaryFont: 'Noto Sans Phoenician',
    isFullCourse: false,
  ),
];
