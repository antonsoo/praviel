Param(
  [int]$Port = 0,
  [switch]$FastMode
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $root

# Import Python resolver for correct Python version detection
. (Join-Path $root 'scripts\common\python_resolver.ps1')

function Get-PythonCommand {
  $pythonPath = Get-ProjectPythonCommand
  return [pscustomobject]@{ Exe = $pythonPath; Args = @() }
}

$python = Get-PythonCommand
$pythonExe = $python.Exe
$pythonArgs = $python.Args

$prevUvicornPython = $env:UVICORN_PYTHON
if ($pythonArgs.Count -gt 0) {
  $env:UVICORN_PYTHON = "$pythonExe " + ($pythonArgs -join ' ')
} else {
  $env:UVICORN_PYTHON = $pythonExe
}

try {
  $env:PYTHONPATH = Join-Path $root 'backend'
  $env:LESSONS_ENABLED = '1'
  $env:ALLOW_DEV_CORS = '1'

  Write-Host "[smoke-all-langs] Starting Postgres via docker compose"
  docker compose up -d db | Out-Host

  Write-Host "[smoke-all-langs] Applying migrations"
  $alembicArgs = $pythonArgs + @('-m', 'alembic', '-c', (Join-Path $root 'alembic.ini'), 'upgrade', 'head')
  & $pythonExe $alembicArgs

  $startArgs = @('--log-level','warning')
  if ($Port -gt 0) {
    $startArgs += @('--port', $Port)
  }

  & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') start @startArgs | Out-Host

  $portFile = Join-Path $root 'artifacts/uvicorn.port'
  if (Test-Path $portFile) {
    $portText = (Get-Content $portFile | Select-Object -First 1).Trim()
    if ([int]::TryParse($portText, [ref]$Port)) {
      # parsed port
    }
  } elseif ($Port -le 0) {
    $Port = 8000
  }

  Write-Host ""
  Write-Host "==========================================" -ForegroundColor Cyan
  Write-Host "Language Smoke Tests - All 46 Languages" -ForegroundColor Cyan
  Write-Host "==========================================" -ForegroundColor Cyan
  Write-Host ""

  # All 46 language codes from language_config.py (in display order)
  $allLanguages = @(
    "grc-cls",     # Classical Greek
    "lat",         # Classical Latin
    "egy-old",     # Old Egyptian
    "san-ved",     # Vedic Sanskrit
    "grc-koi",     # Koine Greek
    "sux",         # Sumerian
    "hbo-paleo",   # Paleo-Hebrew
    "ave",         # Avestan
    "pli",         # Pali
    "hbo",         # Biblical Hebrew
    "arc",         # Aramaic
    "san",         # Sanskrit
    "akk",         # Akkadian
    "non",         # Old Norse
    "egy",         # Egyptian
    "ang",         # Old English
    "lzh",         # Classical Chinese
    "cop",         # Coptic
    "hit",         # Hittite
    "nci",         # Classical Nahuatl
    "bod",         # Tibetan
    "ojp",         # Old Japanese
    "qwh",         # Quechua
    "ara",         # Arabic
    "syc",         # Syriac
    "pal",         # Pahlavi
    "sga",         # Old Irish
    "got",         # Gothic
    "gez",         # Ge'ez
    "tam-old",     # Old Tamil
    "xcl",         # Classical Armenian
    "sog",         # Sogdian
    "uga",         # Ugaritic
    "xto",         # Tocharian A
    "txb",         # Tocharian B
    "ett",         # Etruscan
    "gmq-pro",     # Proto-Norse
    "elx",         # Elamite
    "non-rune",    # Runic Norse
    "peo",         # Old Persian
    "myn",         # Mayan
    "otk",         # Old Turkic
    "phn",         # Phoenician
    "obm",         # Old Burmese
    "xpu"          # Punic
  )

  if ($FastMode) {
    Write-Host "FAST MODE: Testing only 5 representative languages" -ForegroundColor Yellow
    $allLanguages = @("grc-cls", "lat", "hbo", "san", "ara")
  }

  $baseUri = "http://127.0.0.1:$Port"
  $passed = 0
  $failed = 0
  $failedLanguages = @()

  foreach ($lang in $allLanguages) {
    Write-Host "[$lang] Testing lesson generation..." -ForegroundColor Gray

    $payload = @{
      language = $lang
      profile = "beginner"
      sources = @("daily", "canon")
      exercise_types = @("match", "cloze")
      k_canon = 2
      include_audio = $false
      provider = "echo"
    } | ConvertTo-Json -Depth 5

    try {
      $response = Invoke-RestMethod -Method Post -Uri "$baseUri/lesson/generate" -Body $payload -ContentType 'application/json' -TimeoutSec 30

      # Validate response structure
      if ($response.vocabulary -and $response.exercises) {
        Write-Host "   Lesson generated successfully" -ForegroundColor Green
        Write-Host "    - Vocabulary count: $($response.vocabulary.Count)" -ForegroundColor Gray
        Write-Host "    - Exercise count: $($response.exercises.Count)" -ForegroundColor Gray
        $passed++
      } else {
        Write-Host "   Invalid response structure" -ForegroundColor Red
        $failed++
        $failedLanguages += $lang
      }
    } catch {
      Write-Host "   FAILED: $($_.Exception.Message)" -ForegroundColor Red
      $failed++
      $failedLanguages += $lang
    }
  }

  Write-Host ""
  Write-Host "==========================================" -ForegroundColor Cyan
  Write-Host "Test Results Summary" -ForegroundColor Cyan
  Write-Host "==========================================" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Total languages tested: $($allLanguages.Count)" -ForegroundColor White
  Write-Host "Passed: $passed" -ForegroundColor Green
  Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

  if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed languages:" -ForegroundColor Red
    foreach ($lang in $failedLanguages) {
      Write-Host "  - $lang" -ForegroundColor Red
    }
    Write-Host ""
    throw "Some languages failed smoke tests"
  } else {
    Write-Host ""
    Write-Host " All languages passed!" -ForegroundColor Green
  }

  Write-Host ""
}
finally {
  & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') stop | Out-Host
  $env:UVICORN_PYTHON = $prevUvicornPython
}
