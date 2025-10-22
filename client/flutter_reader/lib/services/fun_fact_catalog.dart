class FunFactCatalog {
  const FunFactCatalog._();

  static List<Map<String, String>> factsForLanguage(String languageCode) {
    switch (languageCode) {
      case 'grc': // Classical Greek
        return [
          {
            'category': 'Philology',
            'fact':
                'Classical Greek inscriptions often write words with no spaces or punctuation—a style called scriptio continua.'
          },
          {
            'category': 'Culture',
            'fact':
                'Athenians staged dramatic festivals where entire neighborhoods would shut down to watch plays honoring Dionysus.'
          },
          {
            'category': 'Linguistics',
            'fact':
                'The Homeric dialect blends Ionic and Aeolic Greek, preserving older verb forms that disappeared elsewhere.'
          },
          {
            'category': 'History',
            'fact':
                'The Library of Alexandria reputedly housed Greek works on mathematics, medicine, astronomy, and even stagecraft.'
          },
        ];
      case 'lat': // Classical Latin
        return [
          {
            'category': 'Epigraphy',
            'fact':
                'Roman inscriptions frequently carve V where we expect U—CLASSICVS rather than CLASSICUS.'
          },
          {
            'category': 'Culture',
            'fact':
                'Elite Romans often employed Greek tutors, so families could speak Latin in public and Greek at home.'
          },
          {
            'category': 'Literature',
            'fact':
                'Virgil spent nearly a decade refining the Aeneid—after his death, Augustus overruled Virgil’s request to burn the manuscript.'
          },
          {
            'category': 'Linguistics',
            'fact':
                'Cicero helped popularize the Roman lowercase alphabet through his personal correspondence.'
          },
        ];
      case 'hbo': // Biblical Hebrew
        return [
          {
            'category': 'Scripts',
            'fact':
                'Early Biblical Hebrew texts used the Paleo-Hebrew script, closely related to Phoenician characters.'
          },
          {
            'category': 'Manuscripts',
            'fact':
                'The Dead Sea Scrolls preserve Hebrew writings a millennium older than the previously known Masoretic manuscripts.'
          },
          {
            'category': 'Culture',
            'fact':
                'Many psalms originated as temple lyrics—psalm headings like “לַמְנַצֵּחַ” (lamnasseach) direct the choir leader.'
          },
          {
            'category': 'Linguistics',
            'fact':
                'Biblical Hebrew verbs encode both aspect and person—perfect forms describe completed actions, while imperfect forms indicate ongoing or future ones.'
          },
        ];
      case 'san': // Classical Sanskrit
        return [
          {
            'category': 'Grammar',
            'fact':
                'Panini’s 4th-century BCE grammar, the Aṣṭādhyāyī, compresses the entire language into about 4,000 sutras.'
          },
          {
            'category': 'Poetry',
            'fact':
                'Classical Sanskrit poetry revels in elaborate meter; the śloka consists of two 16-syllable lines with internal caesura.'
          },
          {
            'category': 'Philosophy',
            'fact':
                'The Upaniṣads introduce the Sanskrit word “ātman,” which later influenced philosophical vocabulary across Asia.'
          },
          {
            'category': 'Scripts',
            'fact':
                'Although Sanskrit appears in Devanagari today, ancient manuscripts also used Brahmi, Sharada, Grantha, and even Tibet\u2019s Ranjana script.'
          },
        ];
      case 'lzh': // Classical Chinese
        return [
          {
            'category': 'Script',
            'fact':
                'Seal script (篆書) inscriptions from the Qin dynasty preserve forms that feel almost pictographic compared to later clerical script.'
          },
          {
            'category': 'Literature',
            'fact':
                'Many Confucian classics survived the infamous book burnings of 213 BCE because scholars memorized entire texts.'
          },
          {
            'category': 'Philosophy',
            'fact':
                'Legalist texts like the Han Feizi advocate for codified law, contrasting with Confucian emphasis on ritual and virtue.'
          },
          {
            'category': 'Calligraphy',
            'fact':
                'Brush style affects tone—thick deliberate strokes communicate solemnity, while swift running script feels conversational.'
          },
        ];
      case 'pli': // Pali
        return [
          {
            'category': 'Religion',
            'fact':
                'The Pali Canon (Tipiṭaka) was first written down in Sri Lanka around 1st century BCE to preserve oral recitation traditions.'
          },
          {
            'category': 'Phonology',
            'fact':
                'Pali retains many Middle Indo-Aryan features, making it a bridge between Vedic Sanskrit and later Prakrits.'
          },
          {
            'category': 'Manuscripts',
            'fact':
                'Many Pali manuscripts are written on palm leaves—scribes lightly inscribed characters, then rubbed ink into the grooves.'
          },
          {
            'category': 'Culture',
            'fact':
                'Pali chanting practices vary by region; Thai recitations emphasize tonal melody, while Burmese styles favor rhythmic cadence.'
          },
        ];
      case 'chu': // Old Church Slavonic
        return [
          {
            'category': 'Alphabet',
            'fact':
                'Glagolitic script predates Cyrillic; its elaborate letterforms were designed by saints Cyril and Methodius for Slavic missions.'
          },
          {
            'category': 'Liturgy',
            'fact':
                'Old Church Slavonic liturgy helped unite Slavic regions, allowing worship in a language closer to the congregation\u2019s speech.'
          },
          {
            'category': 'Manuscripts',
            'fact':
                'The Codex Zographensis, a 10th-century Glagolitic Gospel, preserves some of the earliest Church Slavonic vowel annotations.'
          },
          {
            'category': 'Linguistics',
            'fact':
                'Old Church Slavonic preserves nasal vowels (ѧ, ѫ) that later evolved differently across Slavic languages.'
          },
        ];
      case 'arc': // Imperial Aramaic
        return [
          {
            'category': 'History',
            'fact':
                'Imperial Aramaic once served as the administrative lingua franca from Egypt to Central Asia under the Achaemenid Empire.'
          },
          {
            'category': 'Script',
            'fact':
                'Imperial Aramaic script gave rise to Hebrew square script and, through Nabataean, the Arabic alphabet.'
          },
          {
            'category': 'Culture',
            'fact':
                'Aramaic ostraca (inked pottery shards) reveal everyday transactions like grain loans and military rations.'
          },
          {
            'category': 'Linguistics',
            'fact':
                'Aramaic maintained stable morphology over centuries, making it easier to adapt for local dialects across the Near East.'
          },
        ];
      case 'ara': // Classical Arabic
        return [
          {
            'category': 'Calligraphy',
            'fact':
                'Early Qurʾānic manuscripts often used the angular Kufic style; later scripts like Naskh improved legibility for everyday use.'
          },
          {
            'category': 'Science',
            'fact':
                'Classical Arabic texts preserve Greek astronomy, Indian mathematics, and original innovations like algebraic symbolic notation.'
          },
          {
            'category': 'Poetics',
            'fact':
                'Pre-Islamic qaṣīda poetry follows a strict tripartite structure: nostalgic prelude, journey section, and praise or satire.'
          },
          {
            'category': 'Lexicography',
            'fact':
                'Arab lexicographers arranged dictionaries by root letters, so words sharing the same triliteral root cluster together.'
          },
        ];
      default:
        return [
          {
            'category': 'Linguistics',
            'fact':
                'Ancient languages often rely on context rather than word order, so endings and particles carry most grammatical meaning.'
          },
          {
            'category': 'Manuscripts',
            'fact':
                'Copyists frequently left marginal notes (scholia) that scholars now study to understand ancient interpretations.'
          },
          {
            'category': 'Tools',
            'fact':
                'Scribes used reed pens and metal styluses. The pen angle affects stroke width, influencing the script\u2019s visual rhythm.'
          },
          {
            'category': 'Philology',
            'fact':
                'Comparing multiple manuscripts of the same work helps reconstruct an archetype—each copy preserves unique clues.'
          },
        ];
    }
  }
}
