# Text-to-Speech (TTS) API

**API Contract:** `/tts/synthesize` endpoint for generating audio from ancient language text.

This document describes the API for text-to-speech synthesis of ancient languages using OpenAI, Google, or offline providers.

---

## Endpoint

**POST** `/tts/synthesize`

Convert ancient language text to audio (reconstructed pronunciation).

---

## Request Format

### Basic Request

```json
{
  "text": "Μῆνιν ἄειδε θεά",
  "language": "grc",
  "provider": "google"
}
```

### Full Request (All Options)

```json
{
  "text": "Μῆνιν ἄειδε θεά, Πηληϊάδεω Ἀχιλῆος",
  "language": "grc",
  "provider": "openai",
  "voice": "alloy",
  "speed": 1.0,
  "format": "mp3"
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | string | ✅ | Text to synthesize (in ancient language) |
| `language` | string | ✅ | Language code (`grc`, `lat`, `san`, `heb`) |
| `provider` | string | ✅ | TTS provider (`openai`, `google`, `echo`) |
| `voice` | string | ❌ | Voice ID (provider-specific) |
| `speed` | float | ❌ | Playback speed (0.25-4.0, default: 1.0) |
| `format` | string | ❌ | Audio format (`mp3`, `opus`, `aac`, `flac`) |

---

## Response Format

### Success Response (200 OK)

**Content-Type:** `audio/mpeg` (or specified format)

Returns raw audio bytes.

**Headers:**
```
Content-Type: audio/mpeg
Content-Length: 12345
X-Audio-Duration: 3.5
```

### Error Response (400 Bad Request)

```json
{
  "error": "Invalid language",
  "detail": "Language 'xyz' is not supported for TTS. Supported languages: grc, lat, san, heb"
}
```

### Error Response (401 Unauthorized)

```json
{
  "error": "API key required",
  "detail": "OpenAI API key not configured. Add OPENAI_API_KEY to .env or use 'google' provider."
}
```

---

## Provider Configuration

### OpenAI TTS

**Models:** `tts-1`, `tts-1-hd`

**Voices:**
- `alloy` — Neutral, balanced
- `echo` — Male, clear
- `fable` — British accent
- `onyx` — Deep male
- `nova` — Female, warm
- `shimmer` — Female, bright

**Required:**
- `OPENAI_API_KEY` environment variable

**Cost:** ~$0.015 per 1,000 characters (tts-1)

**Formats:** `mp3`, `opus`, `aac`, `flac`

```bash
# .env
OPENAI_API_KEY=sk-your-key-here
```

### Google TTS

**Models:** `google-tts`

**Voices:**
- Auto-selected based on language

**Required:**
- `GOOGLE_API_KEY` environment variable

**Cost:** FREE (generous free tier)

**Formats:** `mp3`, `ogg`

```bash
# .env
GOOGLE_API_KEY=AIza-your-key-here
```

### Echo (Offline)

**Model:** Local fallback (no TTS)

**Required:** None

**Cost:** FREE

**Returns:** HTTP 501 Not Implemented (no audio)

**Use for:** Testing without API keys

---

## Language Support

| Language | Code | Status | Pronunciation |
|----------|------|--------|---------------|
| Classical Greek | `grc` | ✅ | Reconstructed Ancient Greek (not Modern Greek) |
| Classical Latin | `lat` | ✅ | Classical Latin (not Ecclesiastical) |
| Classical Sanskrit | `san` | ✅ (Beta) | Vedic/Classical Sanskrit |
| Biblical Hebrew | `heb` | ✅ (Beta) | Biblical Hebrew |

**Note:** Modern TTS models don't natively support ancient pronunciation. The app uses:
1. **Transliteration** — Convert ancient script to Latin/IPA
2. **Pronunciation guides** — Apply reconstructed pronunciation rules
3. **Synthesis** — Use modern TTS with closest language approximation

**Result:** Approximation of ancient pronunciation (not guaranteed scholarly accuracy).

---

## Pronunciation Notes

### Classical Greek

**Erasmian pronunciation** (most common reconstruction):
- β = [b] (not [v])
- γ = [g] (not [ɣ])
- δ = [d] (not [ð])
- η = [ɛː] (long "e")
- ω = [ɔː] (long "o")

**Pitch accent** (not stress accent):
- ά = high pitch (not louder)
- ᾶ = rising pitch

**Modern TTS approximation:**
- Uses closest Latin/English phonemes
- May not perfectly reproduce pitch accent

### Classical Latin

**Classical pronunciation** (not Ecclesiastical):
- c = [k] (never [s])
- v = [w] (not [v])
- ae = [ai̯] (diphthong)
- Long vs. short vowels distinguished

### Sanskrit

**Devanagari transliteration** (IAST):
- ṣ, ś, s = different sibilants
- ṛ = vocalic r
- Aspiration and retroflexion preserved

### Biblical Hebrew

**Tiberian pronunciation**:
- א = glottal stop
- ע = pharyngeal fricative
- ח = voiceless pharyngeal fricative
- Dagesh and shva preserved

---

## Examples

### Synthesize Greek Text (OpenAI)

```bash
curl -X POST http://localhost:8000/tts/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Μῆνιν ἄειδε θεά",
    "language": "grc",
    "provider": "openai",
    "voice": "alloy"
  }' \
  --output iliad_1_1.mp3
