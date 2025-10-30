# Authentication System Documentation

## Overview

The Ancient Languages app features a **production-grade authentication system** designed to match the quality of top language learning platforms. The system includes:

- ✅ Beautiful, modern login/signup UI with animations
- ✅ JWT-based authentication with access & refresh tokens
- ✅ Secure password hashing (bcrypt)
- ✅ Password strength validation and indicators
- ✅ Password reset flow
- ✅ User profile management
- ✅ Guest mode (optional authentication)
- ✅ Session persistence across app restarts
- ✅ Automatic token refresh
- ✅ Security best practices (rate limiting, CSRF protection, etc.)

## Architecture

### Backend (FastAPI)

**Location:** `backend/app/api/routers/auth.py`, `backend/app/security/auth.py`

**Features:**
- JWT token generation with configurable expiry
- Access tokens (short-lived, default 15 minutes)
- Refresh tokens (long-lived, default 7 days)
- Password hashing with bcrypt (automatic salting)
- Protected endpoints using dependency injection
- User registration with related table initialization

**Security Measures:**
- Passwords hashed with bcrypt (never stored in plaintext)
- JWT tokens with expiration
- Rate limiting middleware
- CSRF protection middleware
- Security headers middleware
- Email/username enumeration protection

### Frontend (Flutter)

**Location:**
- UI: `client/flutter_reader/lib/pages/auth/`
- Service: `client/flutter_reader/lib/services/auth_service.dart`
- Provider: `client/flutter_reader/lib/app_providers.dart`

**Features:**
- Animated login/signup screens
- Password strength indicator with visual feedback
- Form validation with helpful error messages
- Secure token storage using `SharedPreferences`
- Automatic token refresh on 401 responses
- Profile management UI
- Guest mode support

## User Flows

### 1. Sign Up Flow

```
User opens app → Profile tab → "Sign Up" button
    ↓
Enter username (validation: 3-50 chars, alphanumeric + _ -)
    ↓
Enter email (validation: valid email format)
    ↓
Enter password (validation: 8+ chars, uppercase, lowercase, digit)
    ↓
Confirm password (must match)
    ↓
Agree to Terms & Privacy Policy
    ↓
Submit → Backend creates user + profile + preferences + progress
    ↓
Auto-login → Navigate to home
```

**Backend Endpoint:** `POST /api/v1/auth/register`

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit

### 2. Login Flow

```
User opens app → Profile tab → "Log In" button
    ↓
Enter username/email
    ↓
Enter password
    ↓
Submit → Backend validates credentials
    ↓
Success → Receive access + refresh tokens
    ↓
Store tokens → Fetch user profile
    ↓
Navigate to home
```

**Backend Endpoint:** `POST /api/v1/auth/login`

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

### 3. Password Reset Flow

```
Login screen → "Forgot password?" link
    ↓
Enter email address
    ↓
Submit → Backend generates reset token
    ↓
Email sent with reset link (TODO: integrate email service)
    ↓
User clicks link → Opens reset form
    ↓
Enter new password → Confirm password
    ↓
Submit → Backend validates token & updates password
    ↓
Success → User can login with new password
```

**Backend Endpoints:**
- `POST /api/v1/auth/password-reset/request` - Request reset
- `GET /api/v1/auth/password-reset/validate-token/{token}` - Validate token
- `POST /api/v1/auth/password-reset/confirm` - Complete reset

**Security:**
- Tokens expire after 15 minutes
- Single-use tokens (deleted after use)
- No email enumeration (always returns success)

### 4. Token Refresh Flow

```
User makes authenticated request
    ↓
Backend returns 401 Unauthorized
    ↓
Frontend automatically calls refresh endpoint
    ↓
Backend validates refresh token
    ↓
Success → New access + refresh tokens issued
    ↓
Frontend retries original request with new token
```

**Backend Endpoint:** `POST /api/v1/auth/refresh`

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

### 5. Profile Management

**View Profile:**
- Navigate to Profile tab
- Shows: avatar, username, email, account status, member since date

**Edit Profile:**
- Currently placeholder (coming soon)
- Will support: real name, discord username, phone, profile picture

