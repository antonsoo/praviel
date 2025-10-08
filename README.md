# Ancient Languages — Learn Ancient Greek with AI-Powered Gamification

**The first AI-powered language learning platform for Classical Greek**

- 🎓 **Interactive lessons** with 4 exercise types (gamified learning)
- 🤖 **AI chat tutors** — converse with ancient Athenians, Spartans, philosophers
- 🏆 **Full gamification** — XP, levels, streaks, achievements, skill trees
- 📖 **Real ancient texts** — learn from Homer's *Iliad*, not "The apple is red"
- 🔬 **Research-grade** — built on Perseus Digital Library, LSJ Lexicon, Smyth Grammar
- 🔐 **Privacy-first** — BYOK (bring your own API key), works offline

**Status:** ✅ Fully functional MVP | **License:** ELv2 (Elastic License 2.0) | **Cost:** Free

[🚀 Try It Now](#-quick-start) • [📖 Read the Docs](#-documentation) • [⭐ Star This Repo](https://github.com/antonsoo/AncientLanguages)

---

## What This App Does

**Learn Ancient Greek through:**
- **AI-powered lessons** → 4 exercise types (alphabet, match, cloze, translate) tailored to your level
- **Interactive reading** → Tap any word in Homer's *Iliad* for instant lemma, morphology, LSJ dictionary, and Smyth grammar
- **Conversational practice** → Chat with historical personas (Athenian merchants, Spartan warriors) in Ancient Greek
- **Gamification** → XP, levels, daily streaks, achievements, skill ratings (ELO system)
- **Text-to-speech** → Hear reconstructed Ancient Greek pronunciation
- **Progress tracking** → Detailed analytics on vocabulary coverage, reading speed, skill mastery (ELO ratings per topic)

**Think:** Addictive gamified UX + academic rigor (Perseus Digital Library, LSJ Lexicon, Smyth Grammar) + privacy-first BYOK AI

**Currently:** Classical Greek (Homer's *Iliad*)
**Coming:** Classical Latin, Ancient Hebrew, Old Egyptian

---

## 🎬 See It In Action

> **Note:** Screenshots and demo videos coming soon. For now, [try the app locally](#-quick-start) in 5 minutes.

### 1. AI Lessons (Gamified & Interactive)

Generate personalized lessons from Homer's *Iliad*:

- **Alphabet drills** — Learn to recognize β, γ, δ (with audio pronunciation)
- **Match exercises** — Pair Greek words with English (λόγος → "word, speech")
- **Cloze (fill-in-blank)** — Complete *Iliad* passages: "οὐλομένην, ἣ μυρί' Ἀχαιοῖς ἄλγε' [____]" (answer: ἔθηκε)
- **Translation practice** — Translate Greek ↔ English

**Earn XP, maintain your streak, level up!** 🔥

### 2. Chat with Ancient Greeks

Converse in Ancient Greek with AI-powered historical personas:

- 🏛️ **Athenian philosopher** — Socratic dialogue style, philosophical debates
- ⚔️ **Spartan warrior** — Military discipline, honor codes
- 🏺 **Athenian merchant** — Marketplace Greek, everyday conversations
- 🏛️ **Roman senator** — Latin with Greek code-switching

**Ask for help in English, practice in Greek, get instant grammar feedback.**

### 3. Interactive Reader (Tap Any Word)

Reading Homer's *Iliad*: **Μῆνιν ἄειδε θεά** (Iliad 1.1 — "Sing, goddess, the wrath")

**Tap "Μῆνιν"** → Get instant analysis:
- **Lemma:** μῆνις (dictionary form)
- **Morphology:** Feminine accusative singular noun
- **LSJ Definition:** "wrath, anger, esp. of the gods"
- **Smyth Grammar:** §175 (Accusative of Respect)

**Every definition includes source citations from Perseus Digital Library.**

---

### 🔬 For Developers: Real API Examples

[See complete API documentation →](docs/API_EXAMPLES.md)

<details>
<summary><b>Example: Generate a lesson via API</b></summary>

**POST** `/lesson/generate`

```json
{
  "language": "grc",
  "profile": "beginner",
  "exercise_types": ["alphabet", "match", "cloze", "translate"],
  "provider": "echo"
}
```

**Response:** Complete lesson JSON with exercises, prompts, and answers.

</details>

<details>
<summary><b>Example: Analyze Greek text via API</b></summary>

**POST** `/reader/analyze?include={"lsj":true,"smyth":true}`

```json
{"q": "Μῆνιν ἄειδε θεά"}
```

**Response:** Morphology, LSJ definitions, and Smyth grammar for each word.

</details>

---

## Why Learn Ancient Greek (vs. Just Reading Translations)?

**Every translation loses something:**
- **Nuance:** Greek has 4 words for "love" (ἔρως, φιλία, ἀγάπη, στοργή) → English collapses them to just "love"
- **Wordplay:** Puns, alliteration, and rhetoric that worked in the original become invisible
- **Meter:** Homeric hexameter's musicality turns into flat prose
- **Cultural context:** Idioms and references need footnotes instead of feeling natural

**When you read a translation, you're reading someone's interpretation.**
**When you read the original, you're hearing the author's actual voice.**

**This app makes learning Ancient Greek accessible and engaging through modern gamified methods—without sacrificing academic rigor.**

---

## 🎯 Who This Is For

### ✅ **Perfect For:**

- 📚 **Classics students** — supplement your coursework with AI-powered practice
- 🎓 **Independent learners** — teach yourself Ancient Greek from scratch
- 📖 **Homeschoolers** — comprehensive curriculum for ancient language study
- 🏛️ **History enthusiasts** — read primary sources from ancient Greece
- 📜 **Theology students** — read the New Testament in Koine Greek (coming soon)
- 🧠 **Lifelong learners** — challenge yourself with a new language
- 💻 **Developers** — contribute to open-source language learning tech

### ❌ **Not For:**

- Modern Greek speakers (this is Ancient/Classical Greek, not Modern Greek)
- Casual learners who just want phrase translation (use Google Translate instead)
- Anyone looking for instant fluency (language learning takes time and practice)

**No prior Greek knowledge required.** Start from the alphabet and work your way up to reading Homer.

---

## ✅ What Works Now

**🎓 AI-Powered Lessons (The Core Experience):**
- ✅ **4 exercise types:** Alphabet drills, match (vocab pairing), cloze (fill-in-blank), translation (Greek ↔ English)
- ✅ **Text-targeted learning:** Generate lessons from specific *Iliad* passages (e.g., "Il.1.20-1.50")
- ✅ **Adaptive difficulty:** Beginner/intermediate profiles
- ✅ **Register modes:** Literary (formal classical) vs. colloquial (everyday speech)
- ✅ **Multi-provider AI:** OpenAI GPT-5, Anthropic Claude 4.5, Google Gemini 2.5, or offline Echo

**💬 Conversational Practice:**
- ✅ **Chat with historical personas:** Athenian merchant (400 BCE), Spartan warrior, Athenian philosopher, Roman senator
- ✅ **Bilingual help:** Practice in Greek, get grammar explanations in English
- ✅ **Context-aware:** AI retrieves relevant grammar/lexicon before responding

**📖 Interactive Reading:**
- ✅ **Tap-to-analyze:** Click any word in Homer's *Iliad* for instant lemma, morphology, LSJ definitions, Smyth grammar
- ✅ **Hybrid search:** Find similar passages (lexical + semantic vector search)
- ✅ **Full citations:** Every definition sourced from Perseus Digital Library, LSJ, Smyth
- ✅ **Works offline:** Embedded linguistic data (no API required for reader)

**🏆 Gamification & Progress:**
- ✅ **XP & levels:** Earn experience, level up algorithmically (dynamic XP thresholds)
- ✅ **Daily streaks:** Track consecutive days of practice (with max streak records)
- ✅ **Achievements:** Unlock badges and milestones
- ✅ **Skills tracking:** ELO ratings per grammar topic (e.g., aorist passive, genitive absolute)
- ✅ **Text stats:** Track vocabulary coverage, reading speed (WPM), comprehension per work
- 🚧 **Quests & SRS:** Database models ready, API endpoints coming soon

**🔊 Text-to-Speech:**
- ✅ **Reconstructed pronunciation:** Hear Ancient Greek spoken aloud (OpenAI TTS, Google TTS)

**🔐 Privacy & Customization:**
- ✅ **BYOK (Bring Your Own Key):** Use your own OpenAI/Anthropic/Google API keys (encrypted at rest)
- ✅ **Preferences:** Default models, daily goals, SRS limits, themes
- ✅ **No lock-in:** Works offline (Echo provider), or pay-as-you-go with your keys

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

**Get the app running in 5 minutes (even with zero technical experience).**

### Step 1: Install Prerequisites

- **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** — Database engine (just click through installer)
- **[Miniconda](https://docs.conda.io/en/latest/miniconda.html)** — Python environment (download & run installer)

### Step 2: Run Setup Commands

Open your terminal (Command Prompt on Windows, Terminal on Mac/Linux) and paste these commands:

```bash
# Download the app
git clone https://github.com/antonsoo/AncientLanguages
cd AncientLanguages

# Start the database
docker compose up -d

# Install dependencies
conda create -y -n ancient python=3.12
conda activate ancient
pip install -e ".[dev]"

# Set up database tables
python -m alembic -c alembic.ini upgrade head

# Launch the app
uvicorn app.main:app --reload
```

### Step 3: Open Your Browser

**Go to:** http://localhost:8000

🎉 **You're done!** The app is now running on your computer.

### Step 4 (Optional): Enable AI Lessons

The app works offline, but AI-powered lessons are much better. Get a **free** Google Gemini API key:

1. Visit https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Copy your key (looks like `AIza...`)
4. Add it to your `.env` file:

```bash
echo "GOOGLE_API_KEY=AIza-your-key-here" >> backend/.env
echo "LESSONS_ENABLED=1" >> backend/.env
# Restart the server (Ctrl+C, then run uvicorn again)
```

**📚 Need help?** See the [complete setup guide →](GETTING_STARTED.md)

---

## ❓ Common Questions

### Is this really free?

**Yes, completely free.** The app is open source (Elastic License 2.0) and works offline with no API key. If you want AI-powered lessons, you bring your own API key and pay only for what you use (Google Gemini has a generous free tier).

**No subscriptions. No hidden fees. No data collection.**

### Do I need to know Greek already?

**Nope!** Start from absolute zero. The app has alphabet drills for complete beginners and progresses all the way to reading full *Iliad* passages. It's designed for learners at every level.

### How is this different from other language learning apps?

**Most gamified language apps don't teach ancient languages.** This app fills that gap with:
- ✅ Real ancient texts (not "The apple is red")
- ✅ Research-grade data (Perseus, LSJ, Smyth)
- ✅ Privacy-first (BYOK, no data collection)
- ✅ Open source (Elastic License 2.0, fork it if you want)

And it has the **same addictive UX** you expect from modern language apps (XP, streaks, levels, gamification).

### Can I use this on my phone?

**Yes.** The Flutter app works on web (Chrome, Safari, etc.) and can be accessed from mobile browsers. Native iOS/Android apps are in development.

### How long does it take to learn Ancient Greek?

Depends on your goals:
- **Read simple sentences:** 2-4 weeks (alphabet + basic vocab)
- **Read *Iliad* with dictionary help:** 3-6 months (consistent daily practice)
- **Read fluently without dictionary:** 1-2 years (serious study)

**This app makes it as fast and fun as possible, but language learning still takes time and effort.**

### What if I get stuck or find a bug?

- 💬 [GitHub Discussions](https://github.com/antonsoo/AncientLanguages/discussions) — Ask questions, get help
- 🐛 [GitHub Issues](https://github.com/antonsoo/AncientLanguages/issues) — Report bugs
- 📖 [Documentation](docs/) — Comprehensive guides

---

## 📖 Documentation

**Learners:**
- [🚀 Getting Started](GETTING_STARTED.md) — Non-technical 5-min setup
- [🎯 Project Vision](BIG-PICTURE_PROJECT_PLAN.md) — Why ancient languages matter
- [✨ Feature Status](FEATURES.md) — Comprehensive feature matrix (what works now vs. planned)

**Developers:**
- [💻 Development](docs/DEVELOPMENT.md) — Architecture, testing
- [📡 API Examples](docs/API_EXAMPLES.md) — Complete curl examples
- [🐳 Docker Deployment](docs/DOCKER.md) — Production containerization
- [🪟 Windows](docs/WINDOWS.md) — Platform-specific setup

**Contributors:**
- [🤝 Contributing](CONTRIBUTING.md) — Code, linguistics, docs
- [🤖 Agent Guidelines](AGENTS.md) — Development handbook (read this!)
- [📋 API Guidelines](docs/AI_AGENT_GUIDELINES.md) — October 2025 API specs
- [⚠️ October 2025 APIs](#october-2025-apis) — Critical info for AI provider code

**Features:**
- [📝 Lessons](docs/LESSONS.md) — AI lesson generation
- [💬 Chat](docs/COACH.md) — Conversational practice
- [🔊 TTS](docs/TTS.md) — Text-to-speech
- [🔑 BYOK](docs/BYOK.md) — Bring your own key

---

## 🤝 How to Help

⭐ **Star this repo** — Help others discover it

💝 **Support development** — [GitHub Sponsors](https://github.com/sponsors/antonsoo) or [other methods](docs/SUPPORT.md)

🗳️ **Vote for languages** — [Discussions](https://github.com/antonsoo/AncientLanguages/discussions)

🐛 **Report bugs** — [Issues](https://github.com/antonsoo/AncientLanguages/issues)

💻 **Contribute code** — Backend (Python/FastAPI), Frontend (Flutter), Data pipelines

📝 **Improve docs** — Tutorials, translations, examples

🧠 **Share linguistics expertise** — Validate reconstructions, curate data

[Contributing Guide →](CONTRIBUTING.md)

---

## 🏆 Current Status

**MVP:** Classical Greek (Homer's Iliad) — **Fully Functional**

✅ **Production-Ready (23 features):**
- ✅ AI lesson generation (4 exercise types: alphabet, match, cloze, translate)
- ✅ Conversational chat (4 historical personas)
- ✅ Interactive reader (tap-to-analyze with Perseus data)
- ✅ Text-to-speech (reconstructed Ancient Greek)
- ✅ Full gamification (XP, levels, streaks, achievements, skills, text stats)
- ✅ User auth & profiles
- ✅ BYOK (encrypted API key storage)
- ✅ Security middleware (rate limiting, CSRF, key redaction)

🚧 **In Development (2 features):**
- 🚧 Quests system (database ready, API endpoints needed)
- 🚧 SRS flashcards (database ready, API endpoints needed)

🚀 **Next Priorities:**
- 🚀 Classical Latin (next language)
- 🚀 Mobile app polish (iOS/Android native)
- 🚀 Community content contributions

**See:** [FEATURES.md](FEATURES.md) for detailed feature status matrix

---

## 🌍 Community

💬 [Discussions](https://github.com/antonsoo/AncientLanguages/discussions) — Questions, requests
🐛 [Issues](https://github.com/antonsoo/AncientLanguages/issues) — Bug reports
⭐ **Star** and **Watch** for updates

---

## 📄 License

**Code:** Elastic License 2.0 (ELv2) — [View full license](LICENSE.md)
**Data:** Original licenses (Perseus/LSJ: CC BY-SA, etc.)

The Elastic License 2.0 allows you to freely use, copy, distribute, and modify this software with three simple limitations:
- Cannot provide as a hosted/managed service
- Cannot circumvent license key functionality
- Must preserve copyright notices

[Full details →](docs/licensing-matrix.md)

---

## 🙏 Acknowledgments

- **Perseus Digital Library** — Digitized texts & morphological data
- **Liddell-Scott-Jones** — The definitive Greek dictionary
- **Smyth's Grammar** — Authoritative reference
- **Open source community** — Makes this possible

---

## 💝 Support This Project

**Loved using this app? Help keep it free and open source.**

**One-time donations:**
- [GitHub Sponsors](https://github.com/sponsors/antonsoo) (preferred)
- [Stripe](PLACEHOLDER_STRIPE) | [Ko-fi](PLACEHOLDER_KOFI) | [Liberapay](PLACEHOLDER_LIBERAPAY)

**Recurring support:**
- [Patreon](PLACEHOLDER_PATREON) (for early access to new languages)
- [Open Collective](PLACEHOLDER_OPENCOLLECTIVE) (transparent finances)

**Crypto:**
- BTC: `PLACEHOLDER_BTC`
- ETH: `PLACEHOLDER_ETH`
- XMR: `PLACEHOLDER_XMR`

[Learn more about supporting this project →](docs/SUPPORT.md)

**Your support helps us:**
- ✅ Add more languages (Latin, Hebrew, Egyptian)
- ✅ Improve AI models and exercises
- ✅ Keep the platform free and open source
- ✅ Preserve ancient languages for future generations

---

## 🤖 October 2025 APIs

⚠️ **Critical Information for Developers Contributing to AI Provider Code**

This repository uses **October 2025 API implementations** for all AI providers:

- **OpenAI GPT-5:** `/v1/responses` endpoint (NOT the older `/v1/chat/completions`)
  - Uses `max_output_tokens` (NOT `max_tokens`)
  - Uses `text.format` (NOT `response_format`)

- **Anthropic:** Claude 4.5 Sonnet, Claude 4.1 Opus (NOT Claude 3.x)

- **Google:** Gemini 2.5 Flash, Gemini 2.5 Pro (NOT Gemini 1.x)

**Before modifying ANY provider code:**
1. Read [AGENTS.md](AGENTS.md) — Agent autonomy boundaries
2. Read [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md) — Complete October 2025 API specs
3. Run validation: `python scripts/validate_october_2025_apis.py`
4. Test with real APIs: `python scripts/validate_api_versions.py`

**If your training data is from before October 2025, DO NOT "fix" code to older API versions.**

**Protected files:** See [.github/CODEOWNERS](.github/CODEOWNERS) for complete list of protected provider implementations.

---

<div align="center">

**Join us in preserving the languages of our ancestors.**

**Every ancient text you read is a conversation across millennia.**

[Start Learning](GETTING_STARTED.md) • [Start Developing](docs/DEVELOPMENT.md) • [Start Contributing](CONTRIBUTING.md)

---

**⭐ Star if you believe ancient languages should be accessible to everyone**

</div>
