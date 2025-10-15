# Flutter App - User Guide

## Quick Start (Easiest Way)

### Option 1: Web Server Mode (RECOMMENDED - No Chrome issues)

1. Open PowerShell in this directory
2. Run the script:
   ```powershell
   .\run_flutter_web.ps1
   ```
3. Wait for "Serving at http://localhost:3000"
4. Open your browser to: **http://localhost:3000**
5. Press Ctrl+C when done

### Option 2: Chrome Mode

1. Open PowerShell in this directory
2. Run the script:
   ```powershell
   .\run_flutter_chrome.ps1
   ```
3. Chrome will launch automatically

---

## Current Issues & Status

### ✅ What's Working

- **Packages Updated**: Analyzer packages updated to latest versions
- **Web Mode**: Works perfectly via web-server mode
- **Chrome Mode**: Works if Chrome isn't already running with Flutter

### ❌ Known Issues

#### 1. flutter_secure_storage Windows Build Issue

**Status**: Windows desktop builds are currently broken due to a symlink issue with `flutter_secure_storage_windows` v2.1.1

**Error**:
```
Cannot open include file: 'include/flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h'
```

**Root Cause**: Windows symlink permissions or Flutter plugin tooling issue

**Workaround**: Use web mode instead (see above)

**Future Fix Options**:
- Upgrade to Flutter 3.36+ when released (may fix symlink handling)
- Replace `flutter_secure_storage` with `shared_preferences` (less secure but works)
- Build on a different Windows machine with different permissions
- Use WSL2 or Linux VM for Windows desktop builds

#### 2. Outdated Packages

**Status**: Some packages can't be upgraded due to breaking changes

Packages stuck on older versions:
- `flutter_secure_storage`: 8.1.0 (latest: 9.2.4) - v9.x breaks Windows builds even worse
- Platform-specific `flutter_secure_storage_*` packages
- `js`: 0.6.7 (discontinued, will be removed in future Flutter versions)

**Impact**: Minimal - these packages are stable and functional

---

## Manual Commands

If you prefer to run commands manually:

### Web Server Mode
```powershell
cd client\flutter_reader
flutter pub get
flutter run -d web-server --web-port=3000
# Then open http://localhost:3000
```

### Chrome Mode
```powershell
cd client\flutter_reader
flutter pub get
flutter run -d chrome
```

### Clean Build
```powershell
flutter clean
flutter pub get
```

---

## Deploying for Non-Technical Users

### Option A: Web App (EASIEST for users)

**What you need**:
1. A web hosting service (Firebase Hosting, Netlify, Vercel, GitHub Pages)
2. Your backend API running somewhere (DigitalOcean, AWS, Heroku, Railway)

**Steps**:

1. **Build the web app**:
   ```powershell
   cd client\flutter_reader
   flutter build web --release
   ```
   Output will be in `build/web/`

2. **Update API URL**:
   - Edit `assets/config/dev.json` to point to your production backend URL
   - Rebuild: `flutter build web --release`

