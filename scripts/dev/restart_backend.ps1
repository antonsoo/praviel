# Restart Backend Server
# Kills all Python uvicorn processes and restarts backend on port 8001

Write-Host "=== Restarting Backend Server ===" -ForegroundColor Cyan

# Kill all Python processes running uvicorn
Write-Host "Stopping existing backend servers..." -ForegroundColor Yellow
Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like '*uvicorn*'
} | ForEach-Object {
    Write-Host "  Killing PID $($_.Id)" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# Wait a moment for ports to release
Start-Sleep -Seconds 2

# Load environment variables from backend/.env
$envPath = Join-Path $PSScriptRoot "..\..\backend\.env"
if (Test-Path $envPath) {
    Write-Host "Loading environment from backend/.env..." -ForegroundColor Yellow
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
} else {
    Write-Host "WARNING: backend/.env not found at $envPath" -ForegroundColor Red
}

# Find Python in conda environment
$pythonPath = "C:/ProgramData/anaconda3/envs/praviel/python.exe"
if (-not (Test-Path $pythonPath)) {
    Write-Host "ERROR: Python not found at $pythonPath" -ForegroundColor Red
    exit 1
}

# Start backend server
Write-Host "Starting backend server on port 8001..." -ForegroundColor Green
$backendPath = Join-Path $PSScriptRoot "..\..\backend"
Set-Location $backendPath

& $pythonPath -B -m uvicorn app.main:app --host 0.0.0.0 --port 8001
