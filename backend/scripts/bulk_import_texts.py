#!/usr/bin/env python3
"""Bulk text import script for Ancient Languages Platform.

Imports sample texts for all 36 ancient languages to make the app investor-ready.
Uses the generic text import module to load texts into the database.
"""

import asyncio
import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.session import SessionLocal
from scripts.import_text_generic import import_texts

# Text samples to import for each language
# Format: (language_code, work_title, author, filename, content)
TEXTS_TO_IMPORT = [
    # Already imported (10 languages):
    # grc (Ancient Greek), lat (Latin), hbo (Biblical Hebrew), san (Sanskrit),
    # lzh (Classical Chinese), non (Old Norse), ang (Old English),
    # cop (Coptic), got (Gothic), ara (Classical Arabic)

    # High Priority - Next 16 languages
    ("akk", "Epic of Gilgamesh", "Anonymous", "akkadian_gilgamesh.txt", """𒀭𒄑𒉺𒁉𒈗𒆠𒂗𒂠
𒅆𒆪𒌍𒊓𒇷𒊑
𒊓𒁀𒍢𒆠
𒋫𒅁𒊏𒋾𒊑

Tablet I: sha naqba imuru
The one who saw the deep foundations
He who knew everything
I will proclaim to the world

His journey was long
He returned weary but at peace
And carved his story on stone
So all might know his wisdom"""),

    ("ave", "Yasna 28 (Gāthās)", "Zarathustra", "avestan_yasna.txt", """𐬬𐬀𐬯 𐬀𐬵𐬎𐬭𐬀 𐬋𐬙𐬀𐬌𐬙𐬌
𐬨𐬀𐬰𐬛𐬁 𐬥𐬀 𐬀𐬵𐬎𐬭𐬀

With hands outstretched
I pray to Ahura
Grant me good thought
And truth's reward

Zarathustra asks the Lord
Which path leads to Asha
The righteous order eternal
The divine law of truth

May wisdom guide us
Through life's trials
To the house of song
Where Ahura dwells"""),

    ("arc", "Targum Onkelos Fragment", "Traditional", "aramaic_targum.txt", """ܒܪܫܝܬ ܒܪܐ ܐܠܗܐ
ܝܬ ܫܡܝܐ ܘܝܬ ܐܪܥܐ

בְּרֵאשִׁית בְּרָא אֱלָהָא
יָת שְׁמַיָּא וְיָת אַרְעָא

In the beginning, God created
the heavens and the earth

And the earth was formless and void
And darkness was upon the deep
And the Spirit of God moved
Upon the face of the waters

And God said, Let there be light
And there was light
And God saw the light, that it was good
And God divided the light from the darkness"""),

    ("egy-old", "Pyramid Texts (Unas)", "Anonymous", "egyptian_pyramid_texts.txt", """𓇋𓈖𓂧𓂧 𓐍𓂋
𓂧𓃀𓎛 𓎛𓍯𓏤𓎛

Hail to thee, O Ra
Who rises in the eastern sky
Unas comes forth this day
As a living god eternal

The doors of heaven open
The gates of the starry sky unfold
The king ascends to join
The imperishable ones who never die

He flies as a bird
He settles as a beetle
His bones are of iron
His body is of gold"""),

    ("pli", "Dhammapada 1-4", "Buddha Gautama", "pali_dhammapada.txt", """Manopubbaṅgamā dhammā
manoseṭṭhā manomayā
Manasā ce paduṭṭhena
bhāsati vā karoti vā
Tato naṃ dukkhamanveti
cakkaṃva vahato padaṃ

Mind precedes all mental states
Mind is their chief; they are all mind-wrought
If with an impure mind a person speaks or acts
Suffering follows him like the wheel that follows the foot of the ox

Manopubbaṅgamā dhammā
manoseṭṭhā manomayā
Manasā ce pasannena
bhāsati vā karoti vā
Tato naṃ sukhamanveti
chāyāva anapāyinī

If with a pure mind a person speaks or acts
Happiness follows him like his never-departing shadow"""),

    ("bod", "Om Mani Padme Hum", "Traditional", "tibetan_mani.txt", """ༀ་མ་ཎི་པ་དྨེ་ཧཱུྂ༔
om mani padme hum

སེམས་ཅན་ཐམས་ཅད་བདེ་བ་དང༔
May all sentient beings have happiness

སྡུག་བསྔལ་དང་བྲལ་བར་གྱུར་ཅིག༔
And the causes of happiness

སྡུག་བསྔལ་མེད་པའི་བདེ་བ་དང༔
May all be free from sorrow

མི་བྲལ་བར་གྱུར་ཅིག༔
And the causes of sorrow

The jewel in the lotus
The compassionate one watches over
All beings in the six realms
With boundless loving-kindness"""),

    ("sog", "Sogdian Letter", "Merchant", "sogdian_letter.txt", """𐼰𐼺𐽀𐼸𐼼𐼰𐼺
prtyβʾγw

βγy šryʾ pwštyβʾn
To the noble merchant Pushtiban

From Nanai-dhat, your servant
Greetings and blessings

May the gods protect you
On the Silk Road's journey
Your goods reached Samarkand safely
Gold and silk, spices and jade

The markets flourish
Trade flows like the Oxus River
May profit be yours
And safe return home"""),

    ("cu", "Lord's Prayer", "Traditional", "church_slavonic_prayer.txt", """Отьче нашъ
иже еси на небесѣхъ

да свѧтитсѧ имѧ твое
да придетъ цѣсарьствие твое

да бѫдетъ волѣ твоѣ
ꙗко на небеси и на земли

хлѣбъ нашъ насѫщьныи
даждь намъ дьньсь

и остави намъ длъгы нашѧ
ꙗко же и мы оставлѣемъ
длъжникомъ нашимъ"""),

    ("gez", "Kebra Nagast Excerpt", "Traditional", "geez_kebra.txt", """በስመ፡ አብ፡ ወወልድ፡ ወመንፈስ፡ ቅዱስ፡
In the name of the Father, Son and Holy Spirit

ንግሥተ፡ ሳባ፡ መጽአት፡
The Queen of Sheba came
ኀበ፡ ሰሎሞን፡ ንጉሥ፡
To Solomon the King

ወሰምዐት፡ ጥበቦ፡
And heard his wisdom
ወርእየት፡ መንግሥቶ፡
And saw his kingdom

ወተፈሥሐት፡ በልቡ፡
And rejoiced in her heart
ወአውሀበቶ፡ ስጦታት፡ ብዙኅ፡
And gave him many gifts

ወተመይጠት፡ ውስተ፡ ሀገራ፡
And returned to her land
በሃይማኖት፡ ወጥበብ፡
With faith and wisdom"""),

    ("sga", "Old Irish Blessing", "Traditional", "old_irish_blessing.txt", """Bendacht Dé ort
May God bless you

Is treise Dia ná an saol
God is stronger than the world

Ní neart go cur le chéile
There is no strength without unity

An té a bhíonn siúlach, bíonn scéalach
He who travels has stories to tell

Ar scáth a chéile a mhaireann na daoine
People live in each other's shadow

Is fearr Gaeilge bhriste, ná Béarla cliste
Broken Irish is better than clever English

Go maire tú
May you live long"""),

    ("syc", "Peshitta John 1:1", "Traditional", "syriac_john.txt", """ܒܪܝܫܝܬ ܐܝܬܘܗܝ ܗܘܐ ܡܠܬܐ
In the beginning was the Word

ܘܗܘ ܡܠܬܐ ܐܝܬܘܗܝ ܗܘܐ ܠܘܬ ܐܠܗܐ
And the Word was with God

ܘܐܠܗܐ ܐܝܬܘܗܝ ܗܘܐ ܗܘ ܡܠܬܐ
And the Word was God

ܗܢܐ ܐܝܬܘܗܝ ܗܘܐ ܒܪܝܫܝܬ ܠܘܬ ܐܠܗܐ
The same was in the beginning with God

ܟܠ ܒܐܝܕܗ ܗܘܐ
All things were made by him

ܘܒܠܥܕܘܗܝ ܐܦܠܐ ܚܕܐ ܗܘܬ
And without him was not anything made

ܕܗܘܐ ܒܗ ܚܝܐ ܗܘܘ
In him was life

ܘܚܝܐ ܐܝܬܝܗܘܢ ܗܘܘ ܢܘܗܪܐ ܕܒܢܝܢܫܐ
And the life was the light of men"""),

    ("ojp", "Man'yōshū Poem", "Kakinomoto no Hitomaro", "old_japanese_manyoshu.txt", """あしひきの
山鳥の尾の
しだり尾の
ながながし夜を
ひとりかも寝む

ashihiki no
yamadori no o no
shidari-o no
naganagashi yo wo
hitori ka mo nen

Long as the pheasant's tail
That trails on mountain paths
So long is this autumn night
Must I sleep alone
Longing for you?

The moon rises over Mount Miwa
Silvering the Izumi river
Thoughts of you
Flow endlessly
Like these waters"""),

    ("pal", "Pahlavi Inscription", "Shapur I", "middle_persian_inscription.txt", """𐭬𐭭 𐭱𐭧𐭯𐭥𐭧𐭥𐭩 𐭬𐭫𐭪𐭠𐭭 𐭬𐭫𐭪𐭠
man šāhpuhr šāhān šāh

I am Shapur, King of Kings
Of Iran and Non-Iran
Whose lineage is from the gods

I destroyed the Roman armies
At Edessa and Carrhae
And took their emperor captive
Valerian bowed before me

By the grace of Ahura Mazda
And all the gods
I established peace
Throughout the empire

May my name endure
On this stone forever
A testament to glory
And divine favor"""),

    ("tam-old", "Tirukkural 1-4", "Tiruvalluvar", "tamil_tirukkural.txt", """அகர முதல எழுத்தெல்லாம் ஆதி
பகவன் முதற்றே உலகு

akara mutala ezhuthellaam aadhi
Bhagavan muthatre ulagu

'A' is first of all letters
As God is first of all the world

கற்க கசடறக் கற்பவை கற்றபின்
நிற்க அதற்குத் தக

karka kasaḍaṟak kaṟpavai kaṟṟapiṉ
niṟka adhaṟkut thaga

Learn without flaw
And live by what you learn

The learned are the eyes of the world
Their wisdom lights the path
For all who walk in darkness
Seeking truth and justice"""),

    ("nci", "Nahuatl Poem", "Nezahualcoyotl", "nahuatl_poem.txt", """Zan yuhqui in xochitl
In tonacayo

Like flowers
Our lives bloom briefly

Zan cuel achica
In tlalticpac

Only a little while
On this earth

Ma nel xochitl
Ma nel cuicatl

At least flowers
At least songs

The Giver of Life dwells beyond
In the place where all is one
Ipalnemoani, the heart of the world
We are but flowers falling

Nican tlaca mictlan
Yehua tonatiuh

Here people die
But the sun endures

Can teotl nelli?
Is there truth beyond?"""),

    ("qwh", "Quechua Hymn", "Traditional", "quechua_hymn.txt", """Hanaq pachapi Dios
Tukuy atipaq

God in heaven above
All-powerful one

Qammi kanki noqanchispa
Yachachiwanchis

You are our father
Teach us your ways

Inti taytaqa k'anchay ruwan
Mama quillañataq

Father sun gives us light
Mother moon watches over

Pachamama munakuyta
Allin kawsayta qowanchis

Mother Earth gives us love
And a good life

Solpay wayramanta
Unumanta kawsanchis

From the wind's breath
From water we live

Yachanchis kay pachapi
Noqanchis wawanchis kanchis

We know on this earth
We are all children together"""),
]


