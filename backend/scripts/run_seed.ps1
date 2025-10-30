# Run seed_reader_texts.py with proper Python environment
$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Split-Path -Parent $ScriptDir

Write-Host "Activating conda environment..." -ForegroundColor Cyan
conda activate praviel

Write-Host "Running seeder from: $BackendDir..." -ForegroundColor Cyan
Set-Location $BackendDir
$SeederScript = Join-Path $BackendDir "scripts" "seed_reader_texts.py"
Write-Host "Seeder script path: $SeederScript" -ForegroundColor Cyan
python $SeederScript

if ($LASTEXITCODE -eq 0) {
    Write-Host "Seeder completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Seeder failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
