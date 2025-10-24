#!/usr/bin/env python3
"""Seed Reader catalog with 71 texts across 7 languages.

This script populates the database with text works and sample segments
for the Reader feature. Uses placeholder content based on the fallback catalog.
"""

import asyncio
import logging
import sys
import unicodedata
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.config import settings
from app.db.models import Language, SourceDoc, TextSegment, TextWork

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def normalize_text(text: str) -> tuple[str, str, str]:
    """Normalize text to NFC and create folded version."""
    text_raw = text.strip()
    text_nfc = unicodedata.normalize("NFC", text_raw)
    # Folded: lowercase, remove accents
    text_fold = "".join(
        c for c in unicodedata.normalize("NFD", text_nfc.lower()) if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


# Catalog of 71 texts across 7 languages
# Format: (language_code, author, title, ref_scheme, segments)
READER_CATALOG = [
    # Classical Latin (10 texts)
    (
        "lat",
        "Virgil",
        "Aeneid",
        "book.line",
        [
            "Arma virumque cano, Troiae qui primus ab oris",
            "Italiam, fato profugus, Laviniaque venit",
            "litora, multum ille et terris iactatus et alto",
        ],
    ),
    (
        "lat",
        "Ovid",
        "Metamorphoses",
        "book.line",
        [
            "In nova fert animus mutatas dicere formas",
            "corpora; di, coeptis (nam vos mutastis et illas)",
            "adspirate meis primaque ab origine mundi",
        ],
    ),
    (
        "lat",
        "Lucretius",
        "De Rerum Natura",
        "book.line",
        [
            "Aeneadum genetrix, hominum divomque voluptas,",
            "alma Venus, caeli subter labentia signa",
            "quae mare navigerum, quae terras frugiferentis",
        ],
    ),
    (
        "lat",
        "Julius Caesar",
        "Commentaries on the Gallic War",
        "book.chapter",
        [
            "Gallia est omnis divisa in partes tres,",
            "quarum unam incolunt Belgae, aliam Aquitani,",
            "tertiam qui ipsorum lingua Celtae, nostra Galli appellantur.",
        ],
    ),
    (
        "lat",
        "Tacitus",
        "Annals",
        "book.chapter",
        [
            "Urbem Romam a principio reges habuere;",
            "libertatem et consulatum L. Brutus instituit.",
            "dictaturae ad tempus sumebantur;",
        ],
    ),
    (
        "lat",
        "Livy",
        "Ab Urbe Condita",
        "book.chapter",
        [
            "Facturusne operae pretium sim si a primordio urbis",
            "res populi Romani perscripserim nec satis scio",
            "nec, si sciam, dicere ausim,",
        ],
    ),
    (
        "lat",
        "Horace",
        "Odes",
        "book.poem.line",
        [
            "Maecenas atavis edite regibus,",
            "o et praesidium et dulce decus meum,",
            "sunt quos curriculo pulverem Olympicum",
        ],
    ),
    (
        "lat",
        "Pliny the Elder",
        "Naturalis Historia",
        "book.chapter",
        [
            "Mundum et hoc quodcumque nomine alio caelum appellare",
            "libuit, cuius circumflexu teguntur cuncta,",
            "numen esse credi par est, aeternum, immensum,",
        ],
    ),
    (
        "lat",
        "Juvenal",
        "Satires",
        "satire.line",
        [
            "Semper ego auditor tantum? numquamne reponam",
            "vexatus totiens rauci Theseide Cordi?",
            "impune ergo mihi recitaverit ille togatas,",
        ],
    ),
    (
        "lat",
        "Jerome",
        "Vulgate (Latin Bible)",
        "book.chapter.verse",
        [
            "In principio creavit Deus caelum et terram.",
            "Terra autem erat inanis et vacua, et tenebrae super faciem abyssi,",
            "et spiritus Dei ferebatur super aquas.",
        ],
    ),
    # Koine Greek (10 texts)
    (
        "grc-koi",
        "Various",
        "Septuagint",
        "book.chapter.verse",
        [
            "Ἐν ἀρχῇ ἐποίησεν ὁ θεὸς τὸν οὐρανὸν καὶ τὴν γῆν.",
            "ἡ δὲ γῆ ἦν ἀόρατος καὶ ἀκατασκεύαστος,",
            "καὶ σκότος ἐπάνω τῆς ἀβύσσου,",
        ],
    ),
    (
        "grc-koi",
        "Various",
        "New Testament",
        "book.chapter.verse",
        [
            "Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν,",
            "καὶ θεὸς ἦν ὁ λόγος.",
            "οὗτος ἦν ἐν ἀρχῇ πρὸς τὸν θεόν.",
        ],
    ),
    (
        "grc-koi",
        "Flavius Josephus",
        "Jewish War",
        "book.chapter",
        [
            "Ἐπειδὴ ὁ τῶν Ἰουδαίων πρὸς Ῥωμαίους πόλεμος",
            "μέγιστος ὢν οὐ μόνον τῶν καθ' ἡμᾶς,",
            "σχεδὸν δὲ καὶ ὧν ἀκοῇ παρειλήφαμεν",
        ],
    ),
    (
        "grc-koi",
        "Plutarch",
        "Parallel Lives",
        "life.chapter",
        [
            "Τὸν βίον γράφων ἀλεξάνδρου τοῦ βασιλέως",
            "καὶ καίσαρος ὑφ' οὗ κατελύθη πομπήιος,",
            "διὰ τὸ πλῆθος τῶν ὑποκειμένων πράξεων",
        ],
    ),
    (
        "grc-koi",
        "Epictetus (via Arrian)",
        "Discourses and Enchiridion",
        "book.chapter",
        [
            "Τῶν ὄντων τὰ μέν ἐστιν ἐφ' ἡμῖν, τὰ δὲ οὐκ ἐφ' ἡμῖν.",
            "ἐφ' ἡμῖν μὲν ὑπόληψις, ὁρμή, ὄρεξις, ἔκκλισις",
            "καὶ ἑνὶ λόγῳ ὅσα ἡμέτερα ἔργα·",
        ],
    ),
    (
        "grc-koi",
        "Strabo",
        "Geographica",
        "book.chapter",
        [
            "Ἡ γεωγραφικὴ μέθοδος",
            "πρὸς τὰς πολιτικὰς πράξεις χρήσιμος",
            "καὶ πρὸς τὴν τῶν φιλοσόφων θεωρίαν",
        ],
    ),
    (
        "grc-koi",
        "Ptolemy",
        "Almagest",
        "book.chapter",
        [
            "Οἱ γνησίως φιλοσοφήσαντες,",
            "τὸ μὲν πρακτικὸν τῆς φιλοσοφίας",
            "ἀπὸ τοῦ θεωρητικοῦ διώρισαν",
        ],
    ),
    (
        "grc-koi",
        "(Pseudo-)Longinus",
        "On the Sublime",
        "chapter",
        [
            "Εἰδὼς μέν, φίλτατε Ποστούμιε Τερεντιανέ,",
            "ὅτε τὸ βιβλίδιον ἀνεγινώσκομεν",
            "τὸ Καικιλίου περὶ ὕψους συγγεγραμμένον,",
        ],
    ),
    (
        "grc-koi",
        "Eusebius",
        "Ecclesiastical History",
        "book.chapter",
        [
            "Τὴν τῶν ἱερῶν ἀποστόλων διαδοχήν",
            "σὺν ὅσοις ἀπὸ τοῦ σωτῆρος ἡμῶν",
            "μέχρι τοῦ νῦν χρόνοις ἐκκλησιαστικῶν",
        ],
    ),
    (
        "grc-koi",
        "Arrian",
        "Anabasis of Alexander",
        "book.chapter",
        [
            "Ἀλέξανδρον τὸν Φιλίππου Μακεδόνα",
            "τὰ ἔργα ξυνέγραψα Ἀρριανὸς",
            "ταῦτα ἀληθέστατα ἁπάντων ἐς ἐμὲ ἀναβεβηκέναι νομίζων",
        ],
    ),
    # Classical Greek (10 texts)
    (
        "grc-cls",
        "Homer",
        "Iliad",
        "book.line",
        [
            "μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος",
            "οὐλομένην, ἣ μυρί' Ἀχαιοῖς ἄλγε' ἔθηκε,",
            "πολλὰς δ' ἰφθίμους ψυχὰς Ἄϊδι προΐαψεν",
        ],
    ),
    (
        "grc-cls",
        "Homer",
        "Odyssey",
        "book.line",
        [
            "ἄνδρα μοι ἔννεπε, Μοῦσα, πολύτροπον, ὃς μάλα πολλὰ",
            "πλάγχθη, ἐπεὶ Τροίης ἱερὸν πτολίεθρον ἔπερσε·",
            "πολλῶν δ' ἀνθρώπων ἴδεν ἄστεα καὶ νόον ἔγνω,",
        ],
    ),
    (
        "grc-cls",
        "Hesiod",
        "Theogony",
        "line",
        [
            "Μουσάων Ἑλικωνιάδων ἀρχώμεθ' ἀείδειν,",
            "αἵ θ' Ἑλικῶνος ἔχουσιν ὄρος μέγα τε ζάθεόν τε",
            "καί τε περὶ κρήνην ἰοειδέα πόσσ' ἁπαλοῖσιν",
        ],
    ),
    (
        "grc-cls",
        "Hesiod",
        "Works and Days",
        "line",
        [
            "Μοῦσαι Πιερίηθεν ἀοιδῇσι κλείουσαι,",
            "δεῦτε Δί' ἐννέπετε σφέτερον πατέρ' ὑμνείουσαι·",
            "ὃν τε διὰ βροτοὶ ἄνδρες ὁμῶς ἄφατοί τε φατοί τε",
        ],
    ),
    (
        "grc-cls",
        "Sophocles",
        "Oedipus Rex",
        "line",
        [
            "Ὦ τέκνα, Κάδμου τοῦ πάλαι νέα τροφή,",
            "τίνας ποθ' ἕδρας τάσδε μοι θοάζετε",
            "ἱκτηρίοις κλάδοισιν ἐξεστεμμένοι;",
        ],
    ),
    (
        "grc-cls",
        "Sophocles",
        "Antigone",
        "line",
        [
            "Ὦ κοινὸν αὐτάδελφον Ἰσμήνης κάρα,",
            "ἆρ' οἶσθ' ὅ τι Ζεὺς τῶν ἀπ' Οἰδίπου κακῶν",
            "ὁποῖον οὐχὶ νῷν ἔτι ζώσαιν τελεῖ;",
        ],
    ),
    (
        "grc-cls",
        "Euripides",
        "Medea",
        "line",
        [
            "Εἴθ' ὤφελ' Ἀργοῦς μὴ διαπτάσθαι σκάφος",
            "Κόλχων ἐς αἶαν κυανέας Συμπληγάδας,",
            "μηδ' ἐν νάπαισι Πηλίου πεσεῖν ποτε",
        ],
    ),
    (
        "grc-cls",
        "Herodotus",
        "Histories",
        "book.chapter",
        [
            "Ἡροδότου Ἁλικαρνησσέος ἱστορίης ἀπόδεξις ἥδε,",
            "ὡς μήτε τὰ γενόμενα ἐξ ἀνθρώπων τῷ χρόνῳ ἐξίτηλα γένηται,",
            "μήτε ἔργα μεγάλα τε καὶ θωμαστά,",
        ],
    ),
    (
        "grc-cls",
        "Thucydides",
        "History of the Peloponnesian War",
        "book.chapter",
        [
            "Θουκυδίδης Ἀθηναῖος ξυνέγραψε τὸν πόλεμον",
            "τῶν Πελοποννησίων καὶ Ἀθηναίων,",
            "ὡς ἐπολέμησαν πρὸς ἀλλήλους,",
        ],
    ),
    (
        "grc-cls",
        "Plato",
        "Republic",
        "stephanus",
        [
            "Κατέβην χθὲς εἰς Πειραιᾶ μετὰ Γλαύκωνος",
            "τοῦ Ἀρίστωνος προσευξόμενός τε τῇ θεῷ",
            "καὶ ἅμα τὴν ἑορτὴν βουλόμενος θεάσασθαι",
        ],
    ),
    # Biblical Hebrew (10 texts)
    (
        "hbo",
        "Torah",
        "Genesis (Bereshit)",
        "chapter.verse",
        [
            "בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ",
            "וְהָאָרֶץ הָיְתָה תֹהוּ וָבֹהוּ וְחֹשֶׁךְ עַל־פְּנֵי תְהוֹם",
            "וְרוּחַ אֱלֹהִים מְרַחֶפֶת עַל־פְּנֵי הַמָּיִם",
        ],
    ),
    (
        "hbo",
        "Torah",
        "Exodus (Shemot)",
        "chapter.verse",
        [
            "וְאֵלֶּה שְׁמוֹת בְּנֵי יִשְׂרָאֵל הַבָּאִים מִצְרָיְמָה",
            "אֵת יַעֲקֹב אִישׁ וּבֵיתוֹ בָּאוּ",
            "רְאוּבֵן שִׁמְעוֹן לֵוִי וִיהוּדָה",
        ],
    ),
    (
        "hbo",
        "Neviim",
        "Isaiah (Yeshayahu)",
        "chapter.verse",
        [
            "חֲזוֹן יְשַׁעְיָהוּ בֶן־אָמוֹץ אֲשֶׁר חָזָה עַל־יְהוּדָה וִירוּשָׁלָ‍ִם",
            "בִּימֵי עֻזִּיָּהוּ יוֹתָם אָחָז יְחִזְקִיָּהוּ מַלְכֵי יְהוּדָה",
            "שִׁמְעוּ שָׁמַיִם וְהַאֲזִינִי אֶרֶץ כִּי יְהוָה דִּבֵּר",
        ],
    ),
    (
        "hbo",
        "Ketuvim",
        "Psalms (Tehillim)",
        "psalm.verse",
        [
            "אַשְׁרֵי־הָאִישׁ אֲשֶׁר לֹא הָלַךְ בַּעֲצַת רְשָׁעִים",
            "וּבְדֶרֶךְ חַטָּאִים לֹא עָמָד",
            "וּבְמוֹשַׁב לֵצִים לֹא יָשָׁב",
        ],
    ),
    (
        "hbo",
        "Torah",
        "Deuteronomy (Devarim)",
        "chapter.verse",
        [
            "אֵלֶּה הַדְּבָרִים אֲשֶׁר דִּבֶּר מֹשֶׁה אֶל־כָּל־יִשְׂרָאֵל",
            "בְּעֵבֶר הַיַּרְדֵּן בַּמִּדְבָּר",
            "בָּעֲרָבָה מוֹל סוּף בֵּין־פָּארָן וּבֵין־תֹּפֶל",
        ],
    ),
    (
        "hbo",
        "Neviim",
        "Samuel (Shmuel)",
        "book.chapter.verse",
        [
            "וַיְהִי אִישׁ אֶחָד מִן־הָרָמָתַיִם צוֹפִים מֵהַר אֶפְרָיִם",
            "וּשְׁמוֹ אֶלְקָנָה בֶּן־יְרֹחָם בֶּן־אֱלִיהוּא",
            "בֶּן־תֹּחוּ בֶן־צוּף אֶפְרָתִי",
        ],
    ),
    (
        "hbo",
        "Neviim",
        "Kings (Melakhim)",
        "book.chapter.verse",
        [
            "וְהַמֶּלֶךְ דָּוִד זָקֵן בָּא בַּיָּמִים",
            "וַיְכַסֻּהוּ בַּבְּגָדִים וְלֹא יִחַם לוֹ",
            "וַיֹּאמְרוּ לוֹ עֲבָדָיו יְבַקְשׁוּ לַאדֹנִי הַמֶּלֶךְ נַעֲרָה בְתוּלָה",
        ],
    ),
    (
        "hbo",
        "Neviim",
        "Jeremiah (Yirmeyahu)",
        "chapter.verse",
        [
            "דִּבְרֵי יִרְמְיָהוּ בֶּן־חִלְקִיָּהוּ",
            "מִן־הַכֹּהֲנִים אֲשֶׁר בַּעֲנָתוֹת בְּאֶרֶץ בִּנְיָמִן",
            "אֲשֶׁר הָיָה דְבַר־יְהוָה אֵלָיו בִּימֵי יֹאשִׁיָּהוּ",
        ],
    ),
    (
        "hbo",
        "Neviim",
        "Ezekiel (Yehezkel)",
        "chapter.verse",
        [
            "וַיְהִי בִּשְׁלֹשִׁים שָׁנָה בָּרְבִיעִי בַּחֲמִשָּׁה לַחֹדֶשׁ",
            "וַאֲנִי בְתוֹךְ־הַגּוֹלָה עַל־נְהַר־כְּבָר",
            "נִפְתְּחוּ הַשָּׁמַיִם וָאֶרְאֶה מַרְאוֹת אֱלֹהִים",
        ],
    ),
    (
        "hbo",
        "Ketuvim",
        "Job (Iyov)",
        "chapter.verse",
        [
            "אִישׁ הָיָה בְאֶרֶץ־עוּץ אִיּוֹב שְׁמוֹ",
            "וְהָיָה הָאִישׁ הַהוּא תָּם וְיָשָׁר",
            "וִירֵא אֱלֹהִים וְסָר מֵרָע",
        ],
    ),
    # Classical Chinese (10 texts)
    (
        "lzh",
        "Confucius",
        "Analects",
        "chapter.verse",
        [
            "子曰學而時習之不亦說乎",
            "有朋自遠方來不亦樂乎",
            "人不知而不慍不亦君子乎",
        ],
    ),
    (
        "lzh",
        "Laozi",
        "Tao Te Ching",
        "chapter",
        [
            "道可道非常道名可名非常名",
            "無名天地之始有名萬物之母",
            "故常無欲以觀其妙常有欲以觀其徼",
        ],
    ),
    (
        "lzh",
        "Sun Tzu",
        "The Art of War",
        "chapter",
        [
            "孫子曰兵者國之大事死生之地存亡之道不可不察也",
            "故經之以五事校之以計而索其情",
            "一曰道二曰天三曰地四曰將五曰法",
        ],
    ),
    (
        "lzh",
        "Zhuangzi",
        "Zhuangzi",
        "chapter",
        [
            "北冥有魚其名為鯤鯤之大不知其幾千里也",
            "化而為鳥其名為鵬鵬之背不知其幾千里也",
            "怒而飛其翼若垂天之雲",
        ],
    ),
    (
        "lzh",
        "Sima Qian",
        "Records of the Grand Historian",
        "chapter",
        [
            "太史公曰余登箕山其上盖有許由冢云",
            "孔子序列古之仁聖賢人如吳太伯伯夷之倫",
            "詳矣余以所聞由光義至高",
        ],
    ),
    (
        "lzh",
        "Mencius",
        "Mencius",
        "chapter",
        [
            "孟子見梁惠王王曰叟不遠千里而來",
            "亦將有以利吾國乎",
            "孟子對曰王何必曰利亦有仁義而已矣",
        ],
    ),
    (
        "lzh",
        "Various",
        "I Ching (Book of Changes)",
        "hexagram",
        [
            "乾元亨利貞",
            "初九潛龍勿用",
            "九二見龍在田利見大人",
        ],
    ),
    (
        "lzh",
        "Various",
        "Classic of Poetry (Shijing)",
        "poem",
        [
            "關關雎鳩在河之洲",
            "窈窕淑女君子好逑",
            "參差荇菜左右流之",
        ],
    ),
    (
        "lzh",
        "Various",
        "Book of Documents (Shujing)",
        "chapter",
        [
            "曰若稽古帝堯曰放勳",
            "欽明文思安安允恭克讓",
            "光被四表格于上下",
        ],
    ),
    (
        "lzh",
        "Zuo Qiuming",
        "Zuo Zhuan",
        "year.entry",
        [
            "春王正月公即位",
            "三月公及邾儀父盟于蔑",
            "夏五月鄭伯克段于鄢",
        ],
    ),
    # Pali (10 texts)
    (
        "pli",
        "Buddha",
        "Dīgha Nikāya",
        "sutta",
        [
            "Evaṃ me sutaṃ. Ekaṃ samayaṃ bhagavā",
            "sāvatthiyaṃ viharati jetavane anāthapiṇḍikassa ārāme.",
            "Tatra kho bhagavā bhikkhū āmantesi: 'bhikkhavo'ti.",
        ],
    ),
    (
        "pli",
        "Buddha",
        "Majjhima Nikāya",
        "sutta",
        [
            "Evaṃ me sutaṃ. Ekaṃ samayaṃ bhagavā",
            "uruvelāyaṃ viharati najjā nerañjarāya tīre",
            "ajapālanigrodhamūle paṭhamābhisambuddho.",
        ],
    ),
    (
        "pli",
        "Buddha",
        "Dhammapada",
        "chapter.verse",
        [
            "Manopubbaṅgamā dhammā, manoseṭṭhā manomayā;",
            "Manasā ce paduṭṭhena, bhāsati vā karoti vā,",
            "Tato naṃ dukkhamanveti, cakkaṃva vahato padaṃ.",
        ],
    ),
    (
        "pli",
        "Various",
        "Jātaka Tales",
        "story",
        [
            "Atīte bārāṇasiyaṃ brahmadatte rajjaṃ kārente",
            "bodhisatto assakhure jāto ahosi.",
            "Tamenaṃ rājā gahetvā rājassahanamhi ṭhapesi.",
        ],
    ),
    (
        "pli",
        "Buddhaghosa",
        "Visuddhimagga",
        "chapter",
        [
            "Namo tassa bhagavato arahato sammāsambuddhassa.",
            "Sīle patiṭṭhāya naro sapañño, cittaṃ paññañca bhāvayaṃ;",
            "Ātāpī nipako bhikkhu, so imaṃ vijaṭaye jaṭaṃ.",
        ],
    ),
    (
        "pli",
        "Buddha",
        "Saṃyutta Nikāya",
        "chapter.sutta",
        [
            "Evaṃ me sutaṃ. Ekaṃ samayaṃ bhagavā",
            "sāvatthiyaṃ viharati jetavane",
            "anāthapiṇḍikassa ārāme.",
        ],
    ),
    (
        "pli",
        "Buddha",
        "Aṅguttara Nikāya",
        "nipāta.sutta",
        [
            "Ekadhammapāḷi. Ekaṃ bhikkhave dhammaṃ",
            "bahukāro vatthugato santāso saṃvego",
            "kathañca bhikkhave ekaṃ dhammaṃ",
        ],
    ),
    (
        "pli",
        "Nāgasena",
        "Milinda Pañha",
        "chapter",
        [
            "Rājā Milindo sāgalaṃ nāma nagaram ajjhāvasati",
            "paññavā paṭibalo caturo vede uggahetā",
            "vedaparaṃparāya anusikkhito",
        ],
    ),
    (
        "pli",
        "Buddha",
        "Vinaya Piṭaka",
        "section",
        [
            "Samantā pāsādikāyā pāḷiyā yathāvuttanayena",
            "tīṇi pitakāni vittharitāni honti.",
            "Tattha vinayapiṭake dve bhāgā.",
        ],
    ),
    (
        "pli",
        "Various",
        "Mahāvaṃsa",
        "chapter",
        [
            "Vanditvā sabbavijjānaṃ pāragū parambujaṃ,",
            "jinasāsanadīpanatthaṃ dīpavaṃsamimaṃ karoṃ.",
            "Pubbe jinavacanato dhammadīpo va jotayaṃ",
        ],
    ),
    # Classical Sanskrit (10 texts)
    (
        "san",
        "Various",
        "Mahābhārata (incl. Bhagavad Gītā)",
        "parva.chapter",
        [
            "नारायणं नमस्कृत्य नरं चैव नरोत्तमम्।",
            "देवीं सरस्वतीं चैव ततो जयमुदीरयेत्॥",
            "धृतराष्ट्र उवाच। धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः।",
        ],
    ),
    (
        "san",
        "Valmiki",
        "Rāmāyaṇa",
        "kāṇḍa.sarga",
        [
            "तपःस्वाध्यायनिरतं तपस्वी वाग्विदां वरम्।",
            "नारदं परिपप्रच्छ वाल्मीकिर्मुनिपुङ्गवम्॥",
            "को न्वस्मिन्साम्प्रतं लोके गुणवान्कश्च वीर्यवान्।",
        ],
    ),
    (
        "san",
        "Vyasa",
        "Bhagavad Gītā",
        "chapter.verse",
        [
            "धृतराष्ट्र उवाच। धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः।",
            "मामकाः पाण्डवाश्चैव किमकुर्वत सञ्जय॥",
            "सञ्जय उवाच। दृष्ट्वा तु पाण्डवानीकं व्यूढं दुर्योधनस्तदा।",
        ],
    ),
    (
        "san",
        "Kauṭilya",
        "Arthaśāstra",
        "book.chapter",
        [
            "अनीक्षिकीत्रयीवार्ताद्द्वीपिकेति विद्याः।",
            "साम्यावराधाय प्रकृतिसम्पदे व्यापाशये",
            "भूमिलाभेन पालने चेति राजवृत्तिः।",
        ],
    ),
    (
        "san",
        "Pāṇini",
        "Aṣṭādhyāyī",
        "adhyāya.pāda.sūtra",
        [
            "वृद्धिरादैच्।",
            "अदेङ् गुणः।",
            "इको गुणवृद्धी।",
        ],
    ),
    (
        "san",
        "Kālidāsa",
        "Abhijñānaśākuntalam",
        "act.verse",
        [
            "या सृष्टिः स्रष्टुराद्या वहति विधिहुतं या हविः",
            "या चेयं व्याप्य विश्वं प्रतिदिवसमदृश्यैव विधत्ते।",
            "येयं कालं कलयति तिथिकरणनामभिर्या",
        ],
    ),
    (
        "san",
        "Kālidāsa",
        "Meghadūta",
        "verse",
        [
            "कश्चित्कान्ताविरहगुरुणा स्वाधिकारात्प्रमत्तः",
            "शापेनास्तङ्गमितमहिमा वर्षभोग्येण भर्तुः।",
            "यक्षश्चक्रे जनकतनयास्नानपुण्योदकेषु",
        ],
    ),
    (
        "san",
        "Suśruta",
        "Suśruta Saṁhitā",
        "sthāna.chapter",
        [
            "अथातः शालाक्यतन्त्रं व्याख्यास्यामः।",
            "इति ह स्माह भगवान्धन्वन्तरिः।",
            "शिरसश्चोर्ध्वजत्रुगतानां",
        ],
    ),
    (
        "san",
        "Various",
        "Pañcatantra",
        "book.story",
        [
            "अस्ति भागीरथ्यां पाटलिपुत्रं नाम नगरम्।",
            "तत्र वर्धमानको नाम धनिकपुत्रो वसति स्म।",
            "स च मूर्खः कापुरुषश्च।",
        ],
    ),
    (
        "san",
        "Patañjali",
        "Yoga Sūtras",
        "pāda.sūtra",
        [
            "अथ योगानुशासनम्॥",
            "योगश्चित्तवृत्तिनिरोधः॥",
            "तदा द्रष्टुः स्वरूपेऽवस्थानम्॥",
        ],
    ),
]


async def seed_reader_texts(session: AsyncSession):
    """Seed database with Reader catalog texts."""
    logger.info("Starting Reader texts seed...")

    # Create default source document
    stmt = select(SourceDoc).where(SourceDoc.slug == "reader-fallback")
    result = await session.execute(stmt)
    source = result.scalar_one_or_none()

    if not source:
        source = SourceDoc(
            slug="reader-fallback",
            title="Reader Catalog Collection",
            license={
                "name": "Public Domain / CC BY-SA 3.0",
                "url": "https://creativecommons.org/licenses/by-sa/3.0/",
            },
            meta={"description": "Curated collection of classical texts for the Reader"},
        )
        session.add(source)
        await session.flush()
        logger.info(f"Created source document: {source.slug}")

    # Process each text in catalog
    texts_created = 0
    segments_created = 0

    for lang_code, author, title, ref_scheme, sample_segments in READER_CATALOG:
        # Get language
        stmt = select(Language).where(Language.code == lang_code)
        result = await session.execute(stmt)
        language = result.scalar_one_or_none()

        if not language:
            logger.warning(f"Language {lang_code} not found, skipping {title}")
            continue

        # Check if work already exists
        stmt = select(TextWork).where(
            TextWork.language_id == language.id, TextWork.author == author, TextWork.title == title
        )
        result = await session.execute(stmt)
        work = result.scalar_one_or_none()

        if work:
            logger.info(f"Work already exists: {author} - {title} ({lang_code})")
            continue

        # Create text work
        work = TextWork(
            language_id=language.id, source_id=source.id, author=author, title=title, ref_scheme=ref_scheme
        )
        session.add(work)
        await session.flush()
        texts_created += 1

        # Add sample segments
        for idx, text in enumerate(sample_segments, start=1):
            text_raw, text_nfc, text_fold = normalize_text(text)

            # Generate reference based on scheme
            if ref_scheme == "book.line":
                ref = f"{title[:3]}.1.{idx}"
                meta = {"book": 1, "line": idx}
            elif ref_scheme == "stephanus":
                # Simple stephanus page refs
                page_num = 17 + (idx // 5)
                section = chr(ord("a") + (idx % 5))
                ref = f"{page_num}{section}"
                meta = {"page": ref}
            elif ref_scheme == "chapter.verse":
                ref = f"1.{idx}"
                meta = {"chapter": 1, "verse": idx}
            elif ref_scheme == "book.chapter.verse":
                ref = f"1.1.{idx}"
                meta = {"book": 1, "chapter": 1, "verse": idx}
            elif ref_scheme == "book.chapter":
                ref = f"1.{idx}"
                meta = {"book": 1, "chapter": idx}
            elif ref_scheme == "sutta":
                ref = f"DN.{idx}"
                meta = {"collection": "DN", "number": idx}
            elif ref_scheme == "chapter":
                ref = f"{idx}"
                meta = {"chapter": idx}
            else:
                ref = f"{idx}"
                meta = {"index": idx}

            segment = TextSegment(
                work_id=work.id, ref=ref, text_raw=text_raw, text_nfc=text_nfc, text_fold=text_fold, meta=meta
            )
            session.add(segment)
            segments_created += 1

        logger.info(f"Created work: {author} - {title} ({lang_code}) with {len(sample_segments)} segments")

    await session.commit()
    logger.info(f"Seed complete: {texts_created} works, {segments_created} segments created")


async def main():
    """Main entry point."""
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        await seed_reader_texts(session)

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
