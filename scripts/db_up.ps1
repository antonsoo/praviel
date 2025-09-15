[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent
Push-Location $RepoRoot
try {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI not found in PATH."
  }
  docker info --format '{{json .ServerVersion}}' | Out-Null

  docker compose up -d db | Out-Null

  Write-Host "Waiting for Postgres..."
  for ($i=1; $i -le 30; $i++) {
    try {
      docker compose exec -T db pg_isready -U app -d app | Out-Null
      Write-Host "Postgres is ready."
      break
    } catch { Start-Sleep -s 1 }
    if ($i -eq 30) { throw "Postgres did not become ready in time." }
  }
} finally {
  Pop-Location
}
