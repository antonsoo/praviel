[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('up','smoke','e2e-web','down','status','logs')]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
$artifactDir = Join-Path $root 'artifacts'
$statePath = Join-Path $artifactDir 'orchestrate_state.json'
$serveScript = Join-Path $root 'scripts/dev/serve_uvicorn.ps1'
$stepRunner = Join-Path $root 'scripts/dev/step.ps1'
$pidPath = Join-Path $artifactDir 'uvicorn.pid'
$portPath = Join-Path $artifactDir 'uvicorn.port'
$defaultIdleTimeout = if ([string]::IsNullOrWhiteSpace($env:STEP_IDLE_TIMEOUT)) { '120' } else { $env:STEP_IDLE_TIMEOUT }
$defaultHardTimeout = if ([string]::IsNullOrWhiteSpace($env:STEP_HARD_TIMEOUT)) { '900' } else { $env:STEP_HARD_TIMEOUT }

New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
function Show-Usage {
@"
Usage: orchestrate.ps1 <start|stop|status|logs>

Commands:
  up [options]         Bring up dependencies, apply migrations, launch API, and record state.
  smoke                Run API contract smokes against the live server.
  e2e-web [options]    Run headless Flutter web integration tests against the live server.
  down [--keep-db]     Stop the API server and docker compose services (optionally keep db container).
  status               Show orchestrator state and server health.
  logs                 Tail the latest uvicorn log via serve helper.
"@
}

function Require-State {
    if (-not (Test-Path $statePath)) {
        throw "orchestrator state not found; run 'orchestrate.ps1 up' first"
    }
}

function Write-State {
    param(
        [Parameter(Mandatory = $true)][string]$BindHost,
        [Parameter(Mandatory = $true)][string]$Port,
        [Parameter(Mandatory = $true)][string]$ProcessId,
        [string]$LogFile
    )
    $state = [ordered]@{
        host        = $BindHost
        port        = [int]$Port
        pid         = [int]$ProcessId
        log_file    = $LogFile
        artifacts   = $artifactDir
        started_at  = [DateTime]::UtcNow.ToString('o')
    }
    $state | ConvertTo-Json -Depth 4 | Set-Content -Path $statePath -Encoding UTF8
}

function Resolve-BaseUrl {
    if (-not (Test-Path $statePath)) {
        return 'http://127.0.0.1:8000'
    }
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    $resolvedHost = if ($state.host) { $state.host } else { '127.0.0.1' }
    $resolvedPort = if ($state.port) { $state.port } else { 8000 }
    return ("http://{0}:{1}" -f $resolvedHost, $resolvedPort)
}

function Wait-ForDb {
    $ready = $false

    if ($env:ORCHESTRATE_SKIP_DB -eq "1") {
        $host = if ($env:ORCHESTRATE_DB_HOST) { $env:ORCHESTRATE_DB_HOST } else { '127.0.0.1' }
        $port = if ($env:ORCHESTRATE_DB_PORT) { [int]$env:ORCHESTRATE_DB_PORT } else { 5432 }
        Wait-ForTcp -TargetHost $host -TargetPort $port -TimeoutSeconds 30
        $ready = $true
    } else {
        for ($attempt = 0; $attempt -lt 30; $attempt++) {
            try {
                docker compose exec -T db pg_isready -U app -d app *> $null
                $ready = $true
                break
            } catch {
                Start-Sleep -Seconds 1
            }
        }
    }

    if (-not $ready) {
        throw "database failed to become ready"
    }

    Write-Output "::DBREADY::OK"
}
function Get-DbEndpoint {
    $mapping = docker compose port db 5432 2>$null | Select-Object -First 1
    if (-not $mapping) {
        return @{ Host = '127.0.0.1'; Port = 5433 }
    }
    $value = $mapping.Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        return @{ Host = '127.0.0.1'; Port = 5433 }
    }
    $lastColon = $value.LastIndexOf(':')
    if ($lastColon -lt 0 -or $lastColon -ge $value.Length - 1) {
        return @{ Host = '127.0.0.1'; Port = 5433 }
    }
    $hostValue = $value.Substring(0, $lastColon)
    $portValue = $value.Substring($lastColon + 1)
    if ($hostValue.StartsWith('[') -and $hostValue.EndsWith(']')) {
        $hostValue = $hostValue.Substring(1, $hostValue.Length - 2)
    }
    if ($hostValue -eq '0.0.0.0') { $hostValue = '127.0.0.1' }
    return @{ Host = $hostValue; Port = [int]$portValue }
}

