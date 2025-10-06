# Flutter Client Setup

Complete guide for running the Ancient Languages Flutter client.

**🎯 New to the project?** See [BIG-PICTURE_PROJECT_PLAN.md](../BIG-PICTURE_PROJECT_PLAN.md) for the vision and language roadmap.

## Prerequisites

- **Flutter SDK**: 3.35.4+ stable ([Install Guide](https://docs.flutter.dev/get-started/install))
- **Backend running**: See [Quick Start](QUICKSTART.md) to start the API server
- **Browser**: Chrome, Edge, or use `web-server` device

**Platform-specific**: See [Windows Setup](WINDOWS.md) for Windows-specific Flutter configuration.

## Quick Start

```bash
cd client/flutter_reader
flutter pub get
flutter run -d chrome --web-renderer html
```

## Device Options

### Web (Chrome)

```bash
flutter run -d chrome --web-renderer html
```

### Web (Edge)

```bash
flutter run -d edge --web-renderer html
```

### Web Server (No Auto-Launch)

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 0
```

Then open the URL shown in your browser.

### Android

```bash
# List available devices
flutter devices

# Run on connected device
flutter run -d <device-id>
```

### Desktop

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## App Features

### Reader Tab

Analyze Ancient Greek text:

1. Paste text (e.g., Iliad 1.1-1.10)
2. Toggle LSJ/Smyth options
3. Tap **Analyze**
4. Tap any token to see:
   - Lemma + morphology
   - LSJ glosses
   - Smyth grammar references

### Lessons Tab

Generate vocabulary and grammar exercises:

1. Select profile: Beginner/Intermediate/Advanced
2. Choose sources: Daily phrases, Canonical texts
3. Pick exercise types: Alphabet, Match, Cloze, Translate
4. Tap **Generate Lesson**

**Requires**: `LESSONS_ENABLED=1` in backend `.env`

### Home Tab

Track your learning progress:

- Daily streak counter
- XP and level progression
- Recent lesson history
- Quick "Start Your Journey" button

### Chat Tab (Coming Soon)

Practice conversations with historical personas.

## BYOK Configuration

### What is BYOK?

**Bring Your Own Key** - Use your own API keys for OpenAI, Anthropic, or Google.

Keys are:
- Stored locally only (never sent to our servers for storage)
- Request-scoped (sent per API call only)
- Secured via `flutter_secure_storage` (mobile/desktop) or session storage (web)

### Setting Up BYOK

1. **Get an API Key**

   **OpenAI:**
   - Visit https://platform.openai.com/settings/organization/api-keys
   - Create a project-scoped key
   - Copy the secret (starts with `sk-proj-`)

   **Anthropic:**
   - Visit https://console.anthropic.com/settings/keys
   - Create a new key
   - Copy the secret (starts with `sk-ant-`)

   **Google:**
   - Visit https://aistudio.google.com/app/apikey
   - Create API key
   - Copy the secret

2. **Open BYOK Sheet in App**

   - Tap the **key icon** in the app bar (debug builds only)
   - Or tap "Quick start" if this is your first time

3. **Configure Provider**

   - Select provider: OpenAI, Anthropic, or Google
   - Paste your API key
   - (Optional) Select a specific model
   - Tap **Save**

4. **Verify**

   - Generate a lesson or use Reader with the selected provider
   - Check that `meta.provider` matches your selection
   - If the key fails, the app falls back to offline `echo` provider

### BYOK Quick Start Flow

First-time users see a quick-start sheet with:
- Preset combinations (e.g., "OpenAI GPT-5 Mini")
- One-tap model selection
- Paste key → Save → Done

### Clearing Keys

Tap **Clear** in the BYOK sheet to remove stored credentials when:
- Switching providers
- Rotating API keys
- Troubleshooting connectivity

## Configuration Files

### Development Config

Edit `client/flutter_reader/assets/config/dev.json`:

```json
{
  "apiBaseUrl": "http://127.0.0.1:8000",
  "enableDebugLogging": true
}
```

### Production Config

Edit `client/flutter_reader/assets/config/prod.json`:

```json
{
  "apiBaseUrl": "https://your-production-domain.com",
  "enableDebugLogging": false
}
```

## Building for Production

### Web

```bash
cd client/flutter_reader
flutter build web --release --web-renderer html
```

Output: `build/web/`

Serve via backend (see [docs/HOSTING.md](HOSTING.md)):
```bash
# In backend/.env
SERVE_FLUTTER_WEB=1
```

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Desktop

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Development Tools

### Analyzer

```bash
# Unix
scripts/dev/analyze_flutter.sh

# Windows
scripts/dev/analyze_flutter.ps1
```

Writes `artifacts/dart_analyze.json` with zero warnings/errors expected.

### Hot Reload

During development, press `r` in the terminal to hot reload changes.

### DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

Open in browser and connect to your running app for:
- Widget inspector
- Performance profiling
- Network debugging

## Demo Mode

Quick demo with pre-built web bundle:

```bash
# Unix
scripts/dev/run_demo.sh

# Windows
scripts/dev/run_demo.ps1
```

This:
1. Builds Flutter web (release mode)
2. Copies to `backend/static/`
3. Starts backend with `SERVE_FLUTTER_WEB=1`
4. Opens `http://127.0.0.1:8000/app/`

See [docs/DEMO.md](DEMO.md) for screenshots and smoke tests.

## Troubleshooting

### "Waiting for another flutter command to release the startup lock"

```bash
rm .flutter-tool-state/lockfile
```

### Chrome not launching (Windows)

Set Chrome path:
```powershell
setx CHROME_EXECUTABLE "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

Then open a **new terminal**.

### Hot reload not working

1. Check you're in the Flutter project directory
2. Ensure you're using `flutter run` (not `flutter run --release`)
3. Try `R` (capital R) for hot restart

### API calls failing

1. **Check backend is running**: `curl http://127.0.0.1:8000/health`
2. **Check CORS**: Set `ALLOW_DEV_CORS=1` in backend `.env`
3. **Check config**: Verify `apiBaseUrl` in `assets/config/dev.json`

### "Connection refused" errors

Backend not running or wrong port. Expected:
- Backend: `http://127.0.0.1:8000`
- Flutter web server: `http://127.0.0.1:<random-port>`

### BYOK keys not working

1. **Verify key format**: OpenAI keys start with `sk-proj-` or `sk-`
2. **Check provider selection**: Ensure provider matches your key
3. **Test backend directly**: Use curl to verify key works (see [API_EXAMPLES.md](API_EXAMPLES.md))
4. **Check diagnostic endpoint**: `GET /diag/byok/openai` with your key

### Storage permission errors (mobile)

Grant storage permission in device settings:
- Android: Settings → Apps → Ancient Languages → Permissions
- iOS: Settings → Ancient Languages → Allow access

## Platform-Specific Notes

### Web

- Keys stored in **session storage** (cleared on tab close)
- Use `flutter_secure_storage` fallback if available
- CORS must be enabled for local development

### Mobile

- Keys stored in **secure enclave** (iOS) or **Keystore** (Android)
- Requires device unlock to access keys
- Biometric unlock supported (if device configured)

### Desktop

- Keys stored in **Credential Manager** (Windows), **Keychain** (macOS), or **Secret Service** (Linux)
- System-level encryption

## Next Steps

- **Backend setup**: See [Quick Start](QUICKSTART.md)
- **API examples**: See [API Examples](API_EXAMPLES.md)
- **Windows-specific**: See [Windows Setup](WINDOWS.md)
- **Production hosting**: See [Hosting Guide](HOSTING.md)
