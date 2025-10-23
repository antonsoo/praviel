/// Historical and cultural information about ancient languages.
///
/// Provides context, fun facts, and famous quotes for each supported language.
library;

class LanguageQuote {
  const LanguageQuote({
    required this.text,
    required this.translation,
    required this.source,
  });

  final String text;
  final String translation;
  final String source;
}

class LanguageDescription {
  const LanguageDescription({
    required this.languageCode,
    required this.whenSpoken,
    required this.whereSpoken,
    required this.whyImportant,
    required this.funFacts,
    required this.famousQuotes,
    required this.notableWorks,
  });

  final String languageCode;
  final String whenSpoken;
  final String whereSpoken;
  final String whyImportant;
  final List<String> funFacts;
  final List<LanguageQuote> famousQuotes;
  final List<String> notableWorks;
}

const Map<String, LanguageDescription> languageDescriptions = {
  'lat': LanguageDescription(
    languageCode: 'lat',
    whenSpoken: '75 BCE – 3rd century CE',
    whereSpoken: 'Roman Empire, Mediterranean basin',
    whyImportant:
        'Foundation of Romance languages. Used in law, medicine, and academia for centuries. Lingua franca of Western civilization.',
    funFacts: [
      'Latin has no word for "yes" – Romans said "it is so" (ita vero)',
      'The Romans wrote without spaces between words (scriptio continua)',
      'Latin V was pronounced like English W – "veni vidi vici" sounded like "weni widi wici"',
      'Over 60% of English words derive from Latin roots',
    ],
    famousQuotes: [
      LanguageQuote(
        text: 'VENI VIDI VICI',
        translation: 'I came, I saw, I conquered',
        source: 'Julius Caesar, 47 BCE',
      ),
      LanguageQuote(
        text: 'CARPE DIEM',
        translation: 'Seize the day',
        source: 'Horace, Odes I.11',
      ),
      LanguageQuote(
        text: 'AMOR VINCIT OMNIA',
        translation: 'Love conquers all',
        source: 'Virgil, Eclogues X.69',
      ),
    ],
    notableWorks: [
      'Aeneid (Virgil)',
      'Commentarii de Bello Gallico (Caesar)',
      'Metamorphoses (Ovid)',
      'De Rerum Natura (Lucretius)',
    ],
  ),
  'grc-cls': LanguageDescription(
    languageCode: 'grc-cls',
    whenSpoken: '5th–4th century BCE',
    whereSpoken: 'Athens, Greek city-states',
    whyImportant:
        'Language of Western philosophy, democracy, and drama. Foundation of scientific and mathematical terminology.',
    funFacts: [
      'Greek has 3 genders: masculine, feminine, and neuter',
      'The Greek question mark (;) looks like an English semicolon',
      'Ancient Greek had pitch accent, not stress accent like Modern Greek',
      'The letter "upsilon" (Υ) changed pronunciation: originally "oo", later "ü"',
    ],
    famousQuotes: [
      LanguageQuote(
        text: 'ΓΝΩΘΙ ΣΑΥΤΟΝ',
        translation: 'Know thyself',
        source: 'Inscribed at Delphi',
      ),
      LanguageQuote(
        text: 'ΕΝ ΑΡΧΗ ΗΝ Ο ΛΟΓΟΣ',
        translation: 'In the beginning was the Word',
        source: 'Gospel of John 1:1',
      ),
      LanguageQuote(
        text: 'ΜΗΔΕΝ ΑΓΑΝ',
        translation: 'Nothing in excess',
        source: 'Delphic maxim',
      ),
    ],
    notableWorks: [
      'Iliad & Odyssey (Homer)',
      'Oedipus Rex (Sophocles)',
      'Republic (Plato)',
      'Histories (Herodotus)',
    ],
  ),
  'grc-koi': LanguageDescription(
    languageCode: 'grc-koi',
    whenSpoken: '3rd century BCE – 6th century CE',
    whereSpoken: 'Eastern Mediterranean, Hellenistic world',
    whyImportant:
        'Language of the New Testament and Septuagint. Lingua franca of the ancient Mediterranean world.',
    funFacts: [
      'Koine means "common" – it was the everyday Greek of the masses',
      'Simplified grammar compared to Classical Greek (dual number dropped)',
      'New Testament Greek is "Jewish Koine" with Hebrew/Aramaic influence',
      'Koine spelling was often phonetic, causing variations in manuscripts',
    ],
    famousQuotes: [
      LanguageQuote(
        text: 'ΚΑΙ Ο ΛΟΓΟΣ ΣΑΡΞ ΕΓΕΝΕΤΟ',
        translation: 'And the Word became flesh',
        source: 'John 1:14',
      ),
      LanguageQuote(
        text: 'ΕΝ ΑΡΧΗ ΕΠΟΙΗΣΕΝ Ο ΘΕΟΣ',
        translation: 'In the beginning, God created',
        source: 'Septuagint, Genesis 1:1',
      ),
      LanguageQuote(
        text: 'ΑΓΑΠΗ ΜΑΚΡΟΘΥΜΕΙ',
        translation: 'Love is patient',
        source: '1 Corinthians 13:4',
      ),
    ],
    notableWorks: [
      'New Testament (various authors)',
      'Septuagint (Greek Old Testament)',
      'Polybius Histories',
      'Josephus Jewish Antiquities',
    ],
  ),
  'hbo': LanguageDescription(
    languageCode: 'hbo',
    whenSpoken: '10th–2nd century BCE',
    whereSpoken: 'Ancient Israel and Judah',
    whyImportant:
        'Language of the Hebrew Bible/Old Testament. Sacred language of Judaism. Ancestor of Modern Hebrew.',
    funFacts: [
      'Hebrew is written right-to-left, but numbers are written left-to-right!',
      'Ancient Hebrew had no vowels – vowel points were added 600-900 CE',
      'The letter "shin" (ש) has two pronunciations based on a dot position',
      'Hebrew word roots are typically 3 consonants (shoresh)',
    ],
    famousQuotes: [
      LanguageQuote(
        text: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים',
        translation: 'In the beginning, God created',
        source: 'Genesis 1:1',
      ),
      LanguageQuote(
        text: 'שְׁמַע יִשְׂרָאֵל',
        translation: 'Hear, O Israel',
        source: 'Deuteronomy 6:4',
      ),
      LanguageQuote(
        text: 'וְאָהַבְתָּ לְרֵעֲךָ כָּמוֹךָ',
        translation: 'Love your neighbor as yourself',
        source: 'Leviticus 19:18',
      ),
    ],
    notableWorks: [
      'Torah (Five Books of Moses)',
      'Book of Psalms',
      'Book of Isaiah',
      'Song of Songs',
    ],
  ),
  'san': LanguageDescription(
    languageCode: 'san',
    whenSpoken: '1500 BCE – 600 CE',
    whereSpoken: 'Indian subcontinent',
    whyImportant:
        'Sacred language of Hinduism, Buddhism, and Jainism. One of the oldest Indo-European languages. Scientific and philosophical powerhouse.',
    funFacts: [
      'Sanskrit has 48 phonemes – more than almost any other language',
      'The word "Sanskrit" means "perfected" or "refined"',
      'Sanskrit grammar was codified by Panini around 500 BCE',
      'NASA researched Sanskrit for AI due to its unambiguous grammar',
    ],
    famousQuotes: [
      LanguageQuote(
        text: 'अहिंसा परमो धर्मः',
        translation: 'Non-violence is the highest dharma',
        source: 'Mahabharata',
      ),
      LanguageQuote(
        text: 'सत्यमेव जयते',
        translation: 'Truth alone triumphs',
        source: 'Mundaka Upanishad',
      ),
      LanguageQuote(
        text: 'तत्त्वमसि',
        translation: 'You are that',
        source: 'Chandogya Upanishad',
      ),
    ],
    notableWorks: [
      'Rigveda (oldest Vedic text)',
      'Bhagavad Gita',
      'Mahabharata',
      'Ramayana',
    ],
  ),
};
