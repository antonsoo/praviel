Param(
  [string]$TeiPath = ""
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
if (-not $TeiPath) {
  $TeiPath = Join-Path $root "tests\fixtures\perseus_sample_annotated_greek.xml"
}

$alembicIni = Join-Path $root "backend\alembic.ini"
$env:PYTHONPATH = Join-Path $root "backend"
$env:PYTHONIOENCODING = "utf-8"

function Test-NotWindowsApps {
  param([string]$Source)
  return ($Source -and $Source -notlike '*WindowsApps*')
}

function Get-PythonCommand {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if ($python -and (Test-NotWindowsApps $python.Source)) {
    return [pscustomobject]@{ Exe = 'python'; Args = @() }
  }
  $python3 = Get-Command python3 -ErrorAction SilentlyContinue
  if ($python3 -and (Test-NotWindowsApps $python3.Source)) {
    return [pscustomobject]@{ Exe = 'python3'; Args = @() }
  }
  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) {
    return [pscustomobject]@{ Exe = 'py'; Args = @('-3') }
  }
  throw "Python interpreter not found; activate the project environment."
}

$python = Get-PythonCommand
$pythonExe = $python.Exe
$pythonArgs = $python.Args

Write-Host "[MVP] Bringing up DB (docker compose up -d db)"
docker compose up -d db | Out-Host

$timeoutSeconds = 60
Write-Host "[MVP] Waiting for Postgres readiness..."
$remainingAttempts = $timeoutSeconds
while ($true) {
  docker compose exec -T db pg_isready -U postgres -d postgres >$null 2>&1
  if ($LASTEXITCODE -eq 0) { break }
  Start-Sleep -Seconds 1
  $remainingAttempts -= 1
  if ($remainingAttempts -le 0) {
    docker compose logs db --tail 100 | Out-Host
    throw "Database failed to become ready after $timeoutSeconds seconds. Please check the Docker logs above for details."
  }
}

Write-Host "[MVP] Applying migrations"
alembic -c $alembicIni upgrade head | Out-Host

# Use DATABASE_URL if provided; otherwise CLI defaults will kick in (5433).
Write-Host "[MVP] Ingesting TEI sample: $TeiPath"
$runArgs = @()
if ($pythonArgs.Count -gt 0) {
  $runArgs += $pythonArgs
}
$runArgs += @('-m', 'pipeline.perseus_ingest', '--tei', $TeiPath, '--language', 'grc', '--ensure-table')
Write-Host "[MVP] Python command: $pythonExe $($runArgs -join ' ')"
& $pythonExe @runArgs | Out-Host
