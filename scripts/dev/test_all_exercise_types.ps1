#!/usr/bin/env pwsh
# Test all 18 exercise types to ensure they generate correctly

$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $root

# Import Python resolver
. (Join-Path $root 'scripts\common\python_resolver.ps1')

function Get-PythonCommand {
  $pythonPath = Get-ProjectPythonCommand
  return [pscustomobject]@{ Exe = $pythonPath; Args = @() }
}

$python = Get-PythonCommand
$pythonExe = $python.Exe
$pythonArgs = $python.Args

# Set environment variables
$env:PYTHONPATH = Join-Path $root 'backend'
$env:LESSONS_ENABLED = '1'
$env:ALLOW_DEV_CORS = '1'

# All 18 exercise types
$exerciseTypes = @(
    "alphabet", "match", "cloze", "translate", "grammar", "listening",
    "speaking", "wordbank", "truefalse", "multiplechoice", "dialogue",
    "conjugation", "declension", "synonym", "contextmatch", "reorder",
    "dictation", "etymology"
)

# Languages to test
$languages = @("grc", "lat", "hbo", "san")

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing All 18 Exercise Types" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Start services
Write-Host "[test] Starting Postgres..." -ForegroundColor Yellow
docker compose up -d db | Out-Host

Write-Host "[test] Running migrations..." -ForegroundColor Yellow
$alembicArgs = $pythonArgs + @('-m', 'alembic', '-c', (Join-Path $root 'alembic.ini'), 'upgrade', 'head')
& $pythonExe $alembicArgs | Out-Host

# Start uvicorn manually (avoiding serve_uvicorn.ps1 due to PowerShell version compatibility)
Write-Host "[test] Starting uvicorn..." -ForegroundColor Yellow

# Find free port
$port = 8001
$listener = $null
try {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
    $listener.Start()
    $port = $listener.Server.LocalEndPoint.Port
    $listener.Stop()
} catch {
    $port = 8001
} finally {
    if ($listener) { $listener.Stop() }
}

# Start uvicorn in background
$uvicornArgs = $pythonArgs + @('-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', $port.ToString(), '--log-level', 'error')
$uvicornProcess = Start-Process -FilePath $pythonExe -ArgumentList $uvicornArgs -NoNewWindow -PassThru -RedirectStandardOutput (Join-Path $root 'artifacts/uvicorn.out') -RedirectStandardError (Join-Path $root 'artifacts/uvicorn.err')

Write-Host "[test] Uvicorn started on port $port (PID: $($uvicornProcess.Id))" -ForegroundColor Green
Start-Sleep -Seconds 3  # Wait for startup

$baseUrl = "http://127.0.0.1:$port/lesson/generate"
$successCount = 0
$failCount = 0
$results = @()

try {
    # Test each exercise type with each language
    foreach ($lang in $languages) {
        Write-Host "`n--- Testing language: $lang ---" -ForegroundColor Magenta

        foreach ($type in $exerciseTypes) {
            $testName = "$lang - $type"

            # Create payload for this exercise type
            $payload = @{
                language = $lang
                profile = "beginner"
                sources = @("daily")
                exercise_types = @($type)
                k_canon = 0
                include_audio = $false
                provider = "echo"
                task_count = 3
            } | ConvertTo-Json -Compress

            try {
                Write-Host "  Testing $testName... " -NoNewline

                $response = Invoke-RestMethod -Method Post -Uri $baseUrl -Body $payload -ContentType 'application/json' -TimeoutSec 10

                # Validate response has tasks
                if ($response.tasks -and $response.tasks.Count -gt 0) {
                    # Check all tasks are of the correct type
                    $allCorrectType = $true
                    foreach ($task in $response.tasks) {
                        if ($task.type -ne $type) {
                            $allCorrectType = $false
                            break
                        }
                    }

                    if ($allCorrectType) {
                        Write-Host "PASS" -ForegroundColor Green
                        $successCount++
                        $results += [PSCustomObject]@{
                            Language = $lang
                            Type = $type
                            Status = "PASS"
                            TaskCount = $response.tasks.Count
                        }
                    } else {
                        Write-Host "FAIL (wrong type returned)" -ForegroundColor Red
                        $failCount++
                        $results += [PSCustomObject]@{
                            Language = $lang
                            Type = $type
                            Status = "FAIL"
                            Error = "Wrong task type returned"
                        }
                    }
                } else {
                    Write-Host "FAIL (no tasks)" -ForegroundColor Red
                    $failCount++
                    $results += [PSCustomObject]@{
                        Language = $lang
                        Type = $type
                        Status = "FAIL"
                        Error = "No tasks in response"
                    }
                }
            } catch {
                Write-Host "FAIL ($($_.Exception.Message))" -ForegroundColor Red
                $failCount++
                $results += [PSCustomObject]@{
                    Language = $lang
                    Type = $type
                    Status = "FAIL"
                    Error = $_.Exception.Message
                }
            }

            Start-Sleep -Milliseconds 100
        }
    }

    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total Tests: $($successCount + $failCount)" -ForegroundColor White
    Write-Host "Passed: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })

    # Show failures if any
    if ($failCount -gt 0) {
        Write-Host "`nFailures:" -ForegroundColor Red
        $results | Where-Object { $_.Status -eq "FAIL" } | Format-Table -AutoSize
    }

    # Show success rate
    $successRate = [math]::Round(($successCount / ($successCount + $failCount)) * 100, 1)
    Write-Host "`nSuccess Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } else { "Yellow" })

} finally {
    # Cleanup
    Write-Host "`n[test] Stopping uvicorn..." -ForegroundColor Yellow
    if ($uvicornProcess -and !$uvicornProcess.HasExited) {
        Stop-Process -Id $uvicornProcess.Id -Force
        Write-Host "[test] Uvicorn stopped" -ForegroundColor Green
    }
}

exit $(if ($failCount -eq 0) { 0 } else { 1 })
