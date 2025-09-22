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

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    if ($env:FLUTTER_HOME) {
        $flutterBin = Join-Path $env:FLUTTER_HOME 'bin'
        $env:PATH = "$flutterBin;" + $env:PATH
    } else {
        throw 'Flutter SDK not found. Set FLUTTER_HOME or add flutter to PATH.'
    }
}

docker compose up -d db
Invoke-CondaPython -Arguments @('-m', 'alembic', '-c', 'alembic.ini', 'upgrade', 'head')

Push-Location client/flutter_reader
flutter build web
Pop-Location

$env:PYTHONPATH = (Join-Path $root 'backend')
$env:SERVE_FLUTTER_WEB = '1'
$env:ALLOW_DEV_CORS = '1'
$env:LESSONS_ENABLED = '1'
$env:LOG_LEVEL = 'INFO'

Invoke-CondaPython -Arguments @(
    '-m', 'uvicorn',
    'app.main:app',
    '--app-dir', (Join-Path $root 'backend'),
    '--reload',
    '--host', '127.0.0.1',
    '--port', '8000'
)
