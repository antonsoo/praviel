# Getting Started — Learn Ancient Greek in 5 Minutes

**Welcome!** You're about to start learning Ancient Greek through AI-powered lessons, conversational practice, and reading Homer's *Iliad* in the original. This guide will get you up and running in **5 minutes**, even if you have zero technical background.

![Getting Started](assets/screenshots/getting-started-hero.png)
*From zero to reading Homer in 5 minutes*

---

## 🎯 What You'll Accomplish

By the end of this guide, you'll:
- ✅ Have the app running on your computer
- ✅ Generate your first AI-powered lesson (alphabet, vocab, cloze, or translation)
- ✅ Practice conversational Greek with an AI historical persona
- ✅ Read the first lines of Homer's *Iliad* in Greek (with tap-to-analyze)
- ✅ Start earning XP, levels, and daily streaks (full gamification system)
- ✅ (Optional) Set up a free AI provider (Google Gemini has a generous free tier)

**No programming knowledge required. Just copy-paste a few commands.**

---

## 📋 What You'll Need

1. **A computer** (Windows, Mac, or Linux)
2. **Internet connection** (to download the app)
3. **15 minutes of your time** (5 for setup, 10 for exploration)
4. **Optional:** A free API key (Google Gemini has a generous free tier)

That's it!

---

## 🚀 Installation (Choose Your Platform)

**Currently available:** Local installation (full features)
**Coming soon:** Hosted web version (no install required)

Choose your platform below:

---

## Local Installation

### 🪟 For Windows Users

<details>
<summary><b>Click to expand Windows installation steps</b></summary>

#### **Step 1: Install Prerequisites**

Download and install these two programs (just click through the installers):

1. **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** — Database engine
   - Click "Download for Windows"
   - Run the installer
   - Restart your computer if prompted

