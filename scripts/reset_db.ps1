# scripts/reset_db.ps1
# Drop and recreate public schema, ensure extensions, and run alembic upgrade head
# Usage (from repo root):
#   $py = (Get-Command python).Path
#   pwsh -NoProfile -File .\scripts\reset_db.ps1 `
#       -Database app -DbUser app -DbPass "app" -DbHost localhost -DbPort 5433 `
#       -PythonExe $py

[CmdletBinding()]
param(
    [Parameter()][string]$Database = "app",
    [Parameter()][string]$DbUser   = "app",
    [Parameter()][string]$DbPass   = "app",
    [Parameter()][string]$DbHost   = "localhost",
    [Parameter()][int]$DbPort      = 5433,
    # If omitted we’ll auto-detect the active interpreter (“python”) on PATH
    [Parameter()][string]$PythonExe = $(Get-Command python -ErrorAction Stop).Path
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Resolve repo root and important paths absolutely
$repoRoot   = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot 'backend'
$alembicIni = Join-Path $backendDir 'alembic.ini'
$migrations = Join-Path $backendDir 'migrations'

if (!(Test-Path $alembicIni)) { throw "Alembic ini not found: $alembicIni" }
if (!(Test-Path $migrations)) { throw "Migrations folder not found: $migrations" }

# Set env vars for THIS process so alembic/env.py can read them
$env:PYTHONPATH        = $backendDir
$env:DATABASE_URL      = "postgresql+asyncpg://$($DbUser):$($DbPass)@$($DbHost):$DbPort/$($Database)"
$env:DATABASE_URL_SYNC = "postgresql+psycopg2://$($DbUser):$($DbPass)@$($DbHost):$DbPort/$($Database)"

Write-Host "Using Python: $PythonExe"
Write-Host "PYTHONPATH: $env:PYTHONPATH"
Write-Host "DATABASE_URL_SYNC: $env:DATABASE_URL_SYNC"

# 1) Reset schema
Write-Host "Dropping and recreating public schema..."
& docker compose exec -T db psql -U $DbUser -d $Database -v ON_ERROR_STOP=1 `
  -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" | Write-Host

# 2) Ensure extensions
Write-Host "Recreating extensions (vector, pg_trgm)..."
& docker compose exec -T db psql -U $DbUser -d $Database -v ON_ERROR_STOP=1 `
  -c "CREATE EXTENSION IF NOT EXISTS vector; CREATE EXTENSION IF NOT EXISTS pg_trgm;" | Write-Host

# 3) Run alembic upgrade with absolute -c path, and force CWD to repo root
Write-Host "Running Alembic upgrade..."
Push-Location $repoRoot
try {
    & $PythonExe -m alembic -c $alembicIni upgrade head
    if ($LASTEXITCODE -ne 0) {
        throw "alembic upgrade head failed with exit code $LASTEXITCODE"
    }

    Write-Host "Current Alembic head:"
    & $PythonExe -m alembic -c $alembicIni current
} finally {
    Pop-Location
}

# 4) Inspect tables
Write-Host "Tables in public schema:"
& docker compose exec -T db psql -U $DbUser -d $Database -c "\dt public.*"
