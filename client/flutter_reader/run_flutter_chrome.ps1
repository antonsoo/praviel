# Run Flutter App in Chrome
# This script launches the Flutter app directly in Chrome browser

Write-Host "=== Ancient Languages App - Chrome Mode ===" -ForegroundColor Cyan
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

# Close all Chrome instances to avoid conflicts
Write-Host "Closing existing Chrome instances..." -ForegroundColor Yellow
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host ""

# Run Flutter in Chrome
Write-Host "Starting Flutter in Chrome..." -ForegroundColor Green
Write-Host "Chrome will launch automatically" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

flutter run -d chrome
