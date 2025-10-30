# Build Flutter Web for Production Deployment
# This script builds the Flutter web app for deployment to Cloudflare Pages

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Flutter Web Production Build" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to Flutter project directory
$FlutterProjectDir = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "client") "flutter_reader"

if (-not (Test-Path $FlutterProjectDir)) {
    Write-Host "Error: Flutter project directory not found at $FlutterProjectDir" -ForegroundColor Red
    exit 1
}

Write-Host "Navigating to Flutter project: $FlutterProjectDir" -ForegroundColor Yellow
Set-Location $FlutterProjectDir

# Check Flutter installation
Write-Host ""
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev" -ForegroundColor Yellow
    exit 1
}
Write-Host $flutterVersion -ForegroundColor Green

# Check current Flutter channel
Write-Host ""
Write-Host "Checking Flutter channel..." -ForegroundColor Yellow
$currentChannel = flutter channel 2>&1 | Select-String -Pattern "\*\s+(\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }
Write-Host "Current channel: $currentChannel" -ForegroundColor Green

if ($currentChannel -ne "beta") {
    Write-Host ""
    Write-Host "WARNING: You are on the '$currentChannel' channel, but this project requires BETA channel." -ForegroundColor Yellow
    Write-Host "The project uses flutter_secure_storage 10.0.0-beta.4 which requires beta channel." -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Do you want to switch to beta channel now? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "Switching to beta channel..." -ForegroundColor Yellow
        flutter channel beta
        flutter upgrade
    } else {
        Write-Host "Continuing with current channel. Build may fail." -ForegroundColor Yellow
    }
}

# Clean previous builds
Write-Host ""
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: flutter clean failed" -ForegroundColor Red
    exit 1
}

# Get dependencies
Write-Host ""
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: flutter pub get failed" -ForegroundColor Red
    exit 1
}

# Build for web
Write-Host ""
Write-Host "Building Flutter web (release mode)..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray
flutter build web --release --verbose
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: flutter build web failed" -ForegroundColor Red
    exit 1
}

# Check build output
$buildOutput = Join-Path (Join-Path $FlutterProjectDir "build") "web"
if (-not (Test-Path $buildOutput)) {
    Write-Host "Error: Build output directory not found at $buildOutput" -ForegroundColor Red
    exit 1
}

# Get build size
$buildSize = (Get-ChildItem -Path $buildOutput -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$fileCount = (Get-ChildItem -Path $buildOutput -Recurse -File | Measure-Object).Count

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Build output: $buildOutput" -ForegroundColor Cyan
Write-Host "Build size: $([math]::Round($buildSize, 2)) MB" -ForegroundColor Cyan
Write-Host "File count: $fileCount files" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cloudflare Pages limits:" -ForegroundColor Yellow
Write-Host "  - Maximum file size: 25 MB per file" -ForegroundColor Yellow
Write-Host "  - Maximum files: 20,000 files" -ForegroundColor Yellow
Write-Host ""

# Check for oversized files
Write-Host "Checking for oversized files (>25 MB)..." -ForegroundColor Yellow
$oversizedFiles = Get-ChildItem -Path $buildOutput -Recurse -File | Where-Object { $_.Length -gt 25MB }
if ($oversizedFiles) {
    Write-Host "WARNING: The following files exceed 25 MB and will fail Cloudflare Pages upload:" -ForegroundColor Red
    $oversizedFiles | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  - $($_.Name): $sizeMB MB" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "You may need to optimize these files before deployment." -ForegroundColor Yellow
} else {
    Write-Host "All files are within size limits." -ForegroundColor Green
}

Write-Host ""
if ($fileCount -gt 20000) {
    Write-Host "WARNING: File count ($fileCount) exceeds Cloudflare Pages limit (20,000)." -ForegroundColor Red
    Write-Host "You will need to reduce the number of files before deployment." -ForegroundColor Yellow
} else {
    Write-Host "File count is within Cloudflare Pages limits." -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Navigate to Cloudflare Dashboard > Workers & Pages" -ForegroundColor White
Write-Host "  2. Create application > Pages > Upload assets" -ForegroundColor White
Write-Host "  3. Upload all files from: $buildOutput" -ForegroundColor White
Write-Host "  4. Deploy!" -ForegroundColor White
Write-Host ""
Write-Host "For detailed deployment instructions, see: docs/DEPLOYMENT.md" -ForegroundColor Cyan
Write-Host ""
