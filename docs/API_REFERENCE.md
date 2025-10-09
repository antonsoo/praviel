# API Reference Guide

**Ancient Languages Platform — Complete REST API Documentation**

Base URL: `http://localhost:8000` (development)

---

## Table of Contents

1. [Authentication](#authentication)
2. [User Management](#user-management)
3. [Lessons](#lessons)
4. [Chat](#chat)
5. [Reader](#reader)
6. [Progress & Gamification](#progress--gamification)
7. [Text-to-Speech](#text-to-speech)
8. [API Keys (BYOK)](#api-keys-byok)
9. [Health & Diagnostics](#health--diagnostics)

---

## Authentication

### Register New User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "learner123",
  "password": "SecurePass123!"
}
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "learner123",
  "created_at": "2025-10-09T12:00:00Z"
}
```

### Login
```http
POST /auth/login
Content-Type: application/x-www-form-urlencoded

username=learner123&password=SecurePass123!
```

**Response:**
```json
{
  "access_token": "<JWT_ACCESS_TOKEN>",
  "refresh_token": "<JWT_REFRESH_TOKEN>",
  "token_type": "bearer"
}
```

### Refresh Token
```http
POST /auth/refresh
Authorization: Bearer {refresh_token}
```

---

## User Management

### Get Current User Profile
```http
GET /users/me
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "learner123",
  "display_name": "Ancient Greek Enthusiast",
  "preferences": {
    "default_lesson_provider": "openai",
    "default_lesson_model": "gpt-5",
    "daily_xp_goal": 500,
    "theme": "dark"
  }
}
```

### Update User Preferences
```http
PUT /users/me/preferences
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "default_lesson_provider": "anthropic",
  "default_lesson_model": "claude-4.5-sonnet",
  "daily_xp_goal": 1000,
  "theme": "light"
}
```

---

## Lessons

### Generate AI Lesson
```http
POST /lesson/generate
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "text_ref": "Il.1.1-1.10",
  "exercise_types": ["match", "cloze", "translate"],
  "difficulty": "intermediate",
  "provider": "openai",
  "model": "gpt-5"
}
```

**Response:**
```json
{
  "lesson_id": "abc123",
  "exercises": [
    {
      "type": "match",
      "pairs": [
        {"greek": "μῆνις", "english": "wrath, anger"},
        {"greek": "θεά", "english": "goddess"}
      ]
    },
    {
      "type": "cloze",
      "text": "Μῆνιν ἄειδε θεά Πηληϊάδεω [____]",
      "options": ["Ἀχιλῆος", "Ἀχιλλέως", "Ἀχιλεύς"],
      "correct": "Ἀχιλῆος"
    }
  ],
  "metadata": {
    "text_source": "Homer, Iliad 1.1-1.10",
    "generated_at": "2025-10-09T12:00:00Z"
  }
}
```

### Submit Lesson Results
```http
POST /lesson/submit
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "lesson_id": "abc123",
  "results": [
    {"exercise_id": "ex1", "correct": true, "time_spent_ms": 5000},
    {"exercise_id": "ex2", "correct": false, "time_spent_ms": 8000}
  ]
}
```

---

## Chat

### Start Chat Session
```http
POST /chat/athenian-merchant
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "message": "Χαῖρε! Τί πωλεῖς;",
  "context": "marketplace"
}
```

**Response:**
```json
{
  "response": "Χαῖρε, ὦ φίλε! Πωλῶ οἶνον καὶ ἐλαίαν. Τί βούλει ἀγοράσαι;",
  "translation": "Greetings, friend! I sell wine and olive oil. What would you like to buy?",
  "grammar_notes": [
    "πωλῶ is present indicative active, 1st person singular of πωλέω (to sell)"
  ]
}
```

### Available Personas
- `POST /chat/athenian-merchant` — Marketplace Greek
- `POST /chat/spartan-warrior` — Military discipline
- `POST /chat/athenian-philosopher` — Socratic dialogue
- `POST /chat/roman-senator` — Latin with Greek code-switching

---

## Reader

### Analyze Greek Text
```http
POST /reader/analyze
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "text": "Μῆνιν",
  "include_lsj": true,
  "include_smyth": true
}
```

**Response:**
```json
{
  "lemma": "μῆνις",
  "morphology": {
    "pos": "noun",
    "case": "accusative",
    "number": "singular",
    "gender": "feminine"
  },
  "lsj_definition": "wrath, anger, esp. of the gods (Il.1.1)",
  "smyth_refs": ["§175 (Accusative of Respect)"],
  "frequency": {
    "rank": 324,
    "total_occurrences": 47
  }
}
```

---

## Progress & Gamification

### Get User Progress
```http
GET /progress/me
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "xp_total": 2500,
  "current_level": 5,
  "xp_to_next_level": 300,
  "progress_percentage": 75.5,
  "streak_days": 14,
  "max_streak": 21,
  "total_lessons": 42,
  "total_exercises": 168,
  "total_time_minutes": 840
}
```

### Update Progress (After Lesson)
```http
POST /progress/me/update
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "xp_earned": 50,
  "lesson_completed": true,
  "exercises_count": 4,
  "time_spent_minutes": 15
}
```

### Get Skills (ELO Ratings)
```http
GET /progress/me/skills
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "skills": [
    {
      "topic": "aorist_passive",
      "elo_rating": 1250,
      "accuracy": 0.78,
      "total_attempts": 45,
      "last_practiced": "2025-10-09T12:00:00Z"
    },
    {
      "topic": "genitive_absolute",
      "elo_rating": 1180,
      "accuracy": 0.72,
      "total_attempts": 32
    }
  ]
}
```

### Get Achievements
```http
GET /progress/me/achievements
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "achievements": [
    {
      "id": "first_lesson",
      "name": "First Steps",
      "description": "Complete your first lesson",
      "icon": "🎓",
      "unlocked_at": "2025-10-01T10:00:00Z"
    },
    {
      "id": "week_streak",
      "name": "Week Warrior",
      "description": "Maintain a 7-day streak",
      "icon": "🔥",
      "unlocked_at": "2025-10-08T09:00:00Z"
    }
  ]
}
```

---

## Text-to-Speech

### Generate Speech
```http
POST /tts/speak
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "text": "Μῆνιν ἄειδε θεά",
  "provider": "openai",
  "voice": "alloy",
  "speed": 0.9
}
```

**Response:** Binary audio data (mp3)

---

## API Keys (BYOK)

### Add API Key
```http
POST /api-keys/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "provider": "openai",
  "api_key": "sk-..."
}
```

### List API Keys
```http
GET /api-keys/
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "keys": [
    {
      "provider": "openai",
      "masked_key": "sk-...abc123",
      "is_valid": true,
      "created_at": "2025-10-09T12:00:00Z"
    }
  ]
}
```

### Delete API Key
```http
DELETE /api-keys/{provider}
Authorization: Bearer {access_token}
```

---

## Health & Diagnostics

### System Health
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "uptime_seconds": 86400
}
```