3. **Deploy to hosting**:

   **Firebase Hosting** (recommended - free tier available):
   ```powershell
   npm install -g firebase-tools
   firebase login
   firebase init hosting
   # Select build/web as your public directory
   firebase deploy
   ```

   **Netlify** (easiest):
   - Go to [https://netlify.com](https://netlify.com)
   - Drag and drop the `build/web` folder
   - Done! You get a URL like `yourapp.netlify.app`

   **GitHub Pages** (free for public repos):
   ```powershell
   # Copy build/web/* to your repo's gh-pages branch
   # Enable GitHub Pages in repo settings
   ```

4. **Share the URL with users**:
   - They just open the URL in any browser
   - No installation needed
   - Works on any device (desktop, mobile, tablet)

**Pros**:
- ✅ Zero installation for users
- ✅ Works on any device
- ✅ Easy updates (just redeploy)
- ✅ Free hosting options available

**Cons**:
- ❌ Requires internet connection
- ❌ Need to deploy backend API somewhere

---

### Option B: Windows Executable (NOT WORKING YET)

**Status**: ❌ **BLOCKED** by flutter_secure_storage Windows build issue

**What you need**:
1. Fix the `flutter_secure_storage` issue (see above)
2. OR replace it with `shared_preferences`

**Once fixed, steps would be**:

1. **Build Windows executable**:
   ```powershell
   flutter build windows --release
   ```
   Output in `build\windows\x64\runner\Release\`

2. **Package with Inno Setup**:
   - Download [Inno Setup](https://jrsoftware.org/isinfo.php)
   - Create installer script to bundle:
     - `ancient_languages_app.exe`
     - All DLLs from Release folder
     - `data/` folder with assets
   - Compile installer

3. **Distribute**:
   - Users download single `.exe` installer
   - Double-click to install
   - Launch from Start Menu

**Pros**:
- ✅ Native Windows app
- ✅ Offline capable
- ✅ Feels more "professional"

**Cons**:
- ❌ Currently broken (build error)
- ❌ Large file size (~50-100 MB)
- ❌ Need to rebuild for each platform (Windows, Mac, Linux)
- ❌ Updates require new installer download

---

### Option C: Android APK (WORKS but not tested here)

**What you need**:
1. Android Studio with SDK installed (you have this ✅)
2. Optional: Google Play Developer account ($25 one-time) for Play Store

**Steps**:

1. **Build APK**:
   ```powershell
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

2. **Distribute**:
   - **Direct**: Share the APK file, users sideload it
   - **Play Store**: Upload to Google Play Console

**Pros**:
- ✅ Works on Android phones/tablets
- ✅ Offline capable

**Cons**:
- ❌ Android only
- ❌ Sideloading requires "Unknown sources" enabled
- ❌ Play Store costs $25 + review process

---

## Recommendations for Your Use Case

Based on "non-technical friends & family":

### 🥇 **Best Option: Deploy as Web App**

**Why**:
- No installation needed
- Works on all devices (Windows, Mac, iPhone, Android)
- Easy to update
- Just share a link

**Quick deploy with Netlify**:
1. Build: `flutter build web --release`
2. Go to netlify.com
3. Drag and drop `build/web` folder
4. Get your URL
5. Share with family: "Just open this link: https://yourapp.netlify.app"

**Backend**: Deploy your FastAPI backend to:
- [Railway.app](https://railway.app) (easiest, has free tier)
- [Fly.io](https://fly.io) (free tier)
- [DigitalOcean App Platform](https://www.digitalocean.com/products/app-platform) ($5/month)

---

## Troubleshooting

### "flutter: command not found"
- Flutter not in PATH
- Solution: Reinstall Flutter or add to PATH

### "Chrome failed to launch"
- Chrome already running with debug mode
- Solution: Use web-server mode instead OR close all Chrome instances

### "Port already in use"
- Another process using port 3000
- Solution: Use different port: `flutter run -d web-server --web-port=4000`

### Windows build fails
- Known issue with flutter_secure_storage
- Solution: Use web mode for now

---

## Package Update Status

Last updated: October 2025

| Package | Current | Latest | Status |
|---------|---------|--------|--------|
| flutter_riverpod | 3.0.0 | 3.0.0 | ✅ Up to date |
| http | 1.5.0 | 1.5.0 | ✅ Up to date |
| flutter_secure_storage | 8.1.0 | 9.2.4 | ⚠️ Can't upgrade (breaks Windows) |
| audioplayers | 6.1.0 | 6.1.0 | ✅ Up to date |
| google_fonts | 6.2.1 | 6.2.1 | ✅ Up to date |
| analyzer | 8.3.0 | 8.3.0 | ✅ Updated |

**Verdict**: Your packages are in good shape. The only "outdated" one is `flutter_secure_storage`, but upgrading it makes things worse.

---

## Need Help?

- Flutter docs: https://docs.flutter.dev
- Deployment guides: https://docs.flutter.dev/deployment
- Firebase Hosting: https://firebase.google.com/docs/hosting
- Netlify: https://docs.netlify.com

---

## Developer Notes

### Why Web Mode Works But Windows Build Doesn't

The issue is platform-specific:

- **Web builds**: Use JavaScript - no native plugins needed - builds succeed
- **Windows builds**: Need C++ plugins - `flutter_secure_storage` has a broken symlink - fails

The `flutter_secure_storage_windows` plugin should have:
```
windows/
  include/
    flutter_secure_storage_windows/
      flutter_secure_storage_windows_plugin.h
```

But the build system creates a symlink in `windows/flutter/ephemeral/.plugin_symlinks/` that doesn't resolve correctly, causing the compiler to fail finding the header file.

### Potential Fixes to Try Later

1. **Run as Administrator**: Some report symlink issues are permissions-related
2. **Enable Developer Mode**: Windows 10/11 Developer Mode improves symlink support
3. **WSL2**: Build in Windows Subsystem for Linux
4. **Replace Package**: Use `shared_preferences` instead (less secure but works)
