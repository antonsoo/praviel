import 'package:flutter/material.dart';

/// Language selection widget showing available and upcoming languages
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.currentLanguage = 'grc',
    this.onLanguageSelected,
  });

  final String currentLanguage;
  final void Function(String languageCode)? onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Learning Language',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 1. Classical Greek
        _LanguageCard(
          languageCode: 'grc',
          languageName: 'Classical Greek',
          languageNative: 'Ἑλληνική',
          icon: '🏺',
          isAvailable: true,
          isSelected: currentLanguage == 'grc',
          keyTexts: 'Iliad (Homer), Odyssey (Homer), Theogony (Hesiod), Works and Days (Hesiod), Oedipus Rex (Sophocles)',
          onTap: () => onLanguageSelected?.call('grc'),
        ),
        // 2. Classical Latin
        _LanguageCard(
          languageCode: 'lat',
          languageName: 'Classical Latin',
          languageNative: 'Lingua Latīna',
          icon: '🏛️',
          isAvailable: false,
          status: 'In Development',
          keyTexts: 'Aeneid (Virgil), Metamorphoses (Ovid), De Rerum Natura (Lucretius), Commentaries on the Gallic War (Caesar), Annals (Tacitus)',
          onTap: null,
        ),
        // 3. Old Egyptian
        _LanguageCard(
          languageCode: 'egy-old',
          languageName: 'Old Egyptian',
          languageNative: 'r n km.t',
          icon: '🔺',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Pyramid Texts, Instruction of Ptahhotep, Autobiography of Weni, Palermo Stone, Autobiography of Harkhuf',
          onTap: null,
        ),
        // 4. Vedic Sanskrit
        _LanguageCard(
          languageCode: 'san-vedic',
          languageName: 'Vedic Sanskrit',
          languageNative: 'वैदिकसंस्कृतम्',
          icon: '🕉️',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Ṛgveda, Sāmaveda, Yajurveda, Atharvaveda, Śatapatha Brāhmaṇa',
          onTap: null,
        ),
        // 5. Koine Greek
        _LanguageCard(
          languageCode: 'grc-koine',
          languageName: 'Koine Greek',
          languageNative: 'Κοινὴ Ἑλληνική',
          icon: '📖',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Septuagint (LXX), New Testament, Jewish War (Josephus), Parallel Lives (Plutarch), Discourses (Epictetus)',
          onTap: null,
        ),
        // 6. Ancient Sumerian
        _LanguageCard(
          languageCode: 'sux',
          languageName: 'Ancient Sumerian',
          languageNative: '𒅴𒂠',
          icon: '🧱',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Code of Ur-Nammu, Sumerian King List, Inanna\'s Descent, Instructions of Shuruppak, Lamentation over Ur',
          onTap: null,
        ),
        // 7. Proto-Hebrew
        _LanguageCard(
          languageCode: 'hbo-proto',
          languageName: 'Proto-Hebrew',
          languageNative: '𐤏𐤁𐤓𐤉𐤕',
          icon: '🫒',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Gezer Calendar, Siloam Inscription, Mesha Stele, Lachish Letters, Ketef Hinnom Amulets',
          onTap: null,
        ),
        // 8. Old Church Slavonic
        _LanguageCard(
          languageCode: 'chu',
          languageName: 'Old Church Slavonic',
          languageNative: 'Словѣньскъ',
          icon: '☦️',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Codex Zographensis, Ostromir Gospel, Sinai Psalter, Proglas, Lives of Cyril and Methodius',
          onTap: null,
        ),
        // 9. Akkadian
        _LanguageCard(
          languageCode: 'akk',
          languageName: 'Akkadian',
          languageNative: 'Akkadû',
          icon: '🦁',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Epic of Gilgamesh, Enūma Eliš, Code of Hammurabi, Atrahasis, Descent of Ishtar',
          onTap: null,
        ),
        // 10. Hittite
        _LanguageCard(
          languageCode: 'hit',
          languageName: 'Hittite',
          languageNative: 'nešili',
          icon: '🗡️',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Anitta Text, Edict of Telepinu, Myth of Illuyanka, Treaty of Kadesh, Plague Prayers of Mursili II',
          onTap: null,
        ),
        // 11. Avestan
        _LanguageCard(
          languageCode: 'ave',
          languageName: 'Avestan',
          languageNative: 'avesta',
          icon: '🔥',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Yasna (incl. Gāthās), Gāthās of Zarathustra, Vendidad, Yašts, Visperad',
          onTap: null,
        ),
        // 12. Ancient Aramaic
        _LanguageCard(
          languageCode: 'arc',
          languageName: 'Ancient Aramaic',
          languageNative: 'ארמיא',
          icon: '🗣️',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Wisdom of Ahiqar, Targum Onkelos, Genesis Apocryphon, Daniel (Aramaic), Ezra (Aramaic)',
          onTap: null,
        ),
        // 13. Old Persian
        _LanguageCard(
          languageCode: 'peo',
          languageName: 'Old Persian',
          languageNative: 'pārsa',
          icon: '🏹',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Behistun Inscription, Naqsh-e Rostam DNa, Xerxes XPh, Suez Canal Stelae, Xerxes Harem Inscription',
          onTap: null,
        ),
        // 14. Classical Nahuatl
        _LanguageCard(
          languageCode: 'nci',
          languageName: 'Classical Nahuatl',
          languageNative: 'Nāhuatlahtōlli',
          icon: '🐆',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Florentine Codex, Huehuetlahtolli, Anales de Cuauhtitlan, Cantares Mexicanos, Doctrina Christiana (1543)',
          onTap: null,
        ),
        // 15. Classical Quechua
        _LanguageCard(
          languageCode: 'qwc',
          languageName: 'Classical Quechua',
          languageNative: 'Qhichwa simi',
          icon: '🦙',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Huarochirí Manuscript, Ollantay, Doctrina Christiana (1584), Arte y Vocabulario (1560), Quechua Villancicos',
          onTap: null,
        ),
        // 16. Classical Mayan
        _LanguageCard(
          languageCode: 'myn',
          languageName: 'Classical Mayan',
          languageNative: "Maya' t'aan",
          icon: '🌽',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Popol Vuh (K\'iche\'), Chilam Balam, Rabinal Achí, Dresden Codex, Annals of the Cakchiquels',
          onTap: null,
        ),
        // 17. Biblical Hebrew
        _LanguageCard(
          languageCode: 'hbo',
          languageName: 'Biblical Hebrew',
          languageNative: 'עִבְרִית מִקְרָאִית',
          icon: '🕎',
          isAvailable: false,
          status: 'Later',
          keyTexts: 'Genesis (Bereshit), Exodus (Shemot), Isaiah (Yeshayahu), Psalms (Tehillim), Deuteronomy (Devarim)',
          onTap: null,
        ),
        // 18. Classical/Middle Egyptian
        _LanguageCard(
          languageCode: 'egy',
          languageName: 'Classical Egyptian',
          languageNative: 'r n km.t',
          icon: '👁️',
          isAvailable: false,
          status: 'Later',
          keyTexts: 'Story of Sinuhe, Coffin Texts, Tale of the Shipwrecked Sailor, Instruction of King Merikare, Instruction of Amenemope',
          onTap: null,
        ),
        // 19. Classical Sanskrit
        _LanguageCard(
          languageCode: 'san',
          languageName: 'Classical Sanskrit',
          languageNative: 'संस्कृतम्',
          icon: '🪷',
          isAvailable: false,
          status: 'Later',
          keyTexts: 'Mahābhārata (incl. Bhagavad-Gītā), Rāmāyaṇa, Aṣṭādhyāyī (Pāṇini), Arthaśāstra (Kauṭilya), Abhijñānaśākuntalam (Kālidāsa)',
          onTap: null,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Want another language? Submit a feature request on GitHub!',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.languageCode,
    required this.languageName,
    required this.languageNative,
    required this.icon,
    required this.isAvailable,
    this.isSelected = false,
    this.status,
    this.keyTexts,
    this.onTap,
  });

  final String languageCode;
  final String languageName;
  final String languageNative;
  final String icon;
  final bool isAvailable;
  final bool isSelected;
  final String? status;
  final String? keyTexts;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          languageName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isAvailable
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isAvailable && status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'In Development'
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: status == 'In Development'
                                    ? Colors.orange[700]
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageNative,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (keyTexts != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        keyTexts!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow or lock icon
              if (isAvailable)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                )
              else
                Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