**Change Password:**
- Requires current password verification
- New password must meet strength requirements

**Backend Endpoint:** `POST /api/v1/auth/change-password`

### 6. Logout

```
Profile tab → "Log Out" button → Confirmation dialog
    ↓
Confirm → Clear local tokens
    ↓
Notify backend (optional, for blacklisting)
    ↓
Navigate to login screen
```

**Backend Endpoint:** `POST /api/v1/auth/logout`

## Guest Mode

The app supports **optional authentication** - users can explore features without creating an account.

**Implementation:**
```dart
AuthGate(
  requireAuth: false, // Set to true to require login
  child: MyApp(),
)
```

**Current Settings:**
- Home, Reader, Lessons, Chat tabs: accessible without login
- Profile tab: prompts to login when accessed
- Progress tracking: local-only for guests, synced for authenticated users

## API Endpoints Reference

### Authentication

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/v1/auth/register` | POST | No | Create new account |
| `/api/v1/auth/login` | POST | No | Login with credentials |
| `/api/v1/auth/logout` | POST | No | Logout (client-side token clearing) |
| `/api/v1/auth/refresh` | POST | No | Refresh access token |
| `/api/v1/auth/change-password` | POST | Yes | Change password |

### Password Reset

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/v1/auth/password-reset/request` | POST | No | Request reset email |
| `/api/v1/auth/password-reset/validate-token/{token}` | GET | No | Check token validity |
| `/api/v1/auth/password-reset/confirm` | POST | No | Complete password reset |

### User Profile

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/v1/users/me` | GET | Yes | Get current user profile |
| `/api/v1/users/me` | PATCH | Yes | Update profile |
| `/api/v1/users/me` | DELETE | Yes | Deactivate account |
| `/api/v1/users/me/preferences` | GET | Yes | Get preferences |
| `/api/v1/users/me/preferences` | PATCH | Yes | Update preferences |

## Security Configuration

### JWT Settings

**Location:** `backend/app/core/config.py`

```python
JWT_SECRET_KEY = "your-secret-key-here"  # Change in production!
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_MINUTES = 10080  # 7 days
```

⚠️ **IMPORTANT:** Change `JWT_SECRET_KEY` in production! Use a strong random string:
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Rate Limiting

**Location:** `backend/app/middleware/rate_limit.py`

Default limits:
- Authentication endpoints: 5 requests per minute per IP
- General endpoints: 60 requests per minute per IP

### CSRF Protection

**Location:** `backend/app/middleware/csrf.py`

- Enabled in production by default
- Exempts authentication endpoints
- Uses double-submit cookie pattern

## Database Models

### User Table

**Location:** `backend/app/db/user_models.py`

```python
class User(Base):
    id: int
    username: str (unique, indexed)
    email: str (unique, indexed)
    hashed_password: str
    is_active: bool (default True)
    is_superuser: bool (default False)
    created_at: datetime
    updated_at: datetime
```

### Related Tables

When a user registers, the following are automatically created:

1. **UserProfile** - Optional personal info (name, discord, phone, payment)
2. **UserPreferences** - App settings (theme, language, daily goals)
3. **UserProgress** - Gamification (XP, level, streak, achievements)

## Flutter Implementation Details

### AuthService

**Location:** `client/flutter_reader/lib/services/auth_service.dart`

**Responsibilities:**
- Token management (storage, retrieval, refresh)
- API calls for auth operations
- User state management
- Automatic token refresh on 401

**Usage:**
```dart
final authService = ref.read(authServiceProvider);

// Login
await authService.login(
  usernameOrEmail: 'user@example.com',
  password: 'Password123',
);

// Check auth status
if (authService.isAuthenticated) {
  final user = authService.currentUser;
}

// Make authenticated request
final response = await authService.authenticatedRequest(
  request: (headers) => http.get(url, headers: headers),
);

