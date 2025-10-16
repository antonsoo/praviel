# Script to copy Noto fonts to assets/fonts directory
# Usage: .\copy_fonts.ps1 -SourcePath "C:\path\to\downloaded\fonts"

param(
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "$env:USERPROFILE\Downloads"
)

$targetDir = ".\assets\fonts"
$fontsNeeded = @(
    "NotoSerifGreek-Regular.ttf",
    "NotoSansDevanagari-Regular.ttf",
    "NotoSansBrahmi-Regular.ttf",
    "NotoSansHebrew-Regular.ttf",
    "NotoSansGlagolitic-Regular.ttf",
    "NotoSansCuneiform-Regular.ttf",
    "NotoSansOldPersian-Regular.ttf",
    "NotoSansAvestan-Regular.ttf",
    "NotoSansImperialAramaic-Regular.ttf",
    "NotoSansPhoenician-Regular.ttf",
    "NotoSansEgyptianHieroglyphs-Regular.ttf",
    "NotoSansRunic-Regular.ttf"
)

Write-Host "Searching for Noto fonts in: $SourcePath" -ForegroundColor Cyan
Write-Host ""

$copiedCount = 0
$missingFonts = @()

foreach ($font in $fontsNeeded) {
    Write-Host "Looking for $font..." -NoNewline

    $found = Get-ChildItem -Path $SourcePath -Filter $font -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($found) {
        Copy-Item -Path $found.FullName -Destination $targetDir -Force
        Write-Host " ✓ Copied" -ForegroundColor Green
        $copiedCount++
    } else {
        Write-Host " ✗ Not found" -ForegroundColor Yellow
        $missingFonts += $font
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Copied: $copiedCount / $($fontsNeeded.Count)" -ForegroundColor Green

if ($missingFonts.Count -gt 0) {
    Write-Host "  Missing:" -ForegroundColor Yellow
    foreach ($font in $missingFonts) {
        Write-Host "    - $font" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "To download missing fonts:" -ForegroundColor Cyan
    Write-Host "  1. Visit https://fonts.google.com/noto" -ForegroundColor White
    Write-Host "  2. Search for each font name" -ForegroundColor White
    Write-Host "  3. Download and extract to $SourcePath" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "All fonts ready! Run 'flutter pub get' to register them." -ForegroundColor Green
}
