/// Service providing default texts for each language in the Reader
class DefaultTextsService {
  /// Get default text for a given language code
  static String getDefaultText(String languageCode) {
    return _defaultTexts[languageCode] ?? _defaultTexts['grc-cls']!;
  }

  /// Get description of the default text
  static String getTextDescription(String languageCode) {
    return _textDescriptions[languageCode] ?? _textDescriptions['grc-cls']!;
  }

  static final Map<String, String> _defaultTexts = {
    // Classical Greek
    'grc-cls': 'Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος',

    // Koine Greek
    'grc-koi': 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν',

    // Classical Latin
    'lat': 'Arma virumque cano, Troiae qui primus ab oris',

    // Biblical Hebrew
    'hbo': 'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ',

    // Sanskrit
    'san': 'धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः',

    // Classical Arabic
    'ara-cls': 'قِفَا نَبْكِ مِنْ ذِكْرَىٰ حَبِيبٍ وَمَنْزِلِ',

    // Old Persian (Behistun Inscription)
    'peo': 'adam Dārayavauš xšāyaθiya vazraka xšāyaθiya xšāyaθiyānām',

    // Ancient Egyptian (Middle Egyptian - Book of the Dead)
    'egy': 'ỉr n⸗f stp-zȝ m pr-ḥḏ',

    // Akkadian
    'akk': 'šarru dannu šarru šarrāni šar māt Aššur',

    // Sumerian
    'sux': 'lugal-e ud re-a',

    // Old Church Slavonic
    'chu': 'искони бѣ слово и слово бѣ отъ бога',

    // Gothic
    'got': 'In anastodeina was waurd jah þata waurd was at guda',

    // Old Norse
    'non': 'Hljóðs bið ek allar helgar kindir',

    // Old English
    'ang': 'Hwæt! Wē Gār-Dena in geār-dagum',

    // Middle English
    'enm': 'Whan that Aprill with his shoures soote',

    // Old Irish
    'sga': 'In principio erat Verbum',

    // Old High German
    'goh': 'Ik gihorta ðat seggen',

    // Middle High German
    'gmh': 'Uns ist in alten mæren wunders vil geseit',

    // Vedic Sanskrit
    'san-ved': 'अग्निमीळे पुरोहितं यज्ञस्य देवमृत्विजम्',

    // Classical Chinese
    'lzh': '道可道，非常道。名可名，非常名',

    // Literary Chinese
    'ltc': '天下皆知美之為美，斯惡已',

    // Old Japanese (Man'yōshū)
    'ojp': 'やまとは くにのまほろば',

    // Classical Japanese
    'lzh-jp': '祗園精舎の鐘の声',

    // Classical Tibetan
    'xct': 'རྒྱལ་བ་རིགས་ལྔའི་ཞིང་ཁམས',

    // Old Javanese
    'kaw': 'Om awighnam astu namo siddhyam',

    // Literary Malay
    'zlm': 'Bismillah ar-rahman ar-rahim',

    // Classical Nahuatl
    'nci': 'Nican mopohua',

    // Classical Syriac
    'syc': 'ܒܪܫܝܬ ܐܝܬܘܗܝ ܗܘܐ ܡܠܬܐ',

    // Coptic
    'cop': 'ϩⲛ ⲟⲩⲁⲣⲭⲏ ⲛⲉ ⲡϣⲁϫⲉ ϣⲟⲟⲡ',

    // Classical Armenian
    'xcl': 'Ի սկզբանէ էր Բանն',

    // Old Georgian
    'oge': 'დასაბამსა შინა იყო სიტყუა',

    // Classical Ethiopic (Ge'ez)
    'gez': 'በመጀመሪያ ቃሉ ነበረ',

    // Avestan
    'ave': 'ahya yasa nemanghā ustānazastō',

    // Pali
    'pli': 'evaṃ me sutaṃ',

    // Prakrit
    'pra': 'dhammam saranam gacchami',

    // Old Babylonian
    'akk-oldbab': 'šumma awilum',

    // Hittite
    'hit': 'nu-mu LUGAL-uš',

    // Ugaritic
    'uga': 'ṯr il abh',

    // Phoenician
    'phn': 'אנכ חרם מלכ צדנם',

    // Linear B (Mycenaean Greek)
    'gmy': 'ti-ri-po-de ai-ke-u',

    // Hieroglyphic Egyptian
    'egy-hiero': 'ḏd mdw',

    // Middle Welsh
    'wlm': 'yn y dechreuad yr oedd y gair',

    // Old Provençal
    'pro': 'Ab la dolchor del temps novel',

    // Old French
    'fro': 'Carles li reis, nostre emperere magnes',

    // Old Spanish
    'osp': 'En un lugar de la Mancha',

    // Old Portuguese
    'roa-opt': 'No começo era o Verbo',

    // Old Italian
    'roa-oit': 'Nel mezzo del cammin di nostra vita',
  };