```

### Synthesize Latin Text (Google, Free)

```bash
curl -X POST http://localhost:8000/tts/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Arma virumque cano",
    "language": "lat",
    "provider": "google"
  }' \
  --output aeneid_1_1.mp3
```

### Slow Down Playback (For Learning)

```bash
curl -X POST http://localhost:8000/tts/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Μῆνιν ἄειδε θεά",
    "language": "grc",
    "provider": "openai",
    "speed": 0.75
  }' \
  --output iliad_slow.mp3
```

---

## Implementation Details

**Backend:** `backend/app/tts/providers/`

**Provider implementations:**
- `openai.py` — OpenAI TTS-1, TTS-1-HD
- `google.py` — Google Cloud TTS
- `echo.py` — Offline fallback (returns 501)

**Database:** Not applicable (stateless)

**Tests:** `tests/test_tts.py`

**Smoke tests:** `scripts/dev/smoke_tts.ps1` (Windows) / `smoke_tts.sh` (Unix)

---

## Rate Limits

| Provider | Rate Limit | Notes |
|----------|------------|-------|
| OpenAI | 50 requests/minute | Default tier |
| Google | 60 requests/minute | Free tier |
| Echo | Unlimited | Local only (no synthesis) |

---

## Cost Estimates

**Typical usage (30 min/day, ~500 characters per session):**

| Provider | Model | Cost per Session | Monthly Cost |
|----------|-------|------------------|--------------|
| **Google** | google-tts | **FREE** | $0 |
| **OpenAI** | tts-1 | ~$0.0075 | ~$0.23/month |
| **OpenAI** | tts-1-hd | ~$0.03 | ~$0.90/month |
| **Echo** | N/A | **FREE** | $0 |

---

## Validation

**Before deploying changes to TTS providers:**

```bash
# Smoke test real TTS APIs
scripts/dev/smoke_tts.ps1  # Windows
scripts/dev/smoke_tts.sh   # Unix
```

---

## Caching

**TTS responses are cacheable.**

**Recommended caching strategy:**
1. Hash text + language + voice + speed
2. Store audio file with hash as filename
3. Return cached file if exists
4. Otherwise, synthesize and cache

**Example cache key:**
```
sha256("Μῆνιν ἄειδε θεά|grc|alloy|1.0") = abc123...
```

**Cache location:**
```
backend/cache/tts/abc123.mp3
```

**Benefits:**
- Reduce API costs
- Faster response times
- Works offline after initial synthesis

---

## Accessibility

**TTS is essential for:**
- Pronunciation learning
- Auditory learners
- Visually impaired users
- Reinforcing spoken fluency

**Recommended usage:**
- Slow speed (0.75x) for beginners
- Repeat audio multiple times
- Shadow speaking (repeat after audio)
- Compare your pronunciation with TTS

---

## Limitations

**TTS for ancient languages is an approximation:**
- Modern TTS models don't natively support ancient pronunciation
- Reconstructed pronunciation is scholarly consensus (not guaranteed accurate)
- Pitch accent (Greek) may not be perfectly rendered
- Some phonemes have no modern equivalent

**For scholarly accuracy:**
- Consult academic pronunciation guides
- Listen to recordings by classicists
- Use TTS as a learning aid, not authoritative source

---

## Related Documentation

- [docs/API_REFERENCE.md](API_REFERENCE.md) — Full API documentation
- [docs/LESSONS.md](LESSONS.md) — AI lesson generation API
- [docs/COACH.md](COACH.md) — Conversational chat API
- [docs/BYOK.md](BYOK.md) — API key setup

---

## Need Help?

- 💬 [GitHub Discussions](https://github.com/antonsoo/praviel/discussions)
- 🐛 [GitHub Issues](https://github.com/antonsoo/praviel/issues)
- 📖 [Documentation](../docs/)
