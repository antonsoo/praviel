# Start the backend server with correct environment variables
# Usage: .\scripts\dev\start_backend.ps1

$ErrorActionPreference = "Stop"

Write-Host "Starting Ancient Languages Backend..." -ForegroundColor Cyan

# Navigate to backend directory
$backendPath = Join-Path $PSScriptRoot "..\..\backend"
Set-Location $backendPath

# Set environment variables
$env:LESSONS_ENABLED = "1"
$env:TTS_ENABLED = "1"
$env:DATABASE_URL = "postgresql+asyncpg://app:app@localhost:5433/ancient_languages"

# Find Python executable
$pythonExe = "C:\ProgramData\anaconda3\envs\praviel\python.exe"

if (-not (Test-Path $pythonExe)) {
    Write-Error "Python not found at: $pythonExe"
    exit 1
}

Write-Host "Using Python: $pythonExe" -ForegroundColor Green
Write-Host "LESSONS_ENABLED: $env:LESSONS_ENABLED" -ForegroundColor Green
Write-Host "DATABASE_URL: $env:DATABASE_URL" -ForegroundColor Green

# Start uvicorn
& $pythonExe -B -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --log-level info
