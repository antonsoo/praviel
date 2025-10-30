# BYOK — Bring Your Own Key

**BYOK (Bring Your Own Key)** is a privacy-first approach where you use your own OpenAI, Anthropic, or Google API keys instead of paying a subscription to the app.

## Why BYOK?

✅ **Privacy:** Your API keys are request-scoped, never stored permanently, never logged
✅ **Cost transparency:** Pay-as-you-go pricing (no markup, no subscription)
✅ **No lock-in:** Use any provider (OpenAI, Anthropic, Google) or none at all (offline Echo)
✅ **Control:** Choose which AI models to use for lessons and chat

---

## How It Works

### 1. Get an API Key

**Free tier (recommended for learners):**
- [Google AI Studio](https://aistudio.google.com/app/apikey) — Gemini 2.5 Flash (generous free tier)

**Paid tier (pay-as-you-go):**
- [OpenAI](https://platform.openai.com/api-keys) — GPT-5 (~$0.01-0.05 per lesson, best quality)
- [Anthropic](https://console.anthropic.com/) — Claude 4.5 (great for explanations)

### 2. Add Your Key to the App

**Option A: Environment Variables (Recommended for local development)**

Add to `backend/.env`:

```bash
# Google (free tier)
GOOGLE_API_KEY=AIza-your-key-here

# OpenAI (paid)
OPENAI_API_KEY=sk-your-key-here

# Anthropic (paid)
ANTHROPIC_API_KEY=sk-ant-your-key-here

# Enable lessons
LESSONS_ENABLED=1
```

Restart the backend:
```bash
uvicorn app.main:app --reload
```

**Option B: Per-Request Headers (Coming Soon)**

Pass API keys as request headers for per-user BYOK:

```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H "X-OpenAI-API-Key: <YOUR_KEY_HERE>" \
  -H "Content-Type: application/json" \
  -d '{"language": "grc", "profile": "beginner", "provider": "openai"}'
```

**Option C: User Preferences (Database Storage)**

Store encrypted API keys in user preferences (requires authentication):

```bash
POST /user/preferences
{
  "api_keys": {
    "openai": "sk-your-key-here",
    "google": "AIza-your-key-here"
  }
}
```

Keys are encrypted at rest using AES encryption.

---

## Security

### How Your Keys Are Protected

1. **Request-scoped:** Keys are only held in memory during API calls
2. **Never logged:** API keys are redacted from all logs
3. **Encrypted at rest:** If stored in database, keys are AES-encrypted
4. **Rate limiting:** Prevents abuse and unexpected costs
5. **CSRF protection:** Security middleware prevents unauthorized requests

### What We Never Do

❌ Store keys in plaintext
❌ Log API keys
❌ Share keys with third parties
❌ Use your keys for anything except your requests

---

## Cost Estimates

**Typical lesson generation costs (per lesson):**

| Provider | Model | Cost per Lesson | Notes |
|----------|-------|-----------------|-------|
| **Google** | Gemini 2.5 Flash | **FREE** | Generous free tier (60 requests/min) |
| **OpenAI** | GPT-5 | ~$0.01-0.05 | Best quality, most expensive |
| **Anthropic** | Claude 4.5 Sonnet | ~$0.02-0.03 | Great for explanations |
| **Echo** | Offline | **FREE** | No AI, returns seed data |

**Typical usage (30 min/day):**
- **Free tier (Google Gemini):** $0/month
- **Paid tier (OpenAI GPT-5):** ~$5-15/month

**Your actual costs depend on:**
- Which provider you choose
- How many lessons you generate
- How much you chat with AI tutors
- Lesson length and complexity

---

## Choosing a Provider

### Best for Beginners: Google Gemini 2.5 Flash

✅ Free tier (generous limits)
✅ Good quality for most lessons
✅ Fast response times

**Get started:**
1. Visit https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Add to `.env`: `GOOGLE_API_KEY=AIza-your-key-here`

### Best Quality: OpenAI GPT-5

✅ Best lesson quality
✅ Most accurate translations
✅ Best grammar explanations

❌ Most expensive (~$0.01-0.05 per lesson)

**Get started:**
1. Visit https://platform.openai.com/api-keys
2. Create an API key
3. Add to `.env`: `OPENAI_API_KEY=sk-your-key-here`

### Best for Privacy: Echo (Offline)

✅ Completely free
✅ No API key needed
✅ Works offline

❌ No AI (returns seed/example data)

**Usage:**
```bash
# No API key needed
POST /lesson/generate
{"language": "grc", "profile": "beginner", "provider": "echo"}
```

---

## API Key Rotation

**Recommended: Rotate keys periodically for security.**

1. Generate new API key from provider dashboard
2. Update `.env` or user preferences
3. Delete old key from provider dashboard

---

## Troubleshooting

### "API key invalid" error

**Check:**
1. Key copied correctly (no extra spaces)
2. Key is active (not revoked)
3. Billing enabled (for OpenAI/Anthropic)

### "Rate limit exceeded" error

**Solutions:**
- Wait a few seconds and retry
- Upgrade to paid tier (Google)
- Check your usage limits in provider dashboard

### "Insufficient credits" error

**Solutions:**
- Add credits to your OpenAI/Anthropic account
- Switch to Google Gemini (free tier)
- Use Echo provider (offline fallback)

---

## FAQ

### Is my API key stored permanently?

**No.** By default, keys are request-scoped (only held in memory during API calls).

If you choose to store keys in user preferences, they are encrypted at rest using AES encryption.

### Can the app owner see my API key?

**No.** Keys are never logged and are redacted from all server logs.

### What if I don't want to use BYOK?

Use the **Echo provider** (offline fallback). It's completely free and requires no API key.

### Can I use multiple providers?

**Yes.** You can add multiple API keys and choose which provider to use per request.

---

## Privacy Policy

For full privacy details, see [docs/PRIVACY.md](PRIVACY.md).

**Summary:**
- API keys are request-scoped (not stored by default)
- If stored in database, keys are AES-encrypted
- Keys are never logged or shared
- You can delete your keys at any time

---

## Need Help?

- 💬 [GitHub Discussions](https://github.com/antonsoo/praviel/discussions)
- 🐛 [GitHub Issues](https://github.com/antonsoo/praviel/issues)
- 📖 [Documentation](../docs/)
