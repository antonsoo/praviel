# User Authentication & Gamification System

## Overview

The Ancient Languages learning app now includes a comprehensive user authentication and profile management system with advanced gamification features. This document explains the architecture, setup, and usage.

## Architecture

### Backend (FastAPI + PostgreSQL)

#### Database Tables

**Authentication & Profile:**
- `user` - Core authentication (username, email, hashed password)
- `user_profile` - Optional personal info (real name, Discord, phone)
- `user_api_config` - BYOK API key storage (encrypted)
- `user_preferences` - App settings and LLM preferences

**Gamification & Progress:**
- `user_progress` - XP, level, streak, total lessons/exercises
- `user_skill` - Per-topic Elo ratings (grammar, morphology, vocabulary)
- `user_achievement` - Badges, milestones, collections
- `user_text_stats` - Per-work reading statistics (coverage, WPM, comprehension)

**Learning Tracking:**
- `user_srs_card` - SRS flashcard state (FSRS algorithm)
- `learning_event` - Event log for all learning activities
- `user_quest` - Active and completed quests/challenges

#### Authentication Flow

1. **Registration** (`POST /api/v1/auth/register`)
   - Creates user account with hashed password (bcrypt)
   - Initializes profile, preferences, and progress records
   - Returns user profile (does NOT auto-login)

2. **Login** (`POST /api/v1/auth/login`)
   - Accepts username or email + password
   - Returns JWT access token (7 days) and refresh token (30 days)

3. **Token Refresh** (`POST /api/v1/auth/refresh`)
   - Exchanges refresh token for new access + refresh tokens
   - Allows seamless mobile experience

4. **Logout** (`POST /api/v1/auth/logout`)
   - Client-side only (discard tokens)
   - Could be extended with token blacklisting

### API Endpoints

#### Authentication
```
POST /api/v1/auth/register       - Register new user
POST /api/v1/auth/login          - Login with credentials
POST /api/v1/auth/refresh        - Refresh access token
POST /api/v1/auth/logout         - Logout (client discards tokens)
```

#### User Profile
```
GET    /api/v1/users/me          - Get current user profile
PATCH  /api/v1/users/me          - Update profile (name, Discord, phone)
DELETE /api/v1/users/me          - Deactivate account
GET    /api/v1/users/me/preferences     - Get preferences
PATCH  /api/v1/users/me/preferences     - Update preferences
```

#### Progress & Gamification
```
GET  /api/v1/progress/me         - Get overall progress (XP, level, streak)
POST /api/v1/progress/me/update  - Update progress after lesson
GET  /api/v1/progress/me/skills  - Get skill ratings by topic
GET  /api/v1/progress/me/achievements  - Get unlocked achievements
GET  /api/v1/progress/me/texts         - Get reading stats for all works
GET  /api/v1/progress/me/texts/{work_id}  - Get stats for specific work
```

## Setup Instructions

### 1. Install Dependencies

Add to `backend/requirements.txt`:
```txt
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
```

Install:
```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Add to `backend/.env`:
```env
# Required: Set a strong secret key for JWT signing
JWT_SECRET_KEY=your-super-secret-random-string-here-change-me-in-production

