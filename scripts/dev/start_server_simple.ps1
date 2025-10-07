# Simple server startup script
$ErrorActionPreference = "Stop"

Write-Host "Activating conda environment..."
& conda activate ancient-languages-py312

Write-Host "Starting server..."
cd C:\Dev\AI_Projects\AncientLanguagesAppDirs\Current-working-dirs\AncientLanguages\backend

C:\ProgramData\anaconda3\envs\ancient-languages-py312\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
