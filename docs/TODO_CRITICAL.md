# Critical TODOs - The Real Mission

**Last updated:** 2025-10-11 (After research into gamification, narrative pedagogy, and Gen Z engagement)

## 🎯 THE REAL MISSION

**This isn't about teaching languages. It's about uplifting humanity.**

We're using ancient languages as a **Trojan horse** to inject philosophy, theology, history, and great literature into minds that hate learning. Our goal: make someone who **absolutely hates studying** look at this app and get **excited** to use it.

**Target:** The dopamine-addicted zoomer scrolling TikTok. We need to be MORE addictive than social media, but **trick them into studying Plato, Homer, and the Vedas.**

---

## ✅ WHAT'S ALREADY DONE

### Backend Infrastructure ✅
- ✅ Backend lesson generation working for 4 languages × 18 exercise types
- ✅ Backend audio caching with deterministic hashing ([audio_cache.py](../backend/app/lesson/audio_cache.py))
- ✅ Static audio serving at `/audio/` endpoint
- ✅ Multi-provider AI support (GPT-5, Claude 4.5, Gemini 2.5)
- ✅ Content expansion: Cloze/translate/grammar 2-3x per language (commits a7568c5, add412f)

### Frontend Infrastructure ✅
- ✅ Flutter audio integration complete (commit b49bf13)
  - [vibrant_listening_exercise.dart:37](../client/flutter_reader/lib/widgets/exercises/vibrant_listening_exercise.dart#L37) has AudioPlayer
  - [vibrant_dictation_exercise.dart:29](../client/flutter_reader/lib/widgets/exercises/vibrant_dictation_exercise.dart#L29) has AudioPlayer
  - [vibrant_lessons_page.dart:157](../client/flutter_reader/lib/pages/vibrant_lessons_page.dart#L157) sets `includeAudio: true`
- ✅ 18 exercise widgets built (match, cloze, translate, grammar, listening, dictation, speaking, wordbank, truefalse, multiplechoice, dialogue, synonym, contextmatch, reorder, alphabet, conjugation, declension, etymology)

### What's Missing: **THE SOUL OF THE APP**
The infrastructure exists, but it's **boring**. It's just another language app. We need to make it **irresistible**.

---

## 🚨 PRIORITY 1: MAKE IT ADDICTIVE (Dopamine Engineering)

**Research insight:** Duolingo increased DAU by 350% using streaks, social competition, and dopamine triggers. Gen Z attention span is 8 seconds. We need **microlearning** (< 10 min lessons), **instant rewards**, and **gamification that hijacks the dopamine system**.

### A. Streak System (HIGH PRIORITY - Week 1)
**Status:** ❌ NOT IMPLEMENTED
**Research:** Users who maintain 7-day streak are 3.6x more likely to stay engaged long-term. Streak Freeze feature reduced churn by 21%.

**What to build:**
- [ ] Daily streak counter with fire emoji 🔥
- [ ] Streak freeze power-up (save your streak if you miss a day)
- [ ] Streak milestones with celebrations (7 days, 30 days, 100 days, 365 days)
- [ ] Visual streak calendar showing your history
- [ ] Push notifications: "Don't lose your 47-day streak!" (loss aversion psychology)
- [ ] Streak repair feature (watch ad or complete double lesson to restore broken streak)

**Database schema needed:**
```sql
ALTER TABLE users ADD COLUMN current_streak INT DEFAULT 0;
ALTER TABLE users ADD COLUMN longest_streak INT DEFAULT 0;
ALTER TABLE users ADD COLUMN last_activity_date DATE;
ALTER TABLE users ADD COLUMN streak_freezes_remaining INT DEFAULT 2;
```

**UI mockup:**
- Home screen: Giant flame icon with number
- Tap streak to see calendar heatmap (GitHub-style contribution graph)
- Animation when completing daily lesson (confetti + flame grows bigger)

---

### B. XP & Leveling System Enhancement (HIGH PRIORITY - Week 1)
**Status:** ⚠️ PARTIALLY IMPLEMENTED (backend exists, needs frontend overhaul)
**Research:** Gamification increases engagement by 100-150%. Visual markers of progress keep users motivated.

**What to enhance:**
- [ ] **Visual level-up animations** with screen-wide celebration
- [ ] **Progress bar** showing XP until next level (always visible)
- [ ] **Level titles** with prestige:
  - Level 1-5: "Novice Scholar"
  - Level 6-10: "Apprentice Linguist"
  - Level 11-20: "Scholar of the Ancients"
  - Level 21-30: "Master of Dead Tongues"
  - Level 31-50: "Keeper of Ancient Wisdom"
  - Level 51+: "Living Library" / "Immortal Sage"
- [ ] **Unlock new features at levels:**
  - Level 5: Unlock harder exercise types
  - Level 10: Unlock chat with historical personas
  - Level 15: Unlock story mode (see below)
  - Level 20: Unlock advanced texts (original Homer, Plato)
- [ ] **XP sources diversified:**
  - Complete lesson: 10-50 XP (based on difficulty)
  - Perfect score: +25 XP bonus
  - Maintain streak: +10 XP per day
  - Complete story chapter: 100 XP
  - Unlock achievement: 50-500 XP

**UI:**
- Large progress bar at top of home screen
- Level badge next to profile picture
- XP gain animation after every correct answer (+5 XP floats up)

---

### C. Leaderboards & Social Competition (MEDIUM PRIORITY - Week 2)
**Status:** ❌ NOT IMPLEMENTED
**Research:** Social competition drove Duolingo's growth to multi-billion business. Gen Z is hyper-competitive.

**What to build:**
- [ ] Weekly leaderboard (top 50 users by XP this week)
- [ ] Friends list (follow other learners)
- [ ] "Friend leaderboard" (compare with friends only)
- [ ] Challenge friends to XP battles
- [ ] Global rank display ("You're #1,847 out of 125,000 learners")
- [ ] League system (Bronze → Silver → Gold → Diamond → Legendary)
  - Promotion/demotion each week based on performance
  - Top 10 in league get promoted, bottom 5 demoted

**Backend API needed:**
```python
GET /leaderboard/weekly?limit=50
GET /leaderboard/friends
GET /user/{id}/rank
POST /friends/{id}/challenge
```

---

### D. Achievement System (MEDIUM PRIORITY - Week 2)
**Status:** ⚠️ EXISTS but needs 10x more achievements
**Research:** Achievements create "collection motivation" - users want to complete the set.

**Achievement categories to add:**
- [ ] **Streak achievements:** 7, 30, 100, 365, 1000 day streaks
- [ ] **Lesson achievements:** Complete 10, 50, 100, 500, 1000 lessons
- [ ] **Perfect score achievements:** 10, 50, 100 perfect lessons
- [ ] **Language achievements:** Unlock all 4 languages, reach level 10 in each
- [ ] **Text achievements:** Read 100, 1000, 10000 words in original texts
- [ ] **Philosophical achievements:** Complete Plato story arc, complete Homer story arc
- [ ] **Speed achievements:** Complete lesson in under 2 minutes
- [ ] **Consistency achievements:** Practice every day for a week/month
- [ ] **Social achievements:** Challenge 10 friends, win 50 XP battles
- [ ] **Rare achievements:** "Night Owl" (complete lesson at 3am), "Early Bird" (complete lesson at 6am)

**UI:**
- Achievement showcase page (grid of locked/unlocked badges)
- Rarity indicators (Common, Rare, Epic, Legendary)
- Progress bars for incomplete achievements

---

## 🚨 PRIORITY 2: STORY MODE (Narrative Pedagogy)

**Research insight:** Story-driven learning improves concept mastery, creativity, and empathy. Digital storytelling significantly improves speaking proficiency, fluency, vocabulary, and reduces anxiety.

**THIS IS THE KILLER FEATURE.** Instead of random exercises, users follow **narrative arcs** that teach philosophy, history, and theology through interactive stories.

### Story Mode Architecture (HIGH PRIORITY - Week 3-4)

**Concept:** Each language has 3-5 **story arcs** (10-20 chapters each). Each chapter teaches vocabulary/grammar through a compelling narrative.

**Example Story Arc: "The Delphic Quest" (Greek)**
- **Chapter 1:** You're a young Athenian traveling to Delphi to consult the Oracle
- **Chapter 2:** Meet a mysterious stranger who quotes Heraclitus: "πάντα ῥεῖ" (everything flows)
- **Chapter 3:** Arrive at Delphi, see the inscription "Γνῶθι σεαυτόν" (Know thyself)
- **Chapter 4:** The Oracle speaks in riddles - you must translate them
- **Chapter 5:** Philosophy debate with a Stoic in the marketplace
- **Chapter 6-10:** Journey continues, each chapter introduces new philosophical concept
- **Final chapter:** Return home transformed, understanding the wisdom of the ancients

**Example Story Arc: "The Scribe's Apprentice" (Egyptian)**
- Learn hieroglyphics while helping a scribe in the Old Kingdom
- Uncover a mystery in the Pyramid Texts
- Meet pharaohs, priests, and learn Egyptian cosmology

**Example Story Arc: "The Vedic Seeker" (Sanskrit)**
- Journey with a student learning from Vedic teachers
- Learn about karma, dharma, meditation through interactive dialogues
- Culminates in reading actual Upanishads

**Backend schema:**
```sql
CREATE TABLE story_arcs (
  id SERIAL PRIMARY KEY,
  language_code VARCHAR(10),
  title VARCHAR(255),
  description TEXT,
  unlock_level INT,
  chapters_count INT
);

CREATE TABLE story_chapters (
  id SERIAL PRIMARY KEY,
  arc_id INT REFERENCES story_arcs(id),
  chapter_number INT,
  title VARCHAR(255),
  narrative_text TEXT, -- The story text
  vocabulary_focus TEXT[], -- Words to learn this chapter
  grammar_focus VARCHAR(255), -- Grammar concept
  exercises JSONB -- Embedded exercises in narrative
);

CREATE TABLE user_story_progress (
  user_id INT,
  arc_id INT,
  chapter_id INT,
  completed BOOLEAN,
  stars_earned INT, -- 0-3 stars based on performance
  PRIMARY KEY (user_id, chapter_id)
);
```

**UI:**
- Story map showing locked/unlocked chapters (visual journey)
- Beautiful illustrations for each story arc (AI-generated or sourced)
- Narrative text with embedded exercises (not separate screens)
- Character dialogue with voice acting (TTS with emotion)
- Choice-based branching (some chapters have multiple paths)

**Content creation workflow:**
1. Write story arc outline (philosophical/historical theme)
2. Break into chapters with vocabulary/grammar targets
3. Generate narrative text with embedded exercises
4. Add voice acting (TTS or real recordings)
5. Create chapter illustrations

---

## 🚨 PRIORITY 3: VISUAL RICHNESS (Images & Multimedia)

**Research insight:** Gen Z expects rich multimedia. Storytelling works best with multimodal scaffolding (text + images + audio).

### A. Image Integration (MEDIUM PRIORITY - Week 3)
**Status:** ❌ NOT IMPLEMENTED

**What to add:**
- [ ] **Vocabulary images:** Every noun/adjective has an accompanying image
  - Database: `vocabulary_images` table with URLs to local image cache
  - API: `/vocab/{word}/image` returns image URL
  - UI: Flash cards show word + image
- [ ] **Historical context images:** Lessons about "ἀγορά" (agora) show actual agora photos
- [ ] **Story arc illustrations:** Each story chapter has 3-5 narrative illustrations
- [ ] **Achievement badge art:** Each achievement has unique custom artwork
- [ ] **Cultural context gallery:** Browse images of ancient artifacts, architecture, art

**Image sources:**
- Public domain: Wikimedia Commons, Metropolitan Museum API, British Museum API
- AI-generated: Stable Diffusion for story illustrations
- Local cache: Store images locally to avoid API calls

**Backend:**
```python
# backend/app/media/image_service.py
async def get_vocabulary_image(word: str, language: str) -> str:
    """Fetch or generate image for vocabulary word"""
    # Check local cache first
    # Fall back to Wikimedia Commons API
    # Fall back to AI generation
```

---

### B. Native Voice Samples (HIGH PRIORITY - Week 2)
**Status:** ⚠️ TTS exists, but needs **native speaker recordings**

**Problem:** TTS sounds robotic. Users want to hear **real human pronunciation**.

**Solution:**
- [ ] Record native speakers for top 500 words per language
- [ ] Partner with classics departments to get Latin/Greek pronunciation recordings
- [ ] Use existing audio archives (Librivox for Homer, public domain recordings)
- [ ] Fallback to TTS for less common words

**Sources:**
- Classical Greek: Oxford Classical Greek course audio, Polis Institute
- Latin: Latinitium podcast, Luke Ranieri recordings
- Hebrew: Biblical Hebrew recordings from universities
- Sanskrit: Vedic chanting recordings (public domain)

**Implementation:**
```python
# backend/app/lesson/audio_cache.py
async def get_audio_url(text: str, language: str) -> str:
    # Priority 1: Check for native recording
    native_url = await get_native_recording(text, language)
    if native_url:
        return native_url
    # Priority 2: Generate TTS and cache
    return await generate_tts(text, language)
```

---

## 🚨 PRIORITY 4: PHILOSOPHICAL CONTENT INJECTION

**THIS IS YOUR SECRET WEAPON.** Users think they're learning language, but they're actually studying philosophy, theology, and history.

### A. Philosophy Integration (HIGH PRIORITY - Week 4)
**Status:** ❌ NOT IMPLEMENTED

**Concept:** Every 5th lesson includes a **philosophical insight** disguised as language practice.

**Examples:**
- **Greek lesson on "ἀρετή" (virtue):** Exercises use quotes from Aristotle's *Nicomachean Ethics*
- **Latin lesson on "virtus":** Translate Cicero's *De Officiis*
- **Sanskrit lesson on "dharma":** Learn from *Bhagavad Gita*
- **Hebrew lesson on "hesed":** Study Psalms and prophets

**Implementation:**
- [ ] Tag lessons with philosophical themes
- [ ] Create "Philosophy Flash" pop-ups after completing exercises:
  - "Did you know? Socrates said 'γνῶθι σεαυτόν' (know thyself). Tap to learn more."
  - Mini-essay appears with historical context
- [ ] "Wisdom of the Day" feature on home screen
- [ ] Philosophy achievement tree (unlock deeper topics as you progress)

**Backend:**
```sql
CREATE TABLE philosophical_insights (
  id SERIAL PRIMARY KEY,
  language_code VARCHAR(10),
  theme VARCHAR(255), -- e.g., "virtue", "justice", "dharma"
  quote_original TEXT,
  quote_translation TEXT,
  author VARCHAR(255),
  source TEXT,
  explanation TEXT
);
```

---

### B. Historical Context Pop-ups (MEDIUM PRIORITY - Week 4)
**Status:** ❌ NOT IMPLEMENTED

**Concept:** When learning vocabulary, show **why this word matters historically**.

**Example:**
- User learns Greek word "δημοκρατία" (democracy)
- Pop-up appears: "This word was coined in 5th century BCE Athens. The Athenian assembly met on Pnyx hill. Tap to see a photo."
- Shows image of Pnyx, short description
- Links to related story: "Want to experience an Athenian assembly? Start the 'Citizen of Athens' story arc!"

---

## 🚨 PRIORITY 5: UI POLISH (Make it FEEL Premium)

**Research insight:** Gen Z expects smooth animations, instant feedback, mobile-first design.

### A. Loading States & Animations (HIGH PRIORITY - Week 1)
**Status:** ❌ MISSING

**What to add:**
- [ ] Loading spinners during API calls (Lottie animations, not boring circles)
- [ ] Skeleton screens while loading lessons
- [ ] Smooth page transitions (AnimatedSwitcher)
- [ ] Micro-interactions:
  - Button press animations (scale down slightly)
  - Correct answer: green check mark + confetti
  - Wrong answer: red X + shake animation
  - Streak maintained: flame grows bigger
  - Level up: full-screen celebration with particles

**Use:**
- `flutter_animate` package for easy animations
- `lottie` package for JSON animations
- `confetti` package for celebrations

---

### B. Error Recovery (MEDIUM PRIORITY - Week 2)
**Status:** ❌ CRASHES show error text, no retry button

**What to add:**
- [ ] Error screens with retry buttons
- [ ] Offline mode detection
- [ ] Graceful degradation (use cached lessons if API fails)
- [ ] Friendly error messages: "Oops! The ancient gods are angry. Tap to try again."

---

### C. Onboarding Experience (HIGH PRIORITY - Week 1)
**Status:** ❌ NOT IMPLEMENTED

**Problem:** New users are confused. They need guided introduction.

**Solution:**
- [ ] Beautiful welcome screen with app mission statement
- [ ] 3-screen tutorial:
  - Screen 1: "Learn ancient languages, unlock ancient wisdom"
  - Screen 2: "Earn XP, maintain streaks, compete with friends"
  - Screen 3: "Choose your first language and begin your journey"
- [ ] Forced first lesson (tutorial lesson that's impossible to fail)
- [ ] Celebration after first lesson: "You earned your first 10 XP! 🎉"

---

## 🚨 PRIORITY 6: MANUAL TESTING (Week 5)

**Only AFTER the above features are built, then test manually:**
- [ ] Launch Flutter app with real backend
- [ ] Test all 18 exercise types
- [ ] Test audio playback
- [ ] Test streak system
- [ ] Test XP/leveling
- [ ] Test story mode
- [ ] Test on real device (Android + iOS)

---

## 📊 SUCCESS METRICS

**We'll know we've succeeded when:**
- Average session length > 15 minutes (currently ~5 min)
- 7-day retention > 40% (Duolingo is ~25%)
- Users complete at least 1 story arc (engagement beyond exercises)
- User reviews mention "didn't expect to love philosophy" or "learned more than just language"

---

## 🎯 DEVELOPMENT ROADMAP

### Week 1: Dopamine Foundation
- Streak system
- XP/leveling enhancements
- Loading animations
- Onboarding

### Week 2: Social & Audio
- Leaderboards
- Achievement expansion
- Native voice samples
- Error recovery

### Week 3: Visual Richness
- Image integration
- Story mode infrastructure
- Illustrations for first story arc

### Week 4: Content Depth
- Write first complete story arc (Greek: "The Delphic Quest")
- Philosophy integration
- Historical context pop-ups

### Week 5: Testing & Polish
- Manual testing
- Bug fixes
- Performance optimization
- Beta launch

---

## ❌ DON'T DO (Time Wasters)

- ❌ Write more docs or reports
- ❌ Refactor working code unnecessarily
- ❌ Add backend features before frontend can use them
- ❌ Implement features users won't notice (internal metrics, admin dashboards)

---

## 🎉 THE END GOAL

**A dopamine-addicted Gen Z kid picks up this app.**

They expect to quit in 5 minutes. But:
- The streak system hooks them ("just one more day...")
- The story mode intrigues them ("wait, what happens next?")
- The XP system drives them ("I'm so close to level 10!")
- The leaderboard challenges them ("I can beat my friend!")
- The images delight them (beautiful, not boring)
- The philosophy surprises them ("holy shit, Plato was right")

**Three months later, they've read the Iliad in Greek and can't stop talking about Stoicism.**

**That's when we've won.**