// Logout
await authService.logout();
```

### UI Components

**Login Page:** `lib/pages/auth/login_page.dart`
- Animated entry
- Form validation
- Error display
- "Forgot password" link
- "Sign up" navigation
- "Continue as guest" option

**Signup Page:** `lib/pages/auth/signup_page.dart`
- Password strength indicator (with color coding)
- Real-time validation
- Terms & privacy checkbox
- Animated feedback

**Forgot Password Page:** `lib/pages/auth/forgot_password_page.dart`
- Email input
- Success state with instructions
- Resend option

**Profile Page:** `lib/pages/profile_page.dart`
- User info display
- Account management
- Logout with confirmation

## Testing

### Backend Tests

**Location:** `backend/app/tests/test_authentication.py`

Run tests:
```bash
pytest app/tests/test_authentication.py -v
```

**Coverage:**
- Password hashing & verification
- Token generation & validation
- User registration with related tables
- Login with username/email
- Token refresh
- Password change
- Logout

### Manual Testing Checklist

- [ ] Register new user
- [ ] Login with username
- [ ] Login with email
- [ ] Login with wrong password (should fail)
- [ ] Access protected endpoint without token (should fail)
- [ ] Access protected endpoint with valid token (should succeed)
- [ ] Refresh token before expiry
- [ ] Wait for access token to expire, make request (should auto-refresh)
- [ ] Change password
- [ ] Request password reset
- [ ] Complete password reset
- [ ] Logout and verify tokens cleared
- [ ] Close app, reopen (should remember logged-in state)

## Production Deployment Checklist

### Backend

- [ ] Change `JWT_SECRET_KEY` to strong random value
- [ ] Set appropriate token expiry times
- [ ] Enable HTTPS/TLS
- [ ] Configure rate limiting for your traffic
- [ ] Set up email service for password resets
- [ ] Implement token blacklisting (Redis/database)
- [ ] Add email verification for new registrations
- [ ] Set up monitoring for failed login attempts
- [ ] Configure CORS for your domain only
- [ ] Enable all security middleware
- [ ] Set secure cookie flags (httpOnly, secure, sameSite)

### Frontend

- [ ] Use flutter_secure_storage for token storage (not SharedPreferences)
- [ ] Implement certificate pinning
- [ ] Add biometric authentication option
- [ ] Implement remember me / auto-login option
- [ ] Add logout from all devices feature
- [ ] Implement 2FA (two-factor authentication)
- [ ] Add session timeout warnings
- [ ] Implement OAuth providers (Google, Apple, Facebook)

### Monitoring

- [ ] Track failed login attempts
- [ ] Monitor token refresh rates
- [ ] Alert on password reset spikes
- [ ] Track user registration rates
- [ ] Monitor authentication latency

## Future Enhancements

### Planned Features

1. **Email Verification**
   - Send verification email on registration
   - Block certain features until verified
   - Resend verification email

2. **OAuth Social Login**
   - Google Sign In
   - Apple Sign In
   - Facebook Login

3. **Two-Factor Authentication (2FA)**
   - TOTP (Time-based One-Time Password)
   - SMS codes
   - Backup codes

4. **Advanced Security**
   - Session management (view active sessions, logout from all)
   - IP-based login alerts
   - Suspicious activity detection
   - Account recovery options

5. **User Features**
   - Profile pictures with upload
   - User bio/description
   - Privacy settings (profile visibility)
   - Account deletion with data export

## Troubleshooting

### "Could not validate credentials" Error

**Cause:** Token expired or invalid

**Solution:**
1. Check if access token has expired
2. Try refreshing token
3. If refresh fails, re-login

### "Username already registered" Error

**Cause:** Username is taken

**Solution:** Choose a different username

### Password Reset Email Not Received

**Cause:** Email service not configured (development mode)

**Solution:**
- Development: Check logs for reset token
- Production: Integrate email service (SendGrid, AWS SES)

### Tokens Not Persisting After App Restart

**Cause:** Storage not working properly

**Solution:**
- Check SharedPreferences initialization
- Verify `authService.initialize()` is called
- Consider using flutter_secure_storage for production

## Support

For questions or issues with the authentication system:

1. Check this documentation
2. Review test files for usage examples
3. Check backend logs for error details
4. Submit an issue with reproduction steps

---

**Last Updated:** 2025-10-07
**Maintained by:** Ancient Languages Development Team
