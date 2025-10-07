# Authentication System - Quick Start Guide

## Prerequisites

### Required Software
- Python 3.12.11 (via `ancient-languages-py312` conda environment)
- Flutter SDK
- PostgreSQL database (or Docker)
- Git Bash or PowerShell (Windows) / Terminal (Mac/Linux)

### Verify Installation
```powershell
# Check Python version (should be 3.12.11)
conda activate ancient-languages-py312
python --version

# Check Flutter
flutter --version

# Check database
docker ps | grep postgres  # If using Docker
```

## Step 1: Database Setup

### Option A: Using Docker (Recommended)
```powershell
# Start PostgreSQL
docker compose up -d db

# Wait for database to be ready (about 10 seconds)
Start-Sleep -Seconds 10

# Run migrations
python -m alembic -c alembic.ini upgrade head
```

### Option B: Local PostgreSQL
```powershell
# Create database
createdb ancient_languages

# Run migrations
python -m alembic -c alembic.ini upgrade head
```

### Verify Database Tables
```powershell
# Connect to database
docker exec -it ancient_languages_db psql -U postgres -d ancient_languages

# List tables (should see: user, user_profile, user_preferences, user_progress)
\dt

# Exit
\q
```

## Step 2: Backend Setup

### Install Dependencies
```powershell
cd backend

# Activate Python environment
conda activate ancient-languages-py312

# Install packages
pip install -e ".[dev]"
```

### Configure Environment
Create `backend/.env`:
```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ancient_languages

# JWT Secret (CHANGE THIS IN PRODUCTION!)
JWT_SECRET_KEY=your-secret-key-here-change-in-production

# Token Expiry
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_MINUTES=10080

# CORS
DEV_CORS_ENABLED=true

# Features
LESSONS_ENABLED=true
TTS_ENABLED=true
COACH_ENABLED=true
```

### Start Backend Server
```powershell
# From backend directory
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Backend should now be running at:** http://localhost:8000

### Verify Backend is Running
Open browser to: http://localhost:8000/docs

You should see FastAPI Swagger documentation with auth endpoints.

## Step 3: Test Backend Auth Endpoints

### Test 1: Register New User
```powershell
# In a new terminal
curl -X POST http://localhost:8000/api/v1/auth/register `
  -H "Content-Type: application/json" `
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "TestPass123"
  }'
```

**Expected Response:**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "2025-10-07T..."
}
```

### Test 2: Login
```powershell
curl -X POST http://localhost:8000/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{
    "username_or_email": "testuser",
    "password": "TestPass123"
  }'
```

**Expected Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

**Save the access_token for next steps!**

### Test 3: Get Current User Profile
```powershell
# Replace <ACCESS_TOKEN> with token from step 2
curl -X GET http://localhost:8000/api/v1/users/me `
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

**Expected Response:**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "..."
}
```

### Test 4: Request Password Reset
```powershell
curl -X POST http://localhost:8000/api/v1/auth/password-reset/request `
  -H "Content-Type: application/json" `
  -d '{
    "email": "test@example.com"
  }'
```

**Expected Response:**
```json
{
  "message": "If an account exists with this email, you will receive password reset instructions.",
  "email": "test@example.com"
}
```

**Check backend logs for reset token** (email sending is stubbed in development).

## Step 4: Flutter App Setup

### Install Dependencies
```powershell
cd client/flutter_reader

# Get packages
flutter pub get

# Verify no errors
flutter analyze lib/pages/auth/
```

**Expected Output:** "No issues found" or only warnings

### Configure API Endpoint

Edit `client/flutter_reader/lib/models/app_config.dart` if needed:
```dart
static const String defaultApiBaseUrl = 'http://localhost:8000';
```

### Run Flutter App
```powershell
# For web
flutter run -d chrome

# For Windows desktop
flutter run -d windows

# For Android emulator
flutter run -d emulator

# For iOS simulator (Mac only)
flutter run -d ios
```

## Step 5: Test Flutter Auth Flow

### Test A: Sign Up
1. Open the Flutter app
2. Navigate to **Profile** tab (bottom navigation, far right)
3. Tap **"Sign Up"** button
4. Fill in the form:
   - Username: `testuser2` (must be unique)
   - Email: `test2@example.com`
   - Password: `TestPass123` (must have uppercase, lowercase, digit)
   - Confirm Password: `TestPass123`
5. Check the "I agree to Terms" checkbox
6. Tap **"Create Account"**

**Expected Result:**
- Success message appears
- Automatically logs you in
- Returns to Profile tab
- Shows your user info

### Test B: Login
1. If logged in, tap **"Log Out"** first
2. Tap **"Log In"**
3. Enter credentials:
   - Username/Email: `testuser2`
   - Password: `TestPass123`
4. Tap **"Log In"**

**Expected Result:**
- Success
- Returns to Profile tab
- Shows your profile

### Test C: View Profile
1. Navigate to **Profile** tab
2. Verify you see:
   - Your username
   - Your email
   - Avatar with first letter
   - Account status: "Active"
   - Member since date

### Test D: Logout
1. In Profile tab, tap **"Log Out"**
2. Confirm in dialog
3. Verify you see "Not Logged In" message

### Test E: Password Reset
1. From login screen, tap **"Forgot password?"**
2. Enter your email
3. Tap **"Send Reset Instructions"**
4. See success screen with instructions

