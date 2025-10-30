# Test all 46 languages for lesson generation
$languages = @("lat", "grc-koi", "grc", "hbo", "san", "lzh", "pli", "cu", "arc", "ara", "non", "egy", "ang", "hbo-paleo", "cop", "sux", "tam-old", "syc", "akk", "san-ved", "xcl", "hit", "egy-old", "ave", "nci", "bod", "ojp", "qwh", "pal", "sga", "got", "gez", "sog", "uga", "xto", "txb", "otk", "ett", "gmq-pro", "non-rune", "peo", "elx", "myn", "phn", "obm", "xpu")

$passed = 0
$failed = 0
$failedLangs = @()

Write-Host "Testing lesson generation for all 46 languages..." -ForegroundColor Cyan
Write-Host ""

foreach ($lang in $languages) {
    Write-Host "Testing $lang... " -NoNewline

    $body = @{
        language = $lang
        profile = "beginner"
        provider = "echo"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/lesson/generate" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -ErrorAction Stop

        if ($response.tasks -and $response.tasks.Count -gt 0) {
            Write-Host "PASS" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "FAIL (no tasks)" -ForegroundColor Red
            $failed++
            $failedLangs += $lang
        }
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