# Optional: Customize token expiration (in minutes)
ACCESS_TOKEN_EXPIRE_MINUTES=10080  # 7 days (default)
REFRESH_TOKEN_EXPIRE_MINUTES=43200  # 30 days (default)
```

**IMPORTANT:** Generate a secure secret key:
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 3. Run Database Migration

```bash
cd backend
alembic upgrade head
```

This creates all user-related tables.

### 4. Verify Setup

Start the backend:
```bash
uvicorn app.main:app --reload
```

Visit the auto-generated docs:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

You should see the new `/api/v1/auth/*`, `/api/v1/users/*`, and `/api/v1/progress/*` endpoints.

## Usage Examples

### Register a New User

```bash
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "homeros",
    "email": "homeros@example.com",
    "password": "SecurePassword123"
  }'
```

Response:
```json
{
  "id": 1,
  "username": "homeros",
  "email": "homeros@example.com",
  "is_active": true,
  "created_at": "2025-10-05T00:00:00Z",
  "real_name": null,
  "discord_username": null
}
```

### Login

```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username_or_email": "homeros",
    "password": "SecurePassword123"
  }'
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### Access Protected Endpoints

Use the access token in the `Authorization` header:

```bash
curl -X GET "http://localhost:8000/api/v1/users/me" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Update Progress After Lesson

```bash
curl -X POST "http://localhost:8000/api/v1/progress/me/update" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "xp_gained": 50,
    "lesson_id": "iliad-1-1-10",
    "time_spent_minutes": 15
  }'
```

Response includes updated XP, level, streak, and progress to next level.

## Gamification Features

### XP & Leveling

Level calculation: `Level = floor(sqrt(XP/100))`

XP required for level: `XP = level² × 100`

**Examples:**
- Level 1: 100 XP
- Level 5: 2,500 XP
- Level 10: 10,000 XP
- Level 20: 40,000 XP

### Streak Tracking

- Daily streak increments if lesson completed on consecutive days
- Resets if more than 1 day gap
- Tracks `max_streak` for all-time record

### Skill Ratings

Per-topic Elo ratings (default: 1000.0) for:
- Grammar topics (e.g., "genitive_absolute", "optative_mood")
- Morphology categories (e.g., "noun_declension", "verb_conjugation")
- Vocabulary domains

Updated based on exercise performance with Elo algorithm.

### Achievements

**Badge types:**
- Milestones: "First Lesson", "100 Lessons", "1000 Lines Read"
- Mastery: "Grammar Master", "Morphology Expert", "Vocabulary Champion"
- Collections: "LSJ Headwords Unlocked: 100", "Smyth Sections: 50"
- Streaks: "7-Day Streak", "30-Day Streak", "100-Day Streak"

### Quests

Active challenges with progress tracking:
- "Master genitive absolute" (grammar focus)
- "Scan 10 hexameter lines" (meter practice)
- "Zero-hint Iliad 1.1-1.10" (reading challenge)
- "Read 1000 lines this week" (volume goal)

## Integration with Existing Features

### BYOK (Bring Your Own Key)

Currently, API keys are stored per-request in headers. With user accounts, users can:
1. Store encrypted API keys in `user_api_config`
2. Set default provider preferences in `user_preferences`
3. Retrieve keys automatically for authenticated requests

**Note:** API key encryption/decryption utilities need to be implemented.

### Progress Sync

The existing Flutter `ProgressService` stores progress locally. With user accounts:
1. On login: Sync local progress to server
2. On logout: Keep local copy as backup
3. On app start: Pull server progress if logged in
4. Conflict resolution: Use most recent `last_lesson_at`

### Lesson History

Link `lesson_history` records to `user_id` for cross-device sync.

## Security Considerations

### Password Storage
- Passwords hashed with bcrypt (cost factor 12)
- Never logged or returned in API responses
- Password reset flow (TODO: implement email verification)

### JWT Tokens
- Signed with HS256 algorithm
- Stateless (no server-side session storage)
- Access tokens: short-lived (7 days default)
- Refresh tokens: longer-lived (30 days default)
- Tokens contain only user ID, no sensitive data

### API Key Encryption
- User API keys stored encrypted at rest
- Decryption only when needed for API calls
- Consider using Fernet symmetric encryption or AWS KMS

### CORS & Security Headers
- CORS restricted to known origins in production
- HTTPS required in production
- Rate limiting recommended for auth endpoints

## Future Enhancements

### Email Verification
- Send verification email on registration
- Require verification before full account access
- Password reset via email

### OAuth Integration
- Login with Google, GitHub, Discord
- Link multiple auth providers to one account

### Token Blacklisting
- Maintain revoked token list in Redis
- Check on each authenticated request
- Expire blacklist entries after token expiration

### Multi-Factor Authentication (MFA)
- TOTP (Google Authenticator, Authy)
- SMS verification
- Backup codes

### Social Features
- Leaderboards (weekly, all-time)
- Friend system
- Quest sharing and challenges
- Study groups

### Analytics Dashboard
- Detailed progress charts (radar charts per work/author)
- Learning velocity trends
- Comparative stats (vs. similar learners)
- AI-powered coaching recommendations

## Flutter Client Integration

### Authentication Service

```dart
class AuthService extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  User? _currentUser;

  bool get isAuthenticated => _accessToken != null;
  User? get currentUser => _currentUser;

  Future<void> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      // Registration successful - now log in
      await login(username, password);
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<void> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username_or_email': usernameOrEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];

      // Save tokens securely (flutter_secure_storage)
      await _saveTokens(_accessToken!, _refreshToken!);

      // Fetch user profile
      await _fetchCurrentUser();

      notifyListeners();
    } else {
      throw Exception('Login failed');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    await _clearTokens();
    notifyListeners();
  }

  Future<Map<String, String>> getAuthHeaders() async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }
    return {'Authorization': 'Bearer $_accessToken'};
  }
}
```

### Protected API Calls

```dart
class LessonApi {
  final AuthService _authService;

  Future<Lesson> generateLesson(LessonRequest request) async {
    final headers = await _authService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse('$baseUrl/lessons/generate'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 401) {
      // Token expired - try to refresh
      await _authService.refreshToken();
      return generateLesson(request); // Retry
    }

    // Handle response...
  }
}
```

## Testing

Run backend tests:
```bash
cd backend
pytest tests/ -v
```

Key test coverage:
- User registration validation (username/email uniqueness, password strength)
- Login authentication (correct/incorrect credentials)
- JWT token generation and validation
- Protected endpoint access control
- Progress update calculations (XP, level, streak)
- Skill rating updates (Elo algorithm)

## Migration from Local-Only Progress

For existing users with local progress data:

1. **Prompt for account creation** when app detects local progress
2. **Sync local data** to server on first login:
   ```dart
   if (hasLocalProgress && isFirstLogin) {
     await syncLocalProgressToServer();
   }
   ```
3. **Conflict resolution**: If server has newer data, show merge UI
4. **Backup local data** before syncing

## API Reference

Full API documentation available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Support & Questions

For issues or feature requests related to user authentication:
- Backend: See `backend/app/security/auth.py` and `backend/app/api/routers/auth.py`
- Models: See `backend/app/db/user_models.py`
- Schemas: See `backend/app/api/schemas/user_schemas.py`

## License

Same as the main project.