  static final Map<String, String> _textDescriptions = {
    'grc-cls': 'Homer, Iliad 1.1 - "Sing, goddess, the wrath of Achilles"',
    'grc-koi': 'Gospel of John 1:1 - "In the beginning was the Word"',
    'lat': 'Virgil, Aeneid 1.1 - "I sing of arms and the man"',
    'hbo': 'Genesis 1:1 - "In the beginning God created heaven and earth"',
    'san': 'Bhagavad Gita 1.1 - Opening verse at Kurukshetra',
    'ara-cls': 'Imru\' al-Qais, Mu\'allaqat - Pre-Islamic poetry',
    'peo': 'Behistun Inscription - "I am Darius, the great king"',
    'egy': 'Book of the Dead - Ancient Egyptian funerary text',
    'akk': 'Royal inscription - "Mighty king, king of kings"',
    'sux': 'Sumerian royal hymn',
    'chu': 'Old Church Slavonic Gospel of John 1:1',
    'got': 'Gothic Bible - Gospel of John 1:1',
    'non': 'Völuspá - Norse creation poem',
    'ang': 'Beowulf opening - Old English epic',
    'enm': 'Chaucer, Canterbury Tales - Middle English',
    'sga': 'Old Irish Gospel',
    'goh': 'Hildebrandslied - Old High German',
    'gmh': 'Nibelungenlied - Middle High German epic',
    'san-ved': 'Rigveda 1.1.1 - Ancient Vedic hymn to Agni',
    'lzh': 'Dao De Jing 1 - Laozi',
    'ltc': 'Dao De Jing 2 - Laozi',
    'ojp': 'Man\'yōshū - Ancient Japanese poetry',
    'lzh-jp': 'Heike Monogatari opening',
    'xct': 'Classical Tibetan Buddhist text',
    'kaw': 'Old Javanese sacred text',
    'zlm': 'Classical Malay opening formula',
    'nci': 'Nican Mopohua - Nahuatl sacred text',
    'syc': 'Syriac Gospel of John 1:1',
    'cop': 'Coptic Gospel of John 1:1',
    'xcl': 'Classical Armenian Gospel of John 1:1',
    'oge': 'Old Georgian Gospel of John 1:1',
    'gez': 'Ge\'ez Gospel of John 1:1',
    'ave': 'Avestan Yasna - Zoroastrian hymn',
    'pli': 'Pali Buddhist Canon opening',
    'pra': 'Prakrit Buddhist text',
    'akk-oldbab': 'Code of Hammurabi opening',
    'hit': 'Hittite royal text',
    'uga': 'Ugaritic Baal Cycle',
    'phn': 'Phoenician royal inscription',
    'gmy': 'Linear B tablet - Mycenaean Greek',
    'egy-hiero': 'Egyptian hieroglyphic formula',
    'wlm': 'Middle Welsh Gospel',
    'pro': 'Troubadour poetry',
    'fro': 'Chanson de Roland - Old French epic',
    'osp': 'El Cantar de Mio Cid',
    'roa-opt': 'Old Portuguese Gospel',
    'roa-oit': 'Dante, Divine Comedy opening',
  };
}