function Wait-ForTcp {
    param(
        [Parameter(Mandatory = $true)][string]$TargetHost,
        [Parameter(Mandatory = $true)][int]$TargetPort,
        [int]$TimeoutSeconds = 30
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $client = $null
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $task = $client.ConnectAsync($TargetHost, $TargetPort)
            if ($task.Wait(1000) -and $client.Connected) {
                return
            }
        } catch {
        } finally {
            if ($client) { $client.Dispose() }
        }
        Start-Sleep -Milliseconds 500
    }
    throw "port ${TargetHost}:${TargetPort} did not become reachable"
}

function Resolve-Python {
    $candidates = @('python', 'python3')
    foreach ($name in $candidates) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command -and $command.Source -and -not ($command.Source -like '*WindowsApps*')) {
            return $command.Source
        }
    }
    throw "python executable not found"
}

function Save-Env {
    param([string[]]$Keys)
    $snapshot = @{}
    foreach ($key in $Keys) {
        $snapshot[$key] = if (Test-Path "Env:$key") { (Get-Item "Env:$key").Value } else { $null }
    }
    return $snapshot
}

function Restore-Env {
    param([hashtable]$Snapshot)
    foreach ($entry in $Snapshot.GetEnumerator()) {
        if ($null -eq $entry.Value) {
            Remove-Item "Env:$($entry.Key)" -ErrorAction SilentlyContinue
        } else {
            Set-Item "Env:$($entry.Key)" $entry.Value
        }
    }
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$IdleTimeout,
        [string]$HardTimeout,
        [Parameter(Mandatory = $true)][string[]]$Command
    )

    if (-not $Command -or $Command.Count -eq 0) {
        throw "step '$Name' requires a command"
    }
    $idle = if ($PSBoundParameters.ContainsKey("IdleTimeout")) { $IdleTimeout } else { $defaultIdleTimeout }
    $hard = if ($PSBoundParameters.ContainsKey("HardTimeout")) { $HardTimeout } else { $defaultHardTimeout }
    $logPath = Join-Path $artifactDir ("step_{0}.log" -f $Name)
    $heartbeatPath = Join-Path $artifactDir ("step_{0}.hb" -f $Name)
    $args = @('--name', $Name, '--log', $logPath, '--heartbeat', $heartbeatPath, '--idle-timeout', $idle, '--hard-timeout', $hard, '--') + $Command
    & $stepRunner @args
    if ($LASTEXITCODE -ne 0) {
        throw "step '$Name' failed with exit code $LASTEXITCODE"
    }
}
function Invoke-Up {
    param([string[]]$Args)

    $port = '8000'
    $bindHost = '127.0.0.1'
    $flutter = $false
    $logLevel = 'info'

    $index = 0
    while ($index -lt $Args.Count) {
        switch ($Args[$index]) {
            '--port' {
                if ($index + 1 -ge $Args.Count) { throw "--port requires a value" }
                $port = $Args[$index + 1]
                $index += 2
            }
            '--host' {
                if ($index + 1 -ge $Args.Count) { throw "--host requires a value" }
                $bindHost = $Args[$index + 1]
                $index += 2
            }
            '--flutter' {
                $flutter = $true
                $index += 1
            }
            '--log-level' {
                if ($index + 1 -ge $Args.Count) { throw "--log-level requires a value" }
                $logLevel = $Args[$index + 1]
                $index += 2
            }
            '--help' { Show-Usage; return }
            '-h' { Show-Usage; return }
            default { throw "unknown option for up: $($Args[$index])" }
        }
    }

    Push-Location -LiteralPath $root
    $cleanupNeeded = $true
    try {
        # Only start Docker database if not skipping (e.g., on Windows CI where Docker isn't available)
        if ($env:ORCHESTRATE_SKIP_DB -ne "1") {
            Invoke-Step -Name 'db_up' -IdleTimeout '0' -HardTimeout '300' -Command @('docker','compose','up','-d','db')
        }
        Wait-ForDb
        $endpoint = Get-DbEndpoint
        Wait-ForTcp -TargetHost $endpoint.Host -TargetPort $endpoint.Port -TimeoutSeconds 30

        $pythonExe = Resolve-Python
        Invoke-Step -Name 'alembic' -HardTimeout '180' -Command @($pythonExe,'-m','alembic','-c','alembic.ini','upgrade','head')

        $envSnapshot = Save-Env -Keys @('LESSONS_ENABLED','TTS_ENABLED','ALLOW_DEV_CORS','SERVE_FLUTTER_WEB','LOG_LEVEL')
        try {
            $env:LESSONS_ENABLED = '1'
            $env:TTS_ENABLED = '1'
            $env:ALLOW_DEV_CORS = '1'
            if ($flutter) {
                $env:SERVE_FLUTTER_WEB = '1'
            } else {
                Remove-Item Env:SERVE_FLUTTER_WEB -ErrorAction SilentlyContinue
            }
            if ($logLevel) {
                $env:LOG_LEVEL = $logLevel.ToUpperInvariant()
            } else {
                Remove-Item Env:LOG_LEVEL -ErrorAction SilentlyContinue
            }
            Invoke-Step -Name 'uvicorn_start' -HardTimeout '180' -Command @('pwsh','-NoLogo','-File',$serveScript,'start','--host',$bindHost,'--port',$port,'--log-level',$logLevel)
        } finally {
            Restore-Env -Snapshot $envSnapshot
        }

        if (-not (Test-Path $pidPath)) { throw 'uvicorn pid file missing' }
        if (-not (Test-Path $portPath)) { throw 'uvicorn port file missing' }
        $serverPid = (Get-Content $pidPath | Select-Object -First 1).Trim()
        $portValue = (Get-Content $portPath | Select-Object -First 1).Trim()
        if (-not $serverPid) { throw 'uvicorn pid file empty' }
        if (-not $portValue) { throw 'uvicorn port file empty' }
        $logFile = Get-ChildItem -Path $artifactDir -Filter 'uvicorn_*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $logFilePath = if ($logFile) { $logFile.FullName } else { $null }

        $healthUrl = "http://${bindHost}:${portValue}/health"
        try {
            $response = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri $healthUrl
            if ($response.StatusCode -ne 200) {
                Write-Warning "[orchestrate] health probe returned status $($response.StatusCode)"
            }
        } catch {
            Write-Warning "[orchestrate] health probe failed at ${healthUrl}: $($_.Exception.Message)"
        }

        Write-State -BindHost $bindHost -Port $portValue -ProcessId $serverPid -LogFile $logFilePath
        Write-Output "[orchestrate] state written to $statePath"
        Write-Output "::READY::${bindHost}:${portValue}"

        $cleanupNeeded = $false
    } finally {
        if ($cleanupNeeded) {
            try { & $serveScript stop *> $null } catch { }
            try { docker compose down -v *> $null } catch { }
        }
        Pop-Location
    }
}

