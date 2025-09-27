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

$prevUvicornPython = $env:UVICORN_PYTHON
if ($pythonPrefixArgs.Count -gt 0) {
    $env:UVICORN_PYTHON = ($pythonCommand -join ' ')
} else {
    $env:UVICORN_PYTHON = $pythonExe
}

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

$artifacts = Join-Path $root 'artifacts'
if (-not (Test-Path $artifacts)) {
    New-Item -ItemType Directory -Path $artifacts | Out-Null
}

$env:TTS_ENABLED = '1'
$env:ALLOW_DEV_CORS = '1'
if (-not $env:LOG_LEVEL) { $env:LOG_LEVEL = 'INFO' }

$withDb = $true
if ($env:SMOKE_TTS_DB -and $env:SMOKE_TTS_DB -eq '0') {
    $withDb = $false
}

if ($withDb) {
    docker compose up -d db | Out-Null
    $databaseReady = $false
    for ($i = 0; $i -lt 30; $i++) {
        docker compose exec -T db pg_isready -U app -d app >$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            $databaseReady = $true
            break
        }
        Start-Sleep -Seconds 1
    }
    if (-not $databaseReady) {
        docker compose down | Out-Null
        throw 'Database failed to become ready within timeout.'
    }
    Invoke-CondaPython -Arguments @('-m', 'alembic', '-c', 'alembic.ini', 'upgrade', 'head')
}

try {
    & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') start --port 8000 --log-level info | Out-Host

    $portFile = Join-Path $root 'artifacts/uvicorn.port'
    $portValue = 8000
    if (Test-Path $portFile) {
        $raw = (Get-Content $portFile | Select-Object -First 1).Trim()
        [void][int]::TryParse($raw, [ref]$portValue)
    }

    $body = @{ text = '????? ?????'; provider = 'echo' } | ConvertTo-Json
    $uri = "http://127.0.0.1:$portValue/tts/speak"
    $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json'
    $response | ConvertTo-Json -Depth 6 | Out-File (Join-Path $artifacts 'tts_echo.json') -Encoding utf8

    $audioBytes = [System.Convert]::FromBase64String($response.audio.b64)
    [System.IO.File]::WriteAllBytes((Join-Path $artifacts 'tts_echo.wav'), $audioBytes)

    Write-Host "TTS smoke complete. Artifacts written to $artifacts."
}
finally {
    & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') stop | Out-Null
    if ($withDb) {
        docker compose down | Out-Null
    }
    $env:UVICORN_PYTHON = $prevUvicornPython
}
