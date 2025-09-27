#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
Set-Location $root

function Get-CondaPythonCommand {
    param([string]$EnvName = 'ancient-languages-py312')
    if ($env:CONDA_DEFAULT_ENV) {
        Write-Host "Using active Conda env: $env:CONDA_DEFAULT_ENV"
        return ,@('python')
    }
    if (Get-Command conda -ErrorAction SilentlyContinue) {
        & conda run -n $EnvName python -c "import sys" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Conda env '$EnvName' not found. Activate it or create it before running this script."
            exit 1
        }
        return ,@('conda', 'run', '-n', $EnvName, 'python')
    }
    Write-Error "Conda not detected and no active Conda env. Install Conda and create/activate '$EnvName'."
    exit 1
}

$pythonCommand = Get-CondaPythonCommand
$pythonExe = $pythonCommand[0]
$pythonPrefixArgs = @()
if ($pythonCommand.Length -gt 1) {
    $pythonPrefixArgs = $pythonCommand[1..($pythonCommand.Length - 1)]
}

$previousUvicornPython = $env:UVICORN_PYTHON
$env:UVICORN_PYTHON = ($pythonCommand -join ' ')

function Invoke-CondaPython {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $allArgs = @()
    if ($pythonPrefixArgs.Count -gt 0) {
        $allArgs += $pythonPrefixArgs
    }
    $allArgs += $Arguments
    & $pythonExe @allArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Python command failed with exit code $LASTEXITCODE"
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    if ($env:FLUTTER_HOME) {
        $flutterBin = Join-Path $env:FLUTTER_HOME 'bin'
        $env:PATH = "$flutterBin;" + $env:PATH
    } else {
        throw 'Flutter SDK not found. Set FLUTTER_HOME or add flutter to PATH.'
    }
}

Write-Host '[demo] Starting Postgres via docker compose'
docker compose up -d db | Out-Null

Write-Host '[demo] Applying migrations'
Invoke-CondaPython -Arguments @('-m', 'alembic', '-c', 'alembic.ini', 'upgrade', 'head')

Push-Location (Join-Path $root 'client/flutter_reader')
flutter pub get | Out-Null
flutter build web --pwa-strategy none --base-href /app/ | Out-Null
Pop-Location

$demoPort = if ($env:DEMO_PORT) { [int]$env:DEMO_PORT } else { 8000 }

$stopScript = { & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') stop | Out-Null }

try {
    $env:LESSONS_ENABLED = '1'
    $env:TTS_ENABLED = '1'
    $env:ALLOW_DEV_CORS = '1'
    if (-not $env:LOG_LEVEL) { $env:LOG_LEVEL = 'INFO' }

    & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') start --flutter --port $demoPort | Out-Host

    $portFile = Join-Path $root 'artifacts/uvicorn.port'
    if (Test-Path $portFile) {
        $portText = (Get-Content $portFile | Select-Object -First 1).Trim()
        if ([int]::TryParse($portText, [ref]$demoPort)) {
            # demoPort updated
        }
    }

    Write-Host "Demo server ready at http://127.0.0.1:$demoPort/app/"
    Write-Host 'Streaming logs. Press Ctrl+C to stop.'

    & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') logs
}
finally {
    & $stopScript
    $env:UVICORN_PYTHON = $previousUvicornPython
}
