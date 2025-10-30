# Run Flutter App in Web Mode
# This script launches the Flutter app in web-server mode (no Chrome dependency)
# You can then open http://localhost:3000 in any browser

Write-Host "=== Ancient Languages App - Web Mode ===" -ForegroundColor Cyan
Write-Host ""

# Navigate to the Flutter app directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Check if Flutter is installed
$flutterVersion = flutter --version 2>&1 | Select-String -Pattern "Flutter"
if (-not $flutterVersion) {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev" -ForegroundColor Yellow
    exit 1
}

Write-Host "Flutter is installed: $flutterVersion" -ForegroundColor Green
Write-Host ""

# Clean previous builds if requested
if ($args -contains "--clean") {
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    flutter clean
    Write-Host ""
}

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host ""

# Kill any existing Flutter web servers on port 3000
$existingProcess = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($existingProcess) {
    Write-Host "Killing existing process on port 3000..." -ForegroundColor Yellow
    $processId = $existingProcess.OwningProcess
    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Run Flutter in web-server mode
Write-Host "Starting Flutter web server..." -ForegroundColor Green
Write-Host "Once ready, open your browser to: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

flutter run -d web-server --web-port=3000 --web-hostname=localhost
