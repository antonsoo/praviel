# scripts/reset_db.ps1
# Usage example (from repo root):
#   pwsh ./scripts/reset_db.ps1 -Db app -User app -Password "app" -DbHost localhost -Port 5433
#
# Requirements:
#   1) Docker Compose v2 (`docker compose`) and a Postgres service named "db" already running.
#   2) Your conda/venv active so `python -m alembic` resolves to the right Python.
#
# What this does:
#   - Drops and recreates the public schema inside the "app" database (not the DB itself).
#   - Re-creates the pgvector and pg_trgm extensions.
#   - Sets DATABASE_URL / DATABASE_URL_SYNC and runs Alembic upgrade head.
#   - Shows a quick schema sanity check at the end.

[CmdletBinding()]
param(
  [string]$Db       = "app",
  [string]$User     = "app",
  [string]$Password = "",
  [string]$DbHost   = "localhost",
  [int]   $Port     = 5433
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
  Write-Host "==> $msg" -ForegroundColor Cyan
}

# Resolve repo root (this script is expected to live at ./scripts/reset_db.ps1)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
Set-Location $RepoRoot

# Build connection URLs safely (escape password for use in URL)
$pwEsc = if ($Password -ne "") { [System.Uri]::EscapeDataString($Password) } else { "" }
$auth  = if ($pwEsc -ne "") { "$($User):$pwEsc" } else { "$($User)" }

$env:DATABASE_URL      = "postgresql+asyncpg://$auth@$($DbHost):$($Port)/$($Db)"
$env:DATABASE_URL_SYNC = "postgresql+psycopg2://$auth@$($DbHost):$($Port)/$($Db)"

Write-Step "Dropping and recreating public schema in database '$Db'..."
docker compose exec -T db psql -U $User -d $Db -v ON_ERROR_STOP=1 -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;"

Write-Step "Recreating extensions (vector, pg_trgm)..."
docker compose exec -T db psql -U $User -d $Db -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS vector; CREATE EXTENSION IF NOT EXISTS pg_trgm;"

# Make sure Alembic can import your code. We run it via `python -m alembic` so it uses the current Python/conda env.
Write-Step "Running Alembic upgrade to head..."
python -m alembic -c backend/alembic.ini upgrade head

# Quick sanity checks
Write-Step "Installed extensions:"
docker compose exec -T db psql -U $User -d $Db -c "SELECT extname FROM pg_extension ORDER BY 1;"

Write-Step "Public schema relations:"
docker compose exec -T db psql -U $User -d $Db -c "\dt public.*"

Write-Step "Describe 'public.language' (if present):"
docker compose exec -T db psql -U $User -d $Db -c "\d+ public.language"

Write-Host "Done." -ForegroundColor Green
