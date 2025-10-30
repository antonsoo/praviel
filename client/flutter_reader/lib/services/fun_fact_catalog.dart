import '../models/language.dart';

class FunFactCatalog {
  const FunFactCatalog._();

  static List<Map<String, String>> factsForLanguage(String languageCode) {
    switch (languageCode) {
      case 'grc': // Legacy code
      case 'grc-cls': // Classical Greek
        return [
          {
            'category': 'Philology',
            'fact':
                'Classical Greek inscriptions often write words with no spaces or punctuation—a style called scriptio continua.',
          },
          {
            'category': 'Culture',
            'fact':
                'Athenians staged dramatic festivals where entire neighborhoods would shut down to watch plays honoring Dionysus.',
          },
          {
            'category': 'Linguistics',
            'fact':
                'The Homeric dialect blends Ionic and Aeolic Greek, preserving older verb forms that disappeared elsewhere.',
          },
          {
            'category': 'History',
            'fact':
                'The Library of Alexandria reputedly housed Greek works on mathematics, medicine, astronomy, and even stagecraft.',
          },
        ];
      case 'lat': // Classical Latin
        return [
          {
            'category': 'Epigraphy',
            'fact':
                'Roman inscriptions frequently carve V where we expect U—CLASSICVS rather than CLASSICUS.',
          },
          {
            'category': 'Culture',
            'fact':
                'Elite Romans often employed Greek tutors, so families could speak Latin in public and Greek at home.',
          },
          {
            'category': 'Literature',
            'fact':
                'Virgil spent nearly a decade refining the Aeneid—after his death, Augustus overruled Virgil’s request to burn the manuscript.',
          },
          {
            'category': 'Linguistics',
            'fact':
                'Cicero helped popularize the Roman lowercase alphabet through his personal correspondence.',
          },
        ];
      case 'grc-koi': // Koine Greek
        return [
          {
            'category': 'Dialect',
            'fact':
                'Koine Greek blended Attic prestige with Ionic and local dialect features, becoming the lingua franca across the eastern Mediterranean.',
          },
          {
            'category': 'Manuscripts',
            'fact':
                'Early Christian scribes used nomina sacra—contracted sacred names like ΘΣ for Θεός—marked with a horizontal bar.',
          },
          {
            'category': 'Translation',
            'fact':
                'Septuagint translators often rendered Hebrew idioms word-for-word, preserving Semitic turns of phrase inside Greek sentences.',
          },
          {
            'category': 'Daily Life',
            'fact':
                'Thousands of Koine papyri from Egypt record rent disputes, shipping receipts, and family letters in everyday language.',
          },
        ];
      case 'hbo': // Biblical Hebrew
        return [
          {
            'category': 'Scripts',
            'fact':
                'Early Biblical Hebrew texts used the Paleo-Hebrew script, closely related to Phoenician characters.',
          },
          {
            'category': 'Manuscripts',
            'fact':
                'The Dead Sea Scrolls preserve Hebrew writings a millennium older than the previously known Masoretic manuscripts.',
          },
          {
            'category': 'Culture',
            'fact':
                'Many psalms originated as temple lyrics—psalm headings like “לַמְנַצֵּחַ” (lamnasseach) direct the choir leader.',
          },
          {
            'category': 'Linguistics',
            'fact':
                'Biblical Hebrew verbs encode both aspect and person—perfect forms describe completed actions, while imperfect forms indicate ongoing or future ones.',
          },
        ];
      case 'san': // Classical Sanskrit
        return [
          {
            'category': 'Grammar',
            'fact':
                'Panini’s 4th-century BCE grammar, the Aṣṭādhyāyī, compresses the entire language into about 4,000 sutras.',
          },
          {
            'category': 'Poetry',
            'fact':
                'Classical Sanskrit poetry revels in elaborate meter; the śloka consists of two 16-syllable lines with internal caesura.',
          },
          {
            'category': 'Philosophy',
            'fact':
                'The Upaniṣads introduce the Sanskrit word “ātman,” which later influenced philosophical vocabulary across Asia.',
          },
          {
            'category': 'Scripts',
            'fact':
                'Although Sanskrit appears in Devanagari today, ancient manuscripts also used Brahmi, Sharada, Grantha, and even Tibet\u2019s Ranjana script.',
          },
        ];
      case 'lzh': // Classical Chinese
        return [
          {
            'category': 'Script',
            'fact':
                'Seal script (篆書) inscriptions from the Qin dynasty preserve forms that feel almost pictographic compared to later clerical script.',
          },
          {
            'category': 'Literature',
            'fact':
                'Many Confucian classics survived the infamous book burnings of 213 BCE because scholars memorized entire texts.',
          },
          {
            'category': 'Philosophy',
            'fact':
                'Legalist texts like the Han Feizi advocate for codified law, contrasting with Confucian emphasis on ritual and virtue.',
          },
          {
            'category': 'Calligraphy',
            'fact':
                'Brush style affects tone—thick deliberate strokes communicate solemnity, while swift running script feels conversational.',
          },
        ];
      case 'pli': // Pali
        return [
          {
            'category': 'Religion',
            'fact':
                'The Pali Canon (Tipiṭaka) was first written down in Sri Lanka around 1st century BCE to preserve oral recitation traditions.',
          },
          {
            'category': 'Phonology',
            'fact':
                'Pali retains many Middle Indo-Aryan features, making it a bridge between Vedic Sanskrit and later Prakrits.',
          },
          {
            'category': 'Manuscripts',
            'fact':
                'Many Pali manuscripts are written on palm leaves—scribes lightly inscribed characters, then rubbed ink into the grooves.',
          },
          {
            'category': 'Culture',
            'fact':
                'Pali chanting practices vary by region; Thai recitations emphasize tonal melody, while Burmese styles favor rhythmic cadence.',
          },
        ];
      case 'chu': // Old Church Slavonic
        return [
          {
            'category': 'Alphabet',
            'fact':
                'Glagolitic script predates Cyrillic; its elaborate letterforms were designed by saints Cyril and Methodius for Slavic missions.',
          },
          {
            'category': 'Liturgy',
            'fact':
                'Old Church Slavonic liturgy helped unite Slavic regions, allowing worship in a language closer to the congregation\u2019s speech.',
          },
          {
            'category': 'Manuscripts',
            'fact':
                'The Codex Zographensis, a 10th-century Glagolitic Gospel, preserves some of the earliest Church Slavonic vowel annotations.',
          },
          {
            'category': 'Linguistics',
            'fact':
                'Old Church Slavonic preserves nasal vowels (ѧ, ѫ) that later evolved differently across Slavic languages.',
          },
        ];
      case 'arc': // Imperial Aramaic
        return [
          {
            'category': 'History',
            'fact':
                'Imperial Aramaic once served as the administrative lingua franca from Egypt to Central Asia under the Achaemenid Empire.',
          },
          {
            'category': 'Script',
            'fact':
                'Imperial Aramaic script gave rise to Hebrew square script and, through Nabataean, the Arabic alphabet.',
          },
          {
            'category': 'Culture',
            'fact':
                'Aramaic ostraca (inked pottery shards) reveal everyday transactions like grain loans and military rations.',
          },
          {
            'category': 'Linguistics',
            'fact':
                'Aramaic maintained stable morphology over centuries, making it easier to adapt for local dialects across the Near East.',
          },
        ];
      case 'ara': // Classical Arabic
        return [
          {
            'category': 'Calligraphy',
            'fact':
                'Early Qurʾānic manuscripts often used the angular Kufic style; later scripts like Naskh improved legibility for everyday use.',
          },
          {
            'category': 'Science',
            'fact':
                'Classical Arabic texts preserve Greek astronomy, Indian mathematics, and original innovations like algebraic symbolic notation.',
          },
          {
            'category': 'Poetics',
            'fact':
                'Pre-Islamic qaṣīda poetry follows a strict tripartite structure: nostalgic prelude, journey section, and praise or satire.',
          },
          {
            'category': 'Lexicography',
            'fact':
                'Arab lexicographers arranged dictionaries by root letters, so words sharing the same triliteral root cluster together.',
          },
        ];
      default:
        return _fallbackFacts(languageCode);
    }
  }

