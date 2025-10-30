$langs = @('got', 'gez', 'sog', 'uga', 'xto', 'txb', 'otk', 'ett', 'gmq-pro', 'non-rune', 'peo', 'elx', 'myn', 'phn', 'obm', 'xpu')
$passed = 0
$failed = 0
$failedLangs = @()

Write-Host "Retesting 16 rate-limited languages..." -ForegroundColor Cyan
Write-Host ""

foreach ($lang in $langs) {
    Write-Host "Testing $lang... " -NoNewline

    $body = @{
        language = $lang
        profile = "beginner"
        provider = "echo"
    } | ConvertTo-Json

    try {
        $resp = Invoke-RestMethod -Uri "http://localhost:8000/lesson/generate" -Method Post -ContentType "application/json" -Body $body -ErrorAction Stop

        if ($resp.tasks -and $resp.tasks.Count -gt 0) {
            Write-Host "PASS" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "FAIL (no tasks)" -ForegroundColor Red
            $failed++
            $failedLangs += $lang
        }

        Start-Sleep -Milliseconds 500
    } catch {
        Write-Host "FAIL ($($_.Exception.Message))" -ForegroundColor Red
        $failed++
        $failedLangs += $lang
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed languages:" -ForegroundColor Red
    $failedLangs | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
