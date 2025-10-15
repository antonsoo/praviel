class LanguageInfo {
  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isAvailable,
    this.comingSoon = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isAvailable;
  final bool comingSoon;
}

const availableLanguages = [
  // 1. Classical Greek - Available now
  LanguageInfo(
    code: 'grc',
    name: 'Classical Greek',
    nativeName: 'ἙΛΛΗΝΙΚΉ',  // Classical Greek was written in all capitals
    flag: '🏺',
    isAvailable: true,
  ),
  // 2. Classical Latin - Available now
  LanguageInfo(
    code: 'lat',
    name: 'Classical Latin',
    nativeName: 'LINGVA LATINA',  // Classical Latin used all caps
    flag: '🏛️',
    isAvailable: true,
  ),
  // 3. Old Egyptian - Planned
  LanguageInfo(
    code: 'egy-old',
    name: 'Old Egyptian',
    nativeName: '𓂋𓈖𓆎𓅓𓏏𓊖',  // r n kmt in hieroglyphics
    flag: '🔺',
    isAvailable: false,
    comingSoon: true,
  ),
  // 4. Vedic Sanskrit - Planned
  LanguageInfo(
    code: 'san-vedic',
    name: 'Vedic Sanskrit',
    nativeName: 'वैदिकसंस्कृतम्',
    flag: '🕉️',
    isAvailable: false,
    comingSoon: true,
  ),
  // 5. Koine Greek - Planned
  LanguageInfo(
    code: 'grc-koine',
    name: 'Koine Greek',
    nativeName: 'ΚΟΙΝΗ ΕΛΛΗΝΙΚΗ',  // Koine era still primarily used capitals
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
  // 7. Proto-Hebrew - Planned
  LanguageInfo(
    code: 'hbo-proto',
    name: 'Proto-Hebrew',
    nativeName: '𐤏𐤁𐤓𐤉𐤕',
    flag: '🫒',
    isAvailable: false,
    comingSoon: true,
  ),
  // 8. Old Church Slavonic - Planned
  LanguageInfo(
    code: 'chu',
    name: 'Old Church Slavonic',
    nativeName: 'Словѣньскъ',
    flag: '☦️',
    isAvailable: false,
    comingSoon: true,
  ),
  // 9. Akkadian - Planned
  LanguageInfo(
    code: 'akk',
    name: 'Akkadian',
    nativeName: '𒀝𒅗𒁺𒌑',  // Akkadian in cuneiform (a-ka-du-u)
    flag: '🦁',
    isAvailable: false,
    comingSoon: true,
  ),
  // 10. Hittite - Planned
  LanguageInfo(
    code: 'hit',
    name: 'Hittite',
    nativeName: '𒉌𒅆𒇷',  // Hittite nešili in cuneiform
    flag: '🗡️',
    isAvailable: false,
    comingSoon: true,
  ),
  // 11. Avestan - Planned
  LanguageInfo(
    code: 'ave',
    name: 'Avestan',
    nativeName: '𐬀𐬎𐬎𐬆𐬯𐬙𐬁',  // Avestan script (avesta)
    flag: '🔥',
    isAvailable: false,
    comingSoon: true,
  ),
  // 12. Ancient Aramaic - Planned
  LanguageInfo(
    code: 'arc',
    name: 'Ancient Aramaic',
    nativeName: 'ארמיא',
    flag: '🗣️',
    isAvailable: false,
    comingSoon: true,
  ),
  // 13. Old Persian - Planned
  LanguageInfo(
    code: 'peo',
    name: 'Old Persian',
    nativeName: '𐎱𐎠𐎼𐎿',  // Old Persian cuneiform (pārsa)
    flag: '🏹',
    isAvailable: false,
    comingSoon: true,
  ),
  // 14. Classical Nahuatl - Planned
  LanguageInfo(
    code: 'nci',
    name: 'Classical Nahuatl',
    nativeName: 'Nāhuatlahtōlli',
    flag: '🐆',
    isAvailable: false,
    comingSoon: true,
  ),
  // 15. Classical Quechua - Planned
  LanguageInfo(
    code: 'qwc',
    name: 'Classical Quechua',
    nativeName: 'Qhichwa simi',
    flag: '🦙',
    isAvailable: false,
    comingSoon: true,
  ),
  // 16. Classical Mayan - Planned
  LanguageInfo(
    code: 'myn',
    name: 'Classical Mayan',
    nativeName: "Maya' t'aan",
    flag: '🌽',
    isAvailable: false,
    comingSoon: true,
  ),
  // 17. Biblical Hebrew - Available now (Beta)
  LanguageInfo(
    code: 'hbo',
    name: 'Biblical Hebrew',
    nativeName: 'עִבְרִית מִקְרָאִית',
    flag: '🕎',
    isAvailable: true,
  ),
  // 18. Classical/Middle Egyptian - Later
  LanguageInfo(
    code: 'egy',
    name: 'Classical Egyptian',
    nativeName: '𓂋𓈖𓆎𓅓𓏏𓊖',  // r n kmt in hieroglyphics
    flag: '👁️',
    isAvailable: false,
    comingSoon: false,
  ),
  // 19. Classical Sanskrit - Available now (Beta)
  LanguageInfo(
    code: 'san',
    name: 'Classical Sanskrit',
    nativeName: 'संस्कृतम्',
    flag: '🪷',
    isAvailable: true,
  ),
];