function Invoke-Smoke {
    Require-State
    $baseUrl = Resolve-BaseUrl
    Write-Output "[orchestrate] running API contract smokes against $baseUrl"
    Push-Location -LiteralPath $root
    $stateSnapshot = Save-Env -Keys @('ORCHESTRATOR_STATE_PATH')
    try {
        $env:ORCHESTRATOR_STATE_PATH = $statePath
        Invoke-Step -Name 'flutter_analyze' -Command @('pwsh','-NoLogo','-File',(Join-Path $root 'scripts/dev/analyze_flutter.ps1'))
        $apiSnapshot = Save-Env -Keys @('API_BASE_URL')
        try {
            $env:API_BASE_URL = $baseUrl
            Invoke-Step -Name 'contracts_pytest' -Command @('pytest','-q','backend/app/tests/test_contracts.py')
        } finally {
            Restore-Env -Snapshot $apiSnapshot
        }
    } finally {
        Restore-Env -Snapshot $stateSnapshot
        Pop-Location
    }
}

function Invoke-E2EWeb {
    param([string[]]$Args)

    Require-State
    $requireFlutter = $false
    $index = 0
    while ($index -lt $Args.Count) {
        switch ($Args[$index]) {
            '--require-flutter' {
                $requireFlutter = $true
                $index += 1
            }
            '--help' {
                Write-Output 'Usage: orchestrate.ps1 e2e-web [--require-flutter]'
                return
            }
            '-h' {
                Write-Output 'Usage: orchestrate.ps1 e2e-web [--require-flutter]'
                return
            }
            default {
                throw "unknown option for e2e-web: $($Args[$index])"
            }
        }
    }

    if ($requireFlutter -and -not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "[orchestrate] Flutter SDK is required for e2e-web; install Flutter or rerun without --require-flutter."
    }

    $baseUrl = Resolve-BaseUrl
    Write-Output "[orchestrate] running Flutter web E2E against $baseUrl"
    Push-Location -LiteralPath $root
    $apiSnapshot = Save-Env -Keys @('API_BASE_URL')
    try {
        $env:API_BASE_URL = $baseUrl
        Invoke-Step -Name 'e2e_web' -HardTimeout '900' -Command @('pwsh','-NoLogo','-File',(Join-Path $root 'scripts/dev/test_web_smoke.ps1'),'-BaseUrl',$baseUrl)
    } finally {
        Restore-Env -Snapshot $apiSnapshot
        Pop-Location
    }
}

