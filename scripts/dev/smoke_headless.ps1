#!/usr/bin/env pwsh

param([bool]$Lessons = $true)

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

$env:LESSONS_ENABLED = $Lessons ? '1' : '0'
$env:ALLOW_DEV_CORS = '1'
$env:LOG_LEVEL = 'INFO'

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

    $readerResponse = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/reader/analyze?include={""lsj"":true,""smyth"":true}" -ContentType 'application/json' -Body '{"q":"Μῆνιν ἄειδε"}'
    $readerResponse | ConvertTo-Json -Depth 6 | Out-File (Join-Path $artifacts 'reader_analyze.json') -Encoding utf8

    if ($Lessons) {
        $lessonBody = '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":1,"include_audio":false,"provider":"echo"}'
        $lessonResponse = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8000/lesson/generate' -ContentType 'application/json' -Body $lessonBody
        $lessonResponse | ConvertTo-Json -Depth 6 | Out-File (Join-Path $artifacts 'lesson_generate.json') -Encoding utf8
    }

    Write-Host 'Headless smoke complete. Artifacts written to ./artifacts.'
}
finally {
    if ($apiProcess -and -not $apiProcess.HasExited) {
        try { Stop-Process -Id $apiProcess.Id -Force } catch { }
    }
    docker compose down | Out-Null
}
