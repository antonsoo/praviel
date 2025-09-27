#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
$project = Join-Path $root 'client/flutter_reader'
$artifacts = Join-Path $root 'artifacts'
$outPath = Join-Path $artifacts 'dart_analyze.json'

if (-not (Test-Path $artifacts)) {
    New-Item -ItemType Directory -Path $artifacts | Out-Null
}

$dartCmd = Get-Command dart -ErrorAction SilentlyContinue
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue

if ($dartCmd) {
    $pubExe = $dartCmd.Source
    $pubArgs = @('--disable-analytics', 'pub', 'get')
} elseif ($flutterCmd) {
    $pubExe = $flutterCmd.Source
    $pubArgs = @('pub', 'get')
} else {
    throw "[analyze] Neither 'dart' nor 'flutter' is available on PATH. Install Flutter SDK."
}

Push-Location $project
try {
    Write-Host "[analyze] Running $pubExe $($pubArgs -join ' ')"
    & $pubExe @pubArgs
    if ($LASTEXITCODE -ne 0) {
        throw "[analyze] pub get failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

$dartCmd = Get-Command dart -ErrorAction SilentlyContinue
if (-not $dartCmd) {
    throw "[analyze] Dart SDK is unavailable; install Flutter (which bundles dart)."
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $dartCmd.Source
$psi.ArgumentList.Add('analyze')
$psi.ArgumentList.Add('--format=json')
$psi.WorkingDirectory = $project
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false

$process = [System.Diagnostics.Process]::Start($psi)
$stdout = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
$process.WaitForExit()

Set-Content -Path $outPath -Value $stdout -Encoding utf8

if (-not $stdout) {
    throw "[analyze] Analyzer produced no output."
}

try {
    $json = $stdout | ConvertFrom-Json
} catch {
    throw "[analyze] Failed to parse analyzer output: $($_.Exception.Message)"
}

$errors = @()
if ($json -and $json.diagnostics) {
    $errors = @($json.diagnostics | Where-Object { $_.severity -eq 'error' })
}

if ($errors.Count -gt 0) {
    throw "[analyze] Analyzer reported $($errors.Count) error(s). See $outPath."
}

if ($process.ExitCode -ne 0) {
    if ($stderr) {
        Write-Error $stderr
    }
    throw "[analyze] dart analyze exited with $($process.ExitCode)."
}

Write-Host "[analyze] Report saved to $outPath"
