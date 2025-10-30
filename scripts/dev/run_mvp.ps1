Param(
  [string]$TeiPath = ""
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
if (-not $TeiPath) {
  $TeiPath = Join-Path $root "tests\fixtures\perseus_sample_annotated_greek.xml"
}

# Import Python resolver for correct Python version detection
. (Join-Path $root 'scripts\common\python_resolver.ps1')

$alembicIni = Join-Path $root "alembic.ini"
$env:PYTHONPATH = Join-Path $root "backend"
$env:PYTHONIOENCODING = "utf-8"
if (-not $env:DATABASE_URL) { $env:DATABASE_URL = "postgresql+psycopg://app:app@localhost:5433/app" }

function Get-PythonCommand {
  $pythonPath = Get-ProjectPythonCommand
  return [pscustomobject]@{ Exe = $pythonPath; Args = @() }
}

$python = Get-PythonCommand
$pythonExe = $python.Exe
$pythonArgs = $python.Args

Write-Host "[MVP] Bringing up DB (docker compose up -d db)"
docker compose up -d db | Out-Host

# Wait for readiness
$timeoutSeconds = [int]([Environment]::GetEnvironmentVariable('DB_READY_TIMEOUT') ?? "60")
Write-Host "[MVP] Waiting for Postgres readiness (timeout: $timeoutSeconds s)..."
$retries = $timeoutSeconds
while ($true) {
  docker compose exec -T db pg_isready -U postgres -d postgres >$null 2>&1
  if ($LASTEXITCODE -eq 0) { break }
  Start-Sleep -Seconds 1
  $retries -= 1
  if ($retries -le 0) {
    docker compose logs db --tail 100 | Out-Host
    throw "Database failed to become ready after $timeoutSeconds seconds. Please check the Docker logs above for details."
  }
}

Write-Host "[MVP] Applying migrations"
$upgradeArgs = @()
if ($pythonArgs.Count -gt 0) { $upgradeArgs += $pythonArgs }
$upgradeArgs += @('-m', 'alembic', '-c', $alembicIni, 'upgrade', 'head')
& $pythonExe @upgradeArgs | Out-Host

# Use DATABASE_URL if provided; otherwise CLI defaults will kick in (5433).
Write-Host "[MVP] Ingesting TEI sample: $TeiPath"
$runArgs = @()
if ($pythonArgs.Count -gt 0) { $runArgs += $pythonArgs }
$runArgs += @('-m', 'pipeline.perseus_ingest', '--tei', $TeiPath, '--language', 'grc', '--ensure-table')
Write-Host "[MVP] Python command: $pythonExe $($runArgs -join ' ')"
& $pythonExe @runArgs | Out-Host
