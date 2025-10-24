# Simple server startup script
$ErrorActionPreference = "Stop"

Write-Host "Activating conda environment..."
& conda activate praviel

Write-Host "Starting server..."
cd C:\work\projects\praviel_files\praviel\backend

C:\ProgramData\anaconda3\envs\praviel\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
