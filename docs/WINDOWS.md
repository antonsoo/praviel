# Windows Setup Guide

Platform-specific instructions for running Ancient Languages on Windows.

**🎯 New to the project?** See [BIG-PICTURE_PROJECT_PLAN.md](../BIG-PICTURE_PROJECT_PLAN.md) for the vision and language roadmap.

## Prerequisites

### Required
- **Conda** (Miniconda/Miniforge recommended): [Download](https://docs.conda.io/en/latest/miniconda.html)
- **Docker Desktop**: [Download](https://www.docker.com/products/docker-desktop/)
- **Git for Windows**: [Download](https://git-scm.com/download/win)

### Optional (for Flutter client)
- **Flutter SDK** 3.35.4+ stable: [Install Guide](https://docs.flutter.dev/get-started/install/windows)
- **Chrome** or **Edge** browser

## Python Environment

### Option 1: Conda (Recommended)

```powershell
conda create -y -n ancient python=3.12
conda activate ancient
pip install -U pip
pip install -e ".[dev]"
```

### Option 2: venv

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -U pip
pip install -e ".[dev]"
```

## Running the Backend

### The PYTHONPATH Issue

Windows requires setting `PYTHONPATH` for uvicorn's auto-reloader to find the app module.

**Solution 1 - Set PYTHONPATH:**
```powershell
$env:PYTHONPATH = (Resolve-Path .\backend).Path
uvicorn app.main:app --reload
```

**Solution 2 - Use --app-dir:**
```powershell
uvicorn --app-dir .\backend app.main:app --reload
```

## Flutter Setup (Windows)

### 1. Install Flutter

Download Flutter SDK and extract to a permanent location (e.g., `C:\tools\flutter`).

### 2. Add to PATH

Add `C:\tools\flutter\bin` to your **User PATH**:
1. Search "Environment Variables" in Start Menu
2. Edit "User variables" → "Path"
3. Add new entry: `C:\tools\flutter\bin`
4. Click OK and **restart your terminal**

### 3. Configure Chrome

If Chrome isn't in the default location:
```powershell
setx CHROME_EXECUTABLE "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

**Important**: Open a **NEW terminal** after setting environment variables.

### 4. Verify Installation

```powershell
flutter --version
flutter doctor -v
```

### 5. Run Flutter App

```powershell
cd client\flutter_reader
flutter pub get
flutter run -d chrome
```

**Alternative** (if browser won't auto-launch):
```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 0
```

## Android Setup (Optional)

### 1. Install Android Studio

Download from [developer.android.com](https://developer.android.com/studio)

### 2. Configure Flutter

```powershell
flutter config --android-sdk "%LOCALAPPDATA%\Android\sdk"
```

### 3. Accept Licenses

```powershell
cd "%LOCALAPPDATA%\Android\sdk\cmdline-tools\latest\bin"
sdkmanager --licenses
```

### 4. Verify

```powershell
flutter doctor -v  # Should show Android toolchain as configured
```

## Common Issues

### Git Line Endings

This repo enforces LF line endings. If you see CRLF warnings:

```powershell
git config core.autocrlf false
git config core.eol lf
```

Then re-clone or reset line endings:
```powershell
git rm --cached -r .
git reset --hard
```

### PowerShell Execution Policy

If scripts won't run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Docker Desktop Not Starting

1. Enable WSL 2: `wsl --install`
2. Restart computer
3. Open Docker Desktop
4. Settings → General → "Use WSL 2 based engine"

### Port 5433 Already in Use

Check if another Postgres instance is running:
```powershell
netstat -ano | findstr :5433
```

Kill the process or change the port in `docker-compose.yml`.

### pre-commit Hooks Failing

Ensure you're using LF line endings:
```powershell
pre-commit run --all-files
git add -u  # Re-stage fixed files
```

## Development Scripts

All scripts have PowerShell versions (`.ps1` extension):

```powershell
# Orchestrator
scripts/dev/orchestrate.ps1 up
scripts/dev/orchestrate.ps1 smoke
scripts/dev/orchestrate.ps1 e2e-web
scripts/dev/orchestrate.ps1 down

# Smoke tests
scripts/dev/smoke_lessons.ps1
scripts/dev/smoke_tts.ps1
scripts/dev/smoke_headless.ps1

# Flutter
scripts/dev/analyze_flutter.ps1
scripts/dev/run_demo.ps1

# Data fetching
scripts/fetch_data.ps1
```

## Environment Variables Quick Reference

Set temporarily (current session):
```powershell
$env:VARIABLE_NAME = "value"
```

Set permanently (requires new terminal):
```powershell
setx VARIABLE_NAME "value"
```

## Git Bash Alternative

If you prefer Unix-style commands, use **Git Bash** (included with Git for Windows):
- Use `.sh` scripts instead of `.ps1`
- Use Unix commands (`source`, `export`, etc.)
- Line endings handled automatically

## Performance Tips

### WSL 2 Performance

Keep your project on the WSL 2 filesystem (not `/mnt/c/`) for better Docker performance:

```bash
# In WSL 2 terminal
cd ~
git clone <repo-url>
code .  # Opens VS Code with WSL remote
```

### Antivirus Exclusions

Add these to Windows Defender exclusions for faster builds:
- Your project directory
- `C:\Users\<username>\.conda`
- Docker Desktop data directory

## Next Steps

- Return to [Quick Start Guide](QUICKSTART.md) for setup instructions
- See [Main README](../README.md) for feature documentation
