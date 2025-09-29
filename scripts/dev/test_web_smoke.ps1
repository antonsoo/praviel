[CmdletBinding()]
param(
    [string]$BaseUrl,
    [string]$Report
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
$artifactDir = Join-Path $root 'artifacts'
$reportPath = if ($Report) { $Report } else { Join-Path $artifactDir 'e2e_web_report.json' }
$logPath = Join-Path $artifactDir 'e2e_web_console.log'
if (-not $BaseUrl) {
    if ($env:API_BASE_URL) {
        $BaseUrl = $env:API_BASE_URL
    } else {
        $BaseUrl = 'http://127.0.0.1:8000'
    }
}

New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
Remove-Item $reportPath, $logPath -ErrorAction SilentlyContinue
New-Item -ItemType File -Path $logPath -Force | Out-Null

$shouldRun = $true
$result = 'success'
$platform = 'chrome'
$testStatus = 0
$reasons = [System.Collections.Generic.List[string]]::new()


function Test-PortOpen {
    param([int]$Port = 4444)
    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $task = $client.ConnectAsync('127.0.0.1', $Port)
        if ($task.Wait(500)) {
            return $client.Connected
        }
        return $false
    } catch {
        return $false
    } finally {
        if ($client) { $client.Dispose() }
    }
}

function Add-Reason {
    param([string]$Reason)
    if ([string]::IsNullOrWhiteSpace($Reason)) { return }
    $reasons.Add($Reason)
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    '[web-test] Flutter SDK is required for the smoke test.' | Tee-Object -FilePath $logPath -Append | Out-Null
    $result = 'skipped'
    $platform = 'unavailable'
    Add-Reason 'flutter_missing'
    $shouldRun = $false
}

if ($shouldRun) {
    $chromedriverProcess = $null
    $driverCandidates = @()
    if ($env:CHROMEDRIVER) { $driverCandidates += $env:CHROMEDRIVER }
    $driverCandidates += @(Join-Path $root 'tools/chromedriver/chromedriver-win64/chromedriver.exe')
    $driverCandidates += @(Join-Path $root 'tools/chromedriver-win64/chromedriver-win64/chromedriver.exe')
    $driverCandidates += @(Join-Path $root 'tools/chromedriver-win64/chromedriver.exe')
    $driverCandidates += @(Join-Path $root 'tools/chromedriver/chromedriver')
    $driverPath = $driverCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if (-not $driverPath) {
        $command = Get-Command chromedriver -ErrorAction SilentlyContinue
        if ($command) {
            $driverPath = $command.Source
        }
    }
    if ($driverPath -and -not (Test-PortOpen -Port 4444)) {
        try {
            $chromedriverProcess = Start-Process -FilePath $driverPath -ArgumentList '--port=9515','--allowed-origins=*' -WindowStyle Hidden -PassThru -ErrorAction Stop
            Start-Sleep -Seconds 2
        } catch {
            Add-Reason('chromedriver_launch_failed')
        }
    }
    try {
        $devicesJson = flutter devices --machine
        if ([string]::IsNullOrWhiteSpace($devicesJson)) {
            $platform = 'web-server'
            Add-Reason 'devices_query_empty'
        } else {
            try {
                $devices = $devicesJson | ConvertFrom-Json -ErrorAction Stop
                if (-not ($devices | Where-Object { $_.id -eq 'chrome' })) {
                    $platform = 'web-server'
                    Add-Reason 'chrome_missing'
                }
            } catch {
                $platform = 'web-server'
                Add-Reason 'devices_parse_failed'
            }
        }
    } catch {
        $platform = 'web-server'
        Add-Reason 'devices_query_failed'
    }
}

if (-not $shouldRun) {
    '[web-test] Skipping flutter drive execution due to missing prerequisites.' | Tee-Object -FilePath $logPath -Append | Out-Null
    $testStatus = 0
} else {
    Push-Location -LiteralPath (Join-Path $root 'client/flutter_reader')
    $priorApi = $env:API_BASE_URL
    try {
        $env:API_BASE_URL = $BaseUrl
        $arguments = @(
            'drive',
            '-d','web-server',
            '--browser-name', $platform,
            '--driver','integration_test/driver.dart',
            '--target','integration_test/lesson_flow_smoke_test.dart',
            '--driver-port','9515',
            '--dart-define=INTEGRATION_TEST=true'
        )
        & flutter @arguments 2>&1 | Tee-Object -FilePath $logPath -Append
        $testStatus = $LASTEXITCODE
    } finally {
        if ($null -ne $priorApi) {
            $env:API_BASE_URL = $priorApi
        } else {
            Remove-Item Env:API_BASE_URL -ErrorAction SilentlyContinue
        }
        Pop-Location
    }
    if ($chromedriverProcess) {
        try { Stop-Process -Id $chromedriverProcess.Id -Force -ErrorAction SilentlyContinue } catch { }
        $chromedriverProcess = $null
    }
    if ($testStatus -ne 0) {
        $result = 'failure'
        Add-Reason 'test_failed'
    }
}

$summary = $null
if (Test-Path $logPath) {
    try {
        $content = Get-Content $logPath -Raw -ErrorAction Stop
        if ($content) {
            foreach ($line in $content -split "`n") {
                $trim = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($trim)) { continue }
                if ($trim.StartsWith('{"result"')) {
                    try {
                        $summary = $trim | ConvertFrom-Json -ErrorAction Stop
                    } catch {
                    }
                }
            }
        }
    } catch {
    }
}

$logResolved = if (Test-Path $logPath) { (Resolve-Path $logPath).Path } else { $logPath }
$payload = [ordered]@{
    timestamp = (Get-Date -AsUTC).ToString('o')
    result     = $result
    platform   = $platform
    base_url   = $BaseUrl
    log_path   = $logResolved
}
if ($reasons.Count -gt 0) {
    $payload.reasons = $reasons
}
if ($summary) {
    $payload.summary = $summary
    if ($summary.result) {
        $payload.result = [string]$summary.result
    }
    if ($summary.failureDetails) {
        $payload.failures = $summary.failureDetails
    }
}

$payload | ConvertTo-Json -Depth 6 | Set-Content -Path $reportPath -Encoding UTF8

$finalResult = (Get-Content $reportPath -Raw | ConvertFrom-Json).result
if ($finalResult -ne 'success' -and $finalResult -ne 'skipped') {
    exit 1
}
