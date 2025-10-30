#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('start','stop','status','logs')]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName

# Import Python resolver for correct Python version detection
. (Join-Path $root 'scripts\common\python_resolver.ps1')
$artifactDir = Join-Path $root 'artifacts'
$pidPath = Join-Path $artifactDir 'uvicorn.pid'
$portPath = Join-Path $artifactDir 'uvicorn.port'
New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

function Show-Usage {
@"
Usage: serve_uvicorn.ps1 <start|stop|status|logs> [options]

Commands:
  start     Start uvicorn in the background
  stop      Stop the running uvicorn process
  status    Show process and /health status
  logs      Tail the latest uvicorn log file

Options for start:
  --port <port>     Bind to a specific port (default: auto)
  --host <host>     Bind to a specific host (default: 127.0.0.1)
  --no-reload       Disable uvicorn reload (default: reload enabled)
  --reload          Explicitly enable reload
  --flutter         Enable Flutter web static serving
  --log-level <lv>  Override uvicorn log level (default: info)
"@
}

function Set-AtomicFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $tmp = "$Path.tmp"
    [System.IO.File]::WriteAllText($tmp, "$Value`n", [System.Text.Encoding]::UTF8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Test-ProcessRunning {
    param([int]$ProcessId)
    if ($ProcessId -le 0) { return $false }
    try {
        $null = Get-Process -Id $ProcessId -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-FreePort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        return ($listener.LocalEndpoint).Port
    } finally {
        $listener.Stop()
    }
}

function Ensure-PythonPath {
    $backend = Join-Path $root 'backend'
    if ([string]::IsNullOrEmpty($env:PYTHONPATH)) {
        $env:PYTHONPATH = $backend
        return
    }
    if (-not $env:PYTHONPATH.Split([IO.Path]::PathSeparator) -contains $backend) {
        $env:PYTHONPATH = "$backend${[IO.Path]::PathSeparator}$($env:PYTHONPATH)"
    }
}

function Wait-ForHealth {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][int]$ProcessId
    )
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                return $true
            }
        } catch {
        }
        if (-not (Test-ProcessRunning -ProcessId $ProcessId)) {
            return $false
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Resolve-PythonCommand {
    # Use centralized Python resolver to ensure correct version (3.12.x)
    return Get-ProjectPythonCommand
}

function Invoke-Start {
    param([string[]]$StartArgs)

    $bindHost = '127.0.0.1'
    $port = $null
    $reload = $true
    $flutter = $false
    $logLevel = $null

    for ($i = 0; $i -lt $StartArgs.Count; ) {
        switch ($StartArgs[$i]) {
            '--port' {
                if ($i + 1 -ge $StartArgs.Count) { throw "--port requires a value" }
                $port = [int]$StartArgs[$i + 1]
                $i += 2
            }
            '--host' {
                if ($i + 1 -ge $StartArgs.Count) { throw "--host requires a value" }
                $bindHost = $StartArgs[$i + 1]
                $i += 2
            }
            '--no-reload' {
                $reload = $false
                $i += 1
            }
            '--reload' {
                $reload = $true
                $i += 1
            }
            '--flutter' {
                $flutter = $true
                $i += 1
            }
            '--log-level' {
                if ($i + 1 -ge $StartArgs.Count) { throw "--log-level requires a value" }
                $logLevel = $StartArgs[$i + 1]
                $i += 2
            }
            '--help' { Show-Usage; return }
            '-h' { Show-Usage; return }
            default { throw "Unknown option for start: $($StartArgs[$i])" }
        }
    }

    if (Test-Path $pidPath) {
        $existingRaw = (Get-Content $pidPath | Select-Object -First 1).Trim()
        $existingId = 0
        if ([int]::TryParse($existingRaw, [ref]$existingId) -and (Test-ProcessRunning -ProcessId $existingId)) {
            Write-Output "uvicorn already running (pid=$existingId)"
            return
        }
        Remove-Item $pidPath -ErrorAction SilentlyContinue
        Remove-Item $portPath -ErrorAction SilentlyContinue
    }

    if (-not $port) {
        $port = Get-FreePort
    }

    Ensure-PythonPath
    if (-not $env:ALLOW_DEV_CORS) { $env:ALLOW_DEV_CORS = '1' }
    if (-not $env:LESSONS_ENABLED) { $env:LESSONS_ENABLED = '1' }
    if (-not $env:TTS_ENABLED) { $env:TTS_ENABLED = '1' }
    if (-not $env:ECHO_FALLBACK_ENABLED) { $env:ECHO_FALLBACK_ENABLED = '1' }
    if ($flutter) {
        $env:SERVE_FLUTTER_WEB = '1'
    }
    if ($logLevel) {
        $env:LOG_LEVEL = $logLevel.ToUpperInvariant()
    }

    $logPath = Join-Path $artifactDir ("uvicorn_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

    $pythonCommand = Resolve-PythonCommand
    $arguments = @('-m','uvicorn','app.main:app','--app-dir', (Join-Path $root 'backend'),'--host',$bindHost,'--port',$port)
    if ($reload -and -not ($env:UVICORN_RELOAD -match '^(0|false|no)$')) {
        $arguments += '--reload'
    }
    $effectiveLogLevel = if ($logLevel) { $logLevel } elseif ($env:UVICORN_LOG_LEVEL) { $env:UVICORN_LOG_LEVEL } else { 'info' }
    $arguments += @('--log-level', $effectiveLogLevel)

    function Local:Format-CmdArgument {
        param([string]$Value)
        if ($null -eq $Value) { return '""' }
        if ($Value -eq '') { return '""' }
        if ($Value -match '[\s"\^]') {
            $escaped = $Value.Replace('"', '\"').Replace('^', '^^')
            return ('"' + $escaped + '"')
        }
        return $Value
    }

    $cmdComponents = @($pythonCommand) + $arguments
    $cmdLine = ($cmdComponents | ForEach-Object { Format-CmdArgument $_ }) -join ' '
    $cmdLine += ' >> ' + (Format-CmdArgument $logPath) + ' 2>&1'

    $process = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $cmdLine -WorkingDirectory $root -WindowStyle Hidden -PassThru
    if (-not $process) { throw 'Failed to launch uvicorn process.' }

    Set-AtomicFile -Path $pidPath -Value $process.Id
    Set-AtomicFile -Path $portPath -Value $port

    $healthUrl = "http://${bindHost}:${port}/health"
    if (-not (Wait-ForHealth -Url $healthUrl -ProcessId $process.Id)) {
        try { $process.Kill() } catch { }
        throw "Timed out waiting for $healthUrl"
    }

    Write-Output "uvicorn started pid=$($process.Id) host=$bindHost port=$port log=$logPath"
}

function Invoke-Stop {
    if (-not (Test-Path $pidPath)) {
        Write-Output 'uvicorn not running'
        return
    }
    $pidRaw = (Get-Content $pidPath | Select-Object -First 1).Trim()
    $pidValue = 0
    if (-not ([int]::TryParse($pidRaw, [ref]$pidValue) -and (Test-ProcessRunning -ProcessId $pidValue))) {
        Remove-Item $pidPath -ErrorAction SilentlyContinue
        Remove-Item $portPath -ErrorAction SilentlyContinue
        Write-Output 'uvicorn not running (stale pid removed)'
        return
    }
    Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (-not (Test-ProcessRunning -ProcessId $pidValue)) { break }
        Start-Sleep -Milliseconds 500
    }
    if (Test-ProcessRunning -ProcessId $pidValue) {
        Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $pidPath -ErrorAction SilentlyContinue
    Remove-Item $portPath -ErrorAction SilentlyContinue
    Write-Output "uvicorn stopped pid=$pidValue"
}

function Invoke-Status {
    if (-not (Test-Path $pidPath)) {
        Write-Output 'uvicorn not running'
        return
    }
    $pidRaw = (Get-Content $pidPath | Select-Object -First 1).Trim()
    $pidValue = 0
    if (-not ([int]::TryParse($pidRaw, [ref]$pidValue) -and (Test-ProcessRunning -ProcessId $pidValue))) {
        Remove-Item $pidPath -ErrorAction SilentlyContinue
        Remove-Item $portPath -ErrorAction SilentlyContinue
        Write-Output 'uvicorn not running (stale pid removed)'
        return
    }
    $portValue = if (Test-Path $portPath) { (Get-Content $portPath | Select-Object -First 1).Trim() } else { 'unknown' }
    $healthUrl = "http://127.0.0.1:${portValue}/health"
    $status = 'unreachable'
    try {
        $resp = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 5
        if ($resp.StatusCode -eq 200) { $status = 'ok' }
    } catch {
        $status = 'unreachable'
    }
    Write-Output "uvicorn running pid=$pidValue host=127.0.0.1 port=$portValue health=$status"
    if ($status -ne 'ok') { exit 2 }
}

function Invoke-Logs {
    $logs = Get-ChildItem -Path $artifactDir -Filter 'uvicorn_*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $logs) {
        throw "No uvicorn log files found in $artifactDir"
    }
    Get-Content -Path $logs[0].FullName -Tail 200 -Wait
}

switch ($Command) {
    'start' { Invoke-Start -StartArgs $Args }
    'stop' { Invoke-Stop }
    'status' { Invoke-Status }
    'logs' { Invoke-Logs }
}