function Invoke-Down {
    param([string[]]$Args)
    $keepDb = $false
    $index = 0
    while ($index -lt $Args.Count) {
        switch ($Args[$index]) {
            '--keep-db' {
                $keepDb = $true
                $index += 1
            }
            '--help' {
                Write-Output "Usage: orchestrate.ps1 down [--keep-db]"
                return
            }
            '-h' {
                Write-Output "Usage: orchestrate.ps1 down [--keep-db]"
                return
            }
            default {
                throw "unknown option for down: $($Args[$index])"
            }
        }
    }
    Push-Location -LiteralPath $root
    try {
        & $serveScript stop *> $null
        if ($keepDb) {
            docker compose down *> $null
        } else {
            docker compose down -v *> $null
        }
        Remove-Item $statePath -ErrorAction SilentlyContinue
        Write-Output "[orchestrate] teardown complete"
    } finally {
        Pop-Location
    }
}

function Invoke-Status {
    Push-Location -LiteralPath $root
    try {
        if (Test-Path $statePath) {
            Write-Output "[orchestrate] state:"
            Get-Content $statePath
        } else {
            Write-Output "[orchestrate] state file missing"
        }
        & $serveScript status
    } finally {
        Pop-Location
    }
}

function Invoke-Logs {
    Push-Location -LiteralPath $root
    try {
        & $serveScript logs
    } finally {
        Pop-Location
    }
}

switch ($Command) {
    'up' { Invoke-Up -Args $Arguments }
    'smoke' { Invoke-Smoke }
    'e2e-web' { Invoke-E2EWeb -Args $Arguments }
    'down' { Invoke-Down -Args $Arguments }
    'status' { Invoke-Status }
    'logs' { Invoke-Logs }
}