2. **[Miniconda](https://docs.conda.io/en/latest/miniconda.html)** — Python environment
   - Download "Miniconda3 Windows 64-bit"
   - Run the installer
   - ✅ Check "Add Miniconda to PATH" during installation

---

#### **Step 2: Run the Setup Commands**

1. **Open PowerShell** (search "PowerShell" in Windows Start menu)

2. **Copy and paste these commands** one at a time:

```powershell
# Clone the repository
git clone https://github.com/antonsoo/AncientLanguages
cd AncientLanguages

# Start the database
docker compose up -d

# Create Python environment
conda create -y -n ancient python=3.12
conda activate ancient
pip install -e ".[dev]"

# Set up the database
python -m alembic -c alembic.ini upgrade head

# Start the server
uvicorn app.main:app --reload
```

**What's happening?**
- Line 1-2: Downloads the app
- Line 3: Starts the database
- Line 4-6: Sets up Python
- Line 7: Prepares the database
- Line 8: Launches the app

---

#### **Step 3: Open the App**

Once you see `Uvicorn running on http://127.0.0.1:8000`, open your browser and go to:

**http://localhost:8000**

🎉 **You're done!** Jump to [What to Do Next](#what-to-do-next)

---

**Need help?** See the detailed [Windows Setup Guide](docs/WINDOWS.md)

</details>

### 🍎 For Mac Users

<details>
<summary><b>Click to expand Mac installation steps</b></summary>

#### **Step 1: Install Prerequisites**

1. **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** — Database engine
   - Click "Download for Mac"
   - Drag Docker.app to Applications
   - Open Docker and wait for it to start

2. **[Miniconda](https://docs.conda.io/en/latest/miniconda.html)** — Python environment
   - Download "Miniconda3 macOS 64-bit pkg"
   - Run the installer

---

#### **Step 2: Run the Setup Commands**

1. **Open Terminal** (Cmd+Space, type "Terminal")

2. **Copy and paste these commands**:

```bash
# Clone the repository
git clone https://github.com/antonsoo/AncientLanguages
cd AncientLanguages

# Start the database
docker compose up -d

# Create Python environment
conda create -y -n ancient python=3.12
conda activate ancient
pip install -e ".[dev]"

# Set up the database
python -m alembic -c alembic.ini upgrade head

# Start the server
uvicorn app.main:app --reload
```

---

#### **Step 3: Open the App**

Once you see `Uvicorn running on http://127.0.0.1:8000`, open your browser:

**http://localhost:8000**

🎉 **You're done!** Jump to [What to Do Next](#what-to-do-next)

</details>

---

### 🐧 For Linux Users

<details>
<summary><b>Click to expand Linux installation steps</b></summary>

#### **Step 1: Install Prerequisites**

```bash
# Install Docker (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install docker.io docker-compose

# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

---

#### **Step 2: Run the Setup Commands**

```bash
# Clone the repository
git clone https://github.com/antonsoo/AncientLanguages
cd AncientLanguages

# Start the database
docker compose up -d

# Create Python environment
conda create -y -n ancient python=3.12
conda activate ancient
pip install -e ".[dev]"

# Set up the database
python -m alembic -c alembic.ini upgrade head

# Start the server
uvicorn app.main:app --reload
```

---

#### **Step 3: Open the App**

**http://localhost:8000**

🎉 **You're done!** Jump to [What to Do Next](#what-to-do-next)

</details>

---

## 🔑 Optional: Enable AI Features (Recommended)

The app works offline with the built-in "echo" provider, but **AI-powered lessons and chat are way better!**

### Get a Free API Key (Google Gemini — Recommended)

**Why?** Google Gemini 2.5 Flash has a **generous free tier** — enough for daily learning without paying anything.

<details>
<summary><b>Click for step-by-step instructions</b></summary>

#### **Step 1: Get Your Free API Key**

1. Go to **[Google AI Studio](https://aistudio.google.com/app/apikey)**
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Copy the key (looks like: `AIza...`)

---

#### **Step 2: Add the Key to Your App**

**Windows:**
```powershell
# Navigate to the backend folder
cd backend

# Copy the example .env file
copy .env.example .env

# Open .env in Notepad
notepad .env

# Add these lines:
GOOGLE_API_KEY=AIza...your-key-here...
LESSONS_ENABLED=1

# Save and close Notepad
# Restart the server (Ctrl+C in PowerShell, then run uvicorn again)
```

**Mac/Linux:**
```bash
# Navigate to the backend folder
cd backend

# Copy the example .env file
cp .env.example .env

# Edit with nano (or your favorite editor)
nano .env

# Add these lines:
GOOGLE_API_KEY=AIza...your-key-here...
LESSONS_ENABLED=1

# Save (Ctrl+X, Y, Enter)
# Restart the server (Ctrl+C, then run uvicorn again)
```

---

#### **Step 3: Restart the Server**

Press `Ctrl+C` in your terminal, then run:
```bash
uvicorn app.main:app --reload
```

🎉 **AI lessons and chat are now enabled!**

</details>

---

### Other AI Providers (Optional)

**Google Gemini (recommended):**
- ✅ Generous free tier
- ✅ Fast responses
- ✅ Great quality

**OpenAI GPT-5:**
- 💰 ~$0.01-0.05 per lesson (pay-as-you-go)
- ✅ Best quality
- ✅ Most natural responses

**Anthropic Claude 4.5:**
- 💰 Pay-as-you-go
- ✅ Great for detailed explanations
- ✅ Good at grammar help

**Offline "echo" provider:**
- ✅ Completely free
- ✅ No API key required
- ⚠️ No AI — just echoes back sample data

See the **[BYOK Guide](docs/BYOK.md)** for full setup instructions.

---

## 🎉 What to Do Next

You're all set! Here's how to explore the app:

### 1️⃣ **Generate Your First Lesson** — AI-Powered Learning

![Lesson Demo](assets/screenshots/lesson-generation.png)

1. Open the **Lessons** tab
2. Click **"Generate Lesson"**
3. Choose exercise types:
   - **Alphabet:** Practice Greek letters (perfect for absolute beginners)
   - **Match:** Pair Greek words with English meanings (build vocabulary)
   - **Cloze:** Fill-in-the-blank from *Iliad* passages (context-based learning)
   - **Translate:** Translate Greek ↔ English (active production)

4. Complete the exercises and earn **XP + streak points!**

**Tip:** Start with Alphabet if you're brand new to Greek, or Match if you can already read the script!

---

### 2️⃣ **Try Chat Mode** — Converse in Ancient Greek

![Chat Demo](assets/screenshots/chat-interface.png)

1. Open the **Chat** tab
2. Select a persona:
   - **Athenian merchant (400 BCE):** Marketplace Greek, everyday conversations
   - **Spartan warrior:** Military discipline and honor
   - **Athenian philosopher:** Socratic dialogue style
   - **Roman senator:** Latin with Greek code-switching
3. Type a message in Greek (or ask for help in English)
4. Get responses in conversational Greek with grammar explanations

**Try it now:** Type "χαῖρε" (hello) and see what the merchant says back!

---

### 3️⃣ **Read Homer's Iliad** — Interactive Text Analysis

![Reader Demo](assets/screenshots/reader-tap-analysis.png)

1. Open the **Reader** tab
2. See the first 10 lines of Homer's *Iliad* in Ancient Greek
3. **Tap any word** (e.g., "Μῆνιν" or "θεά") to see:
   - **Lemma** (dictionary form)
   - **Morphology** (case, number, gender, tense, voice, mood)
   - **LSJ dictionary definition** (with source citation from Liddell-Scott-Jones)
   - **Smyth grammar reference** (relevant section numbers)

**Try it now:** Tap "Μῆνιν" (the first word) — it means "wrath" and is the theme of the entire *Iliad*!

---

### 4️⃣ **Track Your Progress** — XP, Streaks, Achievements

1. Open the **Progress** tab
2. See your:
   - **Daily streak** (consecutive days using the app)
   - **Total XP** (experience points from lessons)
   - **Current level** (beginner → intermediate → advanced)
   - **Recent lessons** (review what you've practiced)

**Gamification tip:** Come back every day to maintain your streak!

---

## 📚 Suggested Learning Path

**Everyone learns at their own pace — this is just a guide!**

### 🌱 **Week 1-2: The Alphabet** (Absolute Beginner)

**Goal:** Recognize and pronounce all 24 Greek letters

**Activities:**
- ✅ Generate **Alphabet lessons** daily (5-10 minutes)
- ✅ Read *Iliad* 1.1 in the Reader (tap every word to hear it)
- ✅ Don't worry about grammar yet — just get familiar with the script

**Milestone:** Can recognize all Greek letters and pronounce simple words

---

### 🌿 **Week 3-4: First Words** (Beginner)

**Goal:** Build a vocabulary of 50-100 common Greek words

**Activities:**
- ✅ Generate **Match lessons** from *Iliad* 1.1-1.10
- ✅ Read *Iliad* 1.1-1.5 daily, tapping unfamiliar words
- ✅ Start noticing patterns (e.g., word endings)

**Milestone:** Can recognize 50+ Greek words on sight

---

### 🌳 **Month 2-3: Grammar Basics** (Intermediate)

**Goal:** Understand basic Greek grammar (cases, verb conjugations)

**Activities:**
- ✅ Generate **Cloze lessons** (fill-in-the-blank from *Iliad* passages)
- ✅ Read *Iliad* 1.1-1.10, paying attention to word endings
- ✅ Use **Chat mode** to ask grammar questions in English
- ✅ Check Smyth grammar references when tapping words

**Milestone:** Can identify cases (nominative, accusative, genitive) and basic verb forms

---

### 🏛️ **Month 4+: Reading Fluency** (Advanced)

**Goal:** Read longer passages with minimal dictionary lookups

**Activities:**
- ✅ Generate **Translation lessons** (Greek → English and vice versa)
- ✅ Read entire *Iliad* passages (10+ lines at a time)
- ✅ Practice **Chat mode** conversations in Greek
- ✅ Review less frequently — trust your growing knowledge

**Milestone:** Can read a full *Iliad* passage and understand the gist without looking up every word

---

### 🎓 **Long-term Goal**

**Read all of *Iliad* Book 1 in Greek** — understanding the story, wordplay, and cultural references that translations miss.

**Remember:** Ancient language learning is a **marathon, not a sprint**. Even 5-10 minutes daily adds up over time!

---

## Common Questions

### Do I need to know programming?

**No.** The installation steps look technical, but they're just copy-paste commands. If you can use a web browser, you can use this app.

### Is this really free?

**Yes.** The app is open source and free forever. You can:
- Use the offline "echo" provider (no cost)
- Use Google Gemini free tier (generous daily limits)
- Pay-as-you-go with OpenAI/Anthropic (pennies per lesson)

No subscriptions, no hidden fees.

### How is this different from Duolingo?

**This app IS like Duolingo (gamification, streaks, AI lessons)—but for ancient languages and with academic rigor:**

| Feature | Duolingo | Ancient Languages |
|---------|----------|-------------------|
| **Gamification** | ✅ XP, streaks, levels | ✅ XP, streaks, levels, achievements, skills (ELO) |
| **AI Lessons** | ✅ Adaptive exercises | ✅ 4 exercise types (alphabet, match, cloze, translate) |
| **Content** | Simplified phrases ("The apple is red") | **Real ancient texts** (Homer's *Iliad*) |
| **Accuracy** | Good for modern languages | **Research-grade** (Perseus, LSJ, Smyth) |
| **Conversational** | Chatbot practice | ✅ **Historical personas** (Athenian merchant, Spartan warrior) |
| **Pronunciation** | ✅ TTS | ✅ **Reconstructed Ancient Greek** TTS |
| **Privacy** | Subscription, data collection | **BYOK** (your API keys, your data) |
| **Spaced Repetition** | Built-in | 🚧 **FSRS algorithm** (coming soon) |

**TL;DR:** You get Duolingo's addictive UX, but you're reading Homer instead of "The cat is on the table."

### Can I use this on my phone?

**Yes.** The Flutter mobile app is in development. For now, use the web version on mobile browsers (works reasonably well).

### What if I get stuck?

- **Discussions:** [GitHub Discussions](https://github.com/antonsoo/AncientLanguages/discussions) for questions
- **Issues:** [GitHub Issues](https://github.com/antonsoo/AncientLanguages/issues) for bugs
- **Documentation:** [docs/](docs/) for detailed guides

---

## Next Steps

- **Learn the vision:** [BIG-PICTURE_PROJECT_PLAN.md](BIG-PICTURE_PROJECT_PLAN.md)
- **Contribute:** [CONTRIBUTING.md](CONTRIBUTING.md)
- **Vote for languages:** [GitHub Discussions](https://github.com/antonsoo/AncientLanguages/discussions)

---

**Ready to unlock the original words of Homer?**
**Every ancient text you read is a conversation across millennia.**