  static List<Map<String, String>> _fallbackFacts(String languageCode) {
    final languageInfo = availableLanguages.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => const LanguageInfo(
        code: 'default',
        name: 'this language',
        nativeName: '—',
        flag: '📜',
        isAvailable: false,
      ),
    );

    final scriptDescription = languageInfo.script ?? 'its historic script';
    final courseLabel = languageInfo.isFullCourse ? 'full course' : 'early access deck';
    final roadmapNote = languageInfo.comingSoon
        ? 'You are previewing upcoming lessons—send feedback via the bug button to help us calibrate difficulty before launch.'
        : 'We refresh readings every Friday so streaks include fresh passages, not just recycled drills.';

    return [
      {
        'category': 'Course',
        'fact':
            '${languageInfo.name} runs as a $courseLabel inside PRAVIEL. Toggle demo mode in Settings → Providers to jump in without entering API keys.',
      },
      {
        'category': 'Script',
        'fact':
            '${languageInfo.nativeName} appears in $scriptDescription. Script Settings let you swap fonts or enable tutoring notes that explain uncommon glyphs.',
      },
      {
        'category': 'Practice',
        'fact':
            'Daily challenges mix ${languageInfo.name} passages with adaptive review. Earn streak shields to protect longer study gaps.',
      },
      {
        'category': 'Roadmap',
        'fact': roadmapNote,
      },
    ];
  }
}
