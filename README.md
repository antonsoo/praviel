# Ancient Languages — Learn to Read Homer in Greek

**This is a working app that teaches you to read ancient texts in their original languages.**

## 💝 Support This Project

**Research-grade Classical Greek • BYOK Privacy • Open Source Forever**

[GitHub Sponsors](https://github.com/sponsors/antonsoo) • [Stripe](PLACEHOLDER_STRIPE) • [Patreon](PLACEHOLDER_PATREON) • [Liberapay](PLACEHOLDER_LIBERAPAY) • [Ko-fi](PLACEHOLDER_KOFI) • [Open Collective](https://opencollective.com/ancientlanguages)

**Crypto:** BTC: `PLACEHOLDER_BTC` • ETH: `PLACEHOLDER_ETH` • XMR: `PLACEHOLDER_XMR`

[Learn more about supporting →](docs/SUPPORT.md)

---

**Status:** MVP with Classical Greek (Homer's *Iliad*) — functional now
**License:** Apache-2.0 (code) + original licenses for data
**Cost:** Free (offline) or BYOK (bring your own API key)

[Try It Now](#quick-start) • [See API Examples](#proof-it-works) • [Star This Repo ⭐](https://github.com/antonsoo/AncientLanguages)

---

## What This App Does

**Read ancient texts by:**
- **Tapping words** → instant lemma, morphology, LSJ dictionary, Smyth grammar
- **AI lessons** → alphabet drills, vocab matching, cloze exercises, translations
- **Chat practice** → converse with historical personas in Ancient Greek
- **Track progress** → XP, streaks, levels

**Currently:** Classical Greek (Homer's *Iliad*)
**Coming:** Classical Latin, Ancient Hebrew, Old Egyptian

---

## 🔬 Proof It Works

### Real API Response (Reader Analysis)

**Input:** `Μῆνιν ἄειδε θεά` (Iliad 1.1 — "Sing, goddess, the wrath")

**POST** `/reader/analyze?include={"lsj":true,"smyth":true}`

**Response:**
```json
{
  "tokens": [
    {
      "text": "Μῆνιν",
      "lemma": "μῆνις",
      "morph": "n-s---fa-",
      "gloss": "wrath, anger"
    },
    {
      "text": "ἄειδε",
      "lemma": "ἀείδω",
      "morph": "v-2spma--",
      "gloss": "sing, chant"
    },
    {
      "text": "θεά",
      "lemma": "θεά",
      "morph": "n-s---fv-",
      "gloss": "goddess"
    }
  ],
  "lexicon": [
    {
      "lemma": "μῆνις",
      "gloss": "wrath, anger, esp. of the gods",
      "citation": "LSJ s.v. μῆνις",
      "ref": "http://www.perseus.tufts.edu/..."
    }
  ],
  "grammar": [
    {
      "anchor": "smyth-175",
      "title": "Accusative of Respect",
      "score": 0.95
    }
  ]
}
```

**This is real data from the Perseus Digital Library, LSJ Lexicon, and Smyth Grammar.**

---

### Real Lesson Generation (AI)

**POST** `/lesson/generate`

```json
{
  "language": "grc",
  "profile": "beginner",
  "exercise_types": ["alphabet", "match", "cloze"],
  "provider": "echo"
}
```

**Response:** Complete lesson with 4 exercises:
- Alphabet drill (recognize β, γ, δ)
- Matching (λόγος → "word, speech")
- Cloze from *Iliad* 1.5: "οὐλομένην, ἣ μυρί' Ἀχαιοῖς ἄλγε' [____]" (answer: ἔθηκε)
- Translation practice

[See full API examples →](docs/API_EXAMPLES.md)

---

## Why This Matters

**Every translation loses something:**
- Greek: 4 words for "love" (ἔρως, φιλία, ἀγάπη, στοργή) → English: just "love"
- Wordplay vanishes (puns that worked in Greek don't translate)
- Meter disappears (Homeric hexameter becomes prose)
- Cultural context needs footnotes

**When you read a translation, you're reading an interpretation.**
**When you read the original, you're reading the actual words.**

---

## ✅ What Works Now

**Reader Mode:**
- ✅ Analyze any Greek text (paste Iliad passages)
- ✅ Tap words → lemma, morphology, LSJ definitions, Smyth grammar refs
- ✅ Full morphological analysis with source citations
- ✅ Works offline (uses embedded Perseus data)

**AI Lessons:**
- ✅ 4 exercise types (alphabet, match, cloze, translate)
- ✅ Text-targeted (generate from specific Iliad passages like "Il.1.20-1.50")
- ✅ Literary vs. colloquial register (formal vs. everyday Greek)
- ✅ Multi-provider (OpenAI GPT-5, Anthropic Claude 4.5, Google Gemini 2.5, offline echo)

**Chat Mode:**
- ✅ Converse with historical personas (e.g., "Athenian merchant, 400 BCE")
- ✅ Get grammar help in English while practicing Greek
- ✅ Multiple providers supported

**Progress:**
- ✅ XP, levels, daily streaks
- ✅ Lesson history

---

## 🔬 Research-Grade Data

**Built on gold-standard academic sources:**

| Source | What It Provides | Details |
|--------|------------------|---------|
| **Perseus Digital Library** | Morphological analysis | Every Greek word tagged with lemma, part of speech, case, number, gender, tense, voice, mood |
| **Liddell-Scott-Jones Lexicon** | Dictionary definitions | 1940 edition, 116,502 entries, the definitive Ancient Greek dictionary |
| **Smyth's Greek Grammar** | Grammar references | 1920 edition, 3,000+ sections covering all aspects of Ancient Greek grammar |

**Every definition includes source citations.** No AI hallucinations.

---

## 🔑 Free Forever (BYOK)

**Free options:**
- ✅ **Offline "echo" provider** — completely free, no API key needed
- ✅ **Google Gemini 2.5 Flash** — generous free tier (enough for daily learning)

**Paid options (pay-as-you-go):**
- 💰 **OpenAI GPT-5** — ~$0.01-0.05 per lesson (best quality)
- 💰 **Anthropic Claude 4.5** — pay-as-you-go (great for explanations)

**Your keys are request-scoped — never stored, never logged.**

---

## 📚 Languages

**Now:** ✅ Classical Greek (Homer's *Iliad*)

**Next:**
- 🚀 Classical Latin (Virgil, Cicero, Caesar)
- 📜 Ancient Hebrew (Tanakh)
- 𓃭 Old Egyptian (Middle Egyptian hieroglyphics)

[See full roadmap →](BIG-PICTURE_PROJECT_PLAN.md) | [Vote for next language →](https://github.com/antonsoo/AncientLanguages/discussions)

---

## 🚀 Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Miniconda](https://docs.conda.io/en/latest/miniconda.html)

### Setup (5 minutes)

```bash
# Clone & setup
git clone https://github.com/antonsoo/AncientLanguages
cd AncientLanguages
docker compose up -d

# Install dependencies
conda create -y -n ancient python=3.12 && conda activate ancient
pip install -e ".[dev]"
python -m alembic -c alembic.ini upgrade head

# Run
uvicorn app.main:app --reload
```

**Open:** http://localhost:8000

### Optional: Add Free API Key

```bash
# Get key from https://aistudio.google.com/app/apikey
echo "GOOGLE_API_KEY=your-key-here" >> backend/.env
echo "LESSONS_ENABLED=1" >> backend/.env
# Restart server
```

[Full setup guide →](GETTING_STARTED.md)

---

## 📖 Try It Immediately

### 1. Analyze Greek Text

```bash
curl -X POST 'http://127.0.0.1:8000/reader/analyze?include={"lsj":true,"smyth":true}' \
  -H 'Content-Type: application/json' \
  -d '{"q":"Μῆνιν ἄειδε θεά"}'
```

Returns: lemmas, morphology, LSJ definitions, Smyth grammar references

### 2. Generate a Lesson

```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "exercise_types": ["alphabet", "match", "cloze"],
    "provider": "echo"
  }'
```

Returns: Complete lesson with exercises, prompts, and answers

### 3. Run the Flutter App

```bash
cd client/flutter_reader
flutter pub get
flutter run -d chrome
```

[More API examples →](docs/API_EXAMPLES.md)

---

## 📖 Documentation

**Learners:**
- [🚀 Getting Started](GETTING_STARTED.md) — Non-technical 5-min setup
- [🎯 Project Vision](BIG-PICTURE_PROJECT_PLAN.md) — Why ancient languages matter

**Developers:**
- [💻 Development](docs/DEVELOPMENT.md) — Architecture, testing
- [📡 API Examples](docs/API_EXAMPLES.md) — Complete curl examples
- [🪟 Windows](docs/WINDOWS.md) — Platform-specific setup

**Contributors:**
- [🤝 Contributing](CONTRIBUTING.md) — Code, linguistics, docs
- [🤖 Agent Guidelines](AGENTS.md) — Development handbook (read this!)
- [📋 API Guidelines](docs/AI_AGENT_GUIDELINES.md) — October 2025 API specs

**Features:**
- [📝 Lessons](docs/LESSONS.md) — AI lesson generation
- [💬 Chat](docs/COACH.md) — Conversational practice
- [🔊 TTS](docs/TTS.md) — Text-to-speech
- [🔑 BYOK](docs/BYOK.md) — Bring your own key

---

## 🤖 October 2025 APIs

⚠️ **Important for Developers:**

This repo uses **October 2025 API implementations:**
- **OpenAI:** `/v1/responses` (NOT `/v1/chat/completions`)
- **Anthropic:** Claude 4.5/4.1 (NOT 3.x)
- **Google:** Gemini 2.5 (NOT 1.x)

**Before modifying providers:**
1. Read [AGENTS.md](AGENTS.md)
2. Read [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)
3. Run `python scripts/validate_october_2025_apis.py`

---

## 🤝 How to Help

⭐ **Star this repo** — Help others discover it

💝 **Support development** — [GitHub Sponsors](https://github.com/sponsors/antonsoo), [Open Collective](https://opencollective.com/ancientlanguages), or [other methods](docs/SUPPORT.md)

🗳️ **Vote for languages** — [Discussions](https://github.com/antonsoo/AncientLanguages/discussions)

🐛 **Report bugs** — [Issues](https://github.com/antonsoo/AncientLanguages/issues)

💻 **Contribute code** — Backend (Python/FastAPI), Frontend (Flutter), Data pipelines

📝 **Improve docs** — Tutorials, translations, examples

🧠 **Share linguistics expertise** — Validate reconstructions, curate data

[Contributing Guide →](CONTRIBUTING.md)

---

## 🏆 Current Status

**MVP:** Classical Greek (Homer's Iliad)

✅ **Working:**
- Reader with morphological analysis (uses Perseus data)
- AI lesson generation (4 exercise types, multi-provider)
- Chat with historical personas
- Progress tracking (XP, streaks, levels)
- BYOK support

🚧 **In Progress:**
- Expanding text coverage
- Mobile app improvements
- Enhanced customization

🚀 **Next:**
- Classical Latin
- Spaced repetition
- Community content

---

## 🌍 Community

💬 [Discussions](https://github.com/antonsoo/AncientLanguages/discussions) — Questions, requests
🐛 [Issues](https://github.com/antonsoo/AncientLanguages/issues) — Bug reports
⭐ **Star** and **Watch** for updates

---

## 📄 License

**Code:** Apache-2.0 (fork it, extend it, use it)
**Data:** Original licenses (Perseus/LSJ: CC BY-SA, etc.)

[Full details →](docs/licensing-matrix.md)

---

## 🙏 Acknowledgments

- **Perseus Digital Library** — Digitized texts & morphological data
- **Liddell-Scott-Jones** — The definitive Greek dictionary
- **Smyth's Grammar** — Authoritative reference
- **Open source community** — Makes this possible

---

<div align="center">

**Join us in preserving the languages of our ancestors.**

**Every ancient text you read is a conversation across millennia.**

[Start Learning](GETTING_STARTED.md) • [Start Developing](docs/DEVELOPMENT.md) • [Start Contributing](CONTRIBUTING.md)

---

**⭐ Star if you believe ancient languages should be accessible to everyone**

</div>