**Note:** Email is not actually sent (stubbed). Check backend logs for reset token.

### Test F: Guest Mode
1. Tap **"Continue as Guest"** from login
2. App works without account
3. Profile tab prompts to sign in

## Step 6: Verify Session Persistence

1. Log in to the app
2. **Close the app completely** (not just minimize)
3. Reopen the app
4. Navigate to Profile tab

**Expected Result:** Still logged in (token persisted)

## Step 7: Verify Token Refresh

This is automatic but harder to test. The access token expires after 15 minutes.

1. Log in
2. Wait 15-20 minutes
3. Make an API call (e.g., navigate to Profile tab)

**Expected Result:** Token automatically refreshes, no error

## Common Issues & Solutions

### Issue: "Connection refused" from Flutter app
**Solution:**
- Check backend is running on port 8000
- For Android emulator, use `http://10.0.2.2:8000` instead of `localhost`
- For iOS simulator, use your machine's IP address

### Issue: "Username already registered"
**Solution:** Use a different username or email

### Issue: "Password must contain..."
**Solution:** Password requirements:
- At least 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit

### Issue: "Could not validate credentials"
**Solution:**
- Token might be expired
- Log out and log in again
- Check backend logs for errors

### Issue: Database connection error
**Solution:**
```powershell
# Restart database
docker compose restart db

# Check if migrations ran
python -m alembic -c alembic.ini current
```

### Issue: Flutter compilation errors
**Solution:**
```powershell
flutter clean
flutter pub get
flutter analyze
```

## Verification Checklist

Use this to verify everything works:

- [ ] Backend starts without errors
- [ ] Database migrations completed
- [ ] Can register new user via curl
- [ ] Can login via curl
- [ ] Can get user profile with token
- [ ] Flutter app compiles without errors
- [ ] Can navigate to Profile tab
- [ ] Can create account in app
- [ ] Can login in app
- [ ] Profile displays user info
- [ ] Can logout
- [ ] Session persists after app restart
- [ ] Password reset flow works

## Next Steps

### For Development
1. Test all edge cases (wrong password, duplicate username, etc.)
2. Test on different devices/browsers
3. Load test with multiple users
4. Monitor backend logs for errors

### For Production
1. **Change JWT_SECRET_KEY** to a strong random value
2. Set up email service (SendGrid, AWS SES, etc.)
3. Use `flutter_secure_storage` instead of `SharedPreferences`
4. Enable HTTPS/TLS
5. Set up monitoring and logging
6. Configure rate limiting for your traffic
7. Add email verification
8. Consider adding OAuth providers

## Testing Scripts

### Backend Health Check
```powershell
# Create a file: test-auth-health.ps1
$response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET
Write-Host "Backend Health: $($response.status)"

$response = Invoke-RestMethod -Uri "http://localhost:8000/docs" -Method GET
if ($response) {
    Write-Host "API Docs accessible: OK"
}
```

### Full Auth Flow Test
```powershell
# Create a file: test-auth-flow.ps1
# Test registration
$username = "testuser_$(Get-Random -Maximum 10000)"
$email = "test_$(Get-Random -Maximum 10000)@example.com"

Write-Host "Testing registration..."
$register = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/register" `
    -Method POST `
    -ContentType "application/json" `
    -Body (@{
        username = $username
        email = $email
        password = "TestPass123"
    } | ConvertTo-Json)

Write-Host "Registered user: $($register.username)"

# Test login
Write-Host "Testing login..."
$login = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body (@{
        username_or_email = $username
        password = "TestPass123"
    } | ConvertTo-Json)

Write-Host "Login successful, token: $($login.access_token.Substring(0, 20))..."

# Test get profile
Write-Host "Testing get profile..."
$headers = @{
    "Authorization" = "Bearer $($login.access_token)"
}
$profile = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/users/me" `
    -Method GET `
    -Headers $headers

Write-Host "Profile retrieved: $($profile.username)"
Write-Host "`nAll tests passed!"
```

Run it:
```powershell
.\test-auth-flow.ps1
```

## Support & Documentation

- **Full Documentation:** [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md)
- **Honest Status:** [AUTH_STATUS_HONEST.md](AUTH_STATUS_HONEST.md)
- **API Reference:** http://localhost:8000/docs (when backend is running)
- **Backend Tests:** `backend/app/tests/test_authentication.py`

## Quick Reference

### Backend Endpoints
- POST `/api/v1/auth/register` - Register new user
- POST `/api/v1/auth/login` - Login
- POST `/api/v1/auth/refresh` - Refresh token
- POST `/api/v1/auth/logout` - Logout
- POST `/api/v1/auth/change-password` - Change password
- POST `/api/v1/auth/password-reset/request` - Request reset
- POST `/api/v1/auth/password-reset/confirm` - Confirm reset
- GET `/api/v1/users/me` - Get current user

### Flutter Pages
- `lib/pages/auth/login_page.dart` - Login screen
- `lib/pages/auth/signup_page.dart` - Registration screen
- `lib/pages/auth/forgot_password_page.dart` - Password reset
- `lib/pages/profile_page.dart` - User profile
- `lib/services/auth_service.dart` - Auth service logic

---

**Last Updated:** 2025-10-07
**Status:** Ready for testing
**Tested:** Compilation verified, runtime testing required