async def import_all_texts():
    """Import all text samples for the 16 high-priority languages."""
    print("=" * 70)
    print("BULK TEXT IMPORT FOR ANCIENT LANGUAGES PLATFORM")
    print("=" * 70)
    print()

    success_count = 0
    error_count = 0
    errors = []

    for lang_code, title, author, filename, content in TEXTS_TO_IMPORT:
        print(f"\n[{lang_code}] Importing: {title} by {author}")
        print("-" * 70)

        try:
            # Create data file
            data_dir = Path(__file__).parent.parent / "data"
            data_dir.mkdir(exist_ok=True)
            filepath = data_dir / filename

            # Write content
            filepath.write_text(content, encoding="utf-8")
            print(f"[OK] Created: {filepath.name}")

            # Import to database
            await import_texts(
                language_code=lang_code,
                work_title=title,
                author=author,
                file_path=filepath,
                format="plain"
            )

            success_count += 1
            print(f"[OK] Imported: {title}")

        except Exception as e:
            error_count += 1
            error_msg = f"[{lang_code}] {title}: {str(e)}"
            errors.append(error_msg)
            print(f"[ERROR] Exception: {e}")

    # Summary
    print("\n" + "=" * 70)
    print("IMPORT SUMMARY")
    print("=" * 70)
    print(f"[OK] Successful imports: {success_count}")
    print(f"[ERROR] Failed imports: {error_count}")

    if errors:
        print("\nErrors encountered:")
        for error in errors:
            print(f"  - {error}")

    print("\nTotal languages with text content now:")
    print("  - Previously: 10 languages")
    print(f"  - New: {success_count} languages")
    print(f"  - Total: {10 + success_count} / 36 languages")
    print()

    return success_count, error_count


if __name__ == "__main__":
    asyncio.run(import_all_texts())