### Provider Health
```http
GET /health/providers
```

**Response:**
```json
{
  "providers": [
    {"name": "openai", "status": "healthy", "latency_ms": 145},
    {"name": "anthropic", "status": "healthy", "latency_ms": 132},
    {"name": "google", "status": "healthy", "latency_ms": 98}
  ]
}
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid username or password",
    "details": {}
  }
}
```

**Common Error Codes:**
- `AUTHENTICATION_REQUIRED` (401)
- `INVALID_CREDENTIALS` (401)
- `INSUFFICIENT_PERMISSIONS` (403)
- `RESOURCE_NOT_FOUND` (404)
- `VALIDATION_ERROR` (422)
- `RATE_LIMIT_EXCEEDED` (429)
- `INTERNAL_ERROR` (500)

---

## Rate Limits

- **Standard user:** 100 requests/minute
- **Authenticated user:** 300 requests/minute
- **BYOK user:** 1000 requests/minute

---

## Best Practices

1. **Always use HTTPS** in production
2. **Store tokens securely** (never in localStorage for web apps)
3. **Refresh tokens before expiry** (access token: 30min, refresh: 30 days)
4. **Handle rate limits gracefully** (exponential backoff)
5. **Use BYOK for production** (server keys are for demo only)

---

**For more examples, see:** [API_EXAMPLES.md](API_EXAMPLES.md)
