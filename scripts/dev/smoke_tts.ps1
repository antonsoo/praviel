#!/usr/bin/env pwsh

param()

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
$script:PythonExe = $pythonCommand[0]
$script:PythonPrefixArgs = @()
if ($pythonCommand.Length -gt 1) {
    $script:PythonPrefixArgs = $pythonCommand[1..($pythonCommand.Length - 1)]
}

function Invoke-CondaPython {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $allArgs = @()
    if ($script:PythonPrefixArgs.Count -gt 0) {
        $allArgs += $script:PythonPrefixArgs
    }
    $allArgs += $Arguments
    & $script:PythonExe @allArgs
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
$env:LOG_LEVEL = 'INFO'
$env:PYTHONPATH = (Join-Path $root 'backend')

Write-Host 'Starting database container...'
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

$uvicornArgs = @()
if ($script:PythonPrefixArgs.Count -gt 0) {
    $uvicornArgs += $script:PythonPrefixArgs
}
$uvicornArgs += @('-m','uvicorn','app.main:app','--app-dir', (Join-Path $root 'backend'),'--host','127.0.0.1','--port','8000')
$apiProcess = Start-Process -FilePath $script:PythonExe -ArgumentList $uvicornArgs -PassThru -WindowStyle Hidden

try {
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8000/health' | Out-Null
            $ready = $true
            break
        } catch {
            Start-Sleep -Seconds 1
        }
    }
    if (-not $ready) {
        throw 'API failed to become ready within timeout.'
    }

    $body = '{"text":"χαῖρε κόσμε","provider":"echo"}'
    $response = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8000/tts/speak' -ContentType 'application/json' -Body $body
    $jsonPath = Join-Path $artifacts 'tts_echo.json'
    $response | ConvertTo-Json -Depth 4 | Out-File $jsonPath -Encoding utf8

    $audioPath = Join-Path $artifacts 'tts_echo.wav'
    $bytes = [Convert]::FromBase64String($response.audio.b64)
    [IO.File]::WriteAllBytes($audioPath, $bytes)

    Write-Host "TTS smoke complete. Saved JSON to $jsonPath and audio to $audioPath."
}
finally {
    if ($apiProcess -and -not $apiProcess.HasExited) {
        try { Stop-Process -Id $apiProcess.Id -Force } catch { }
    }
    docker compose down | Out-Null
    Remove-Item Env:TTS_ENABLED -ErrorAction SilentlyContinue
    Remove-Item Env:ALLOW_DEV_CORS -ErrorAction SilentlyContinue
    Remove-Item Env:LOG_LEVEL -ErrorAction SilentlyContinue
    Remove-Item Env:PYTHONPATH -ErrorAction SilentlyContinue
}
