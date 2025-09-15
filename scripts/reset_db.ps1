<# 
Resets the Postgres schema and reapplies Alembic migrations.

Usage:
  pwsh -NoProfile -File .\scripts\reset_db.ps1 `
      -Database app -DbUser app -DbPass "app" -DbHost localhost -DbPort 5433 `
      -PythonExe (Get-Command python).Path

Notes:
- Requires Docker Desktop running and the compose service 'db' defined at repo root.
#>

[CmdletBinding()]
param(
  [string]$Database = "app",
  [string]$DbUser   = "app",
  [string]$DbPass   = "app",
  [string]$DbHost   = "localhost",
  [int]   $DbPort   = 5433,
  [string]$PythonExe = $null,
  [switch]$AutoStart = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Resolve repo root = parent of scripts folder
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent
Push-Location $RepoRoot
try {
  # ---- sanity: docker available? ----
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI not found in PATH. Install Docker Desktop or add 'docker' to PATH."
  }

  # ---- sanity: docker engine up? ----
  try {
    docker info --format '{{json .ServerVersion}}' | Out-Null
  } catch {
    throw "Docker Engine is not running. Please start Docker Desktop and retry."
  }

  # ---- ensure db service is up (optionally auto-start) ----
  function Get-ComposeServices([string]$status) {
    # Avoid JSON formatting inconsistencies across compose versions
    $services = docker compose ps --services --filter "status=$status" 2>$null
    if ($services) { $services -split "`r?`n" | Where-Object { $_ } } else { @() }
  }

  $running = Get-ComposeServices "running"
  if ($running -notcontains "db") {
    if ($AutoStart) {
      Write-Host "Starting compose service 'db'..."
      docker compose up -d db | Out-Null
    } else {
      throw "Compose service 'db' is not running. Start it with: docker compose up -d db"
    }
  }

  # ---- wait for postgres readiness (inside the container; default port 5432 in-container) ----
  Write-Host "Waiting for Postgres to become ready..."
  $ok = $false
  for ($i = 1; $i -le 30; $i++) {
    try {
      docker compose exec -T db pg_isready -U $DbUser -d $Database | Out-Null
      $ok = $true; break
    } catch { Start-Sleep -Seconds 1 }
  }
  if (-not $ok) { throw "Postgres did not become ready in time." }

  # ---- drop & recreate public schema ----
  Write-Host "Dropping and recreating public schema..."
  docker compose exec -T db psql -v ON_ERROR_STOP=1 -U $DbUser -d $Database `
    -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" | Write-Host

  # ---- ensure extensions ----
  Write-Host "Recreating extensions (vector, pg_trgm)..."
  docker compose exec -T db psql -v ON_ERROR_STOP=1 -U $DbUser -d $Database `
    -c "CREATE EXTENSION IF NOT EXISTS vector; CREATE EXTENSION IF NOT EXISTS pg_trgm;" | Write-Host

  # ---- alembic migrate (host connects via mapped $DbPort) ----
  if (-not $PythonExe) { $PythonExe = (Get-Command python).Path }
  Write-Host "Using Python: $PythonExe"

  $env:PYTHONPATH        = (Resolve-Path .\backend).Path
  $env:DATABASE_URL_SYNC = "postgresql+psycopg2://${DbUser}:${DbPass}@${DbHost}:${DbPort}/${Database}"
  Write-Host "PYTHONPATH: $env:PYTHONPATH"
  Write-Host "DATABASE_URL_SYNC: $env:DATABASE_URL_SYNC"

  Write-Host "Running Alembic upgrade..."
  & $PythonExe -m alembic -c "$RepoRoot\backend\alembic.ini" upgrade head
  if ($LASTEXITCODE -ne 0) {
    throw "alembic upgrade head failed with exit code $LASTEXITCODE"
  }

  Write-Host "Current Alembic head:"
  & $PythonExe -m alembic -c "$RepoRoot\backend\alembic.ini" current

  Write-Host "Tables in public schema:"
  docker compose exec -T db psql -U $DbUser -d $Database -c "\dt public.*"

} finally {
  Pop-Location
}
