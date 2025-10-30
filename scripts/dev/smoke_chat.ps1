Param(
  [int]$Port = 0
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

  Write-Host "[chat] Starting Postgres via docker compose"
  docker compose up -d db | Out-Host

  Write-Host "[chat] Applying migrations"
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
  Write-Host "================================" -ForegroundColor Cyan
  Write-Host "Chat Provider Smoke Tests" -ForegroundColor Cyan
  Write-Host "================================" -ForegroundColor Cyan
  Write-Host ""

  $baseUri = "http://127.0.0.1:$Port"

  # Test personas to verify
  $testPersonas = @("athenian_merchant", "spartan_warrior", "athenian_philosopher")

  # Test 1: Echo Provider (should always work, no API key needed)
  Write-Host "[TEST 1] Echo Provider (offline, no API key)" -ForegroundColor Yellow
  foreach ($persona in $testPersonas) {
    Write-Host "  Testing persona: $persona" -ForegroundColor Gray
    $payload = @{
      provider = "echo"
      persona = $persona
      message = "χαῖρε"
      context = @()
    } | ConvertTo-Json -Depth 5

    try {
      $response = Invoke-RestMethod -Method Post -Uri "$baseUri/chat/converse" -Body $payload -ContentType 'application/json'
      Write-Host "  ✓ Reply: $($response.reply)" -ForegroundColor Green
      Write-Host "  ✓ Translation: $($response.translation_help)" -ForegroundColor Green
    } catch {
      Write-Host "  ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
      throw
    }
  }
  Write-Host ""

  # Test 2: OpenAI Provider (requires API key)
  Write-Host "[TEST 2] OpenAI Chat Provider (requires OPENAI_API_KEY)" -ForegroundColor Yellow
  if ($env:OPENAI_API_KEY) {
    Write-Host "  API key found, testing..." -ForegroundColor Gray
    $payload = @{
      provider = "openai"
      persona = "athenian_merchant"
      message = "χαῖρε, πῶς ἔχεις;"
      context = @()
      model = "gpt-5-nano-2025-08-07"
    } | ConvertTo-Json -Depth 5

    try {
      $response = Invoke-RestMethod -Method Post -Uri "$baseUri/chat/converse" -Body $payload -ContentType 'application/json'
      Write-Host "  ✓ Reply: $($response.reply)" -ForegroundColor Green
      Write-Host "  ✓ Translation: $($response.translation_help)" -ForegroundColor Green
      Write-Host "  ✓ Model: $($response.meta.model)" -ForegroundColor Green
    } catch {
      Write-Host "  ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "  Note: Check API key validity and quota" -ForegroundColor Yellow
    }
  } else {
    Write-Host "  ⊘ SKIPPED: OPENAI_API_KEY not set" -ForegroundColor Yellow
  }
  Write-Host ""

  # Test 3: Anthropic Provider (requires API key)
  Write-Host "[TEST 3] Anthropic Chat Provider (requires ANTHROPIC_API_KEY)" -ForegroundColor Yellow
  if ($env:ANTHROPIC_API_KEY) {
    Write-Host "  API key found, testing..." -ForegroundColor Gray
    $payload = @{
      provider = "anthropic"
      persona = "spartan_warrior"
      message = "πῶς ἔχεις;"
      context = @()
      model = "claude-4-5-sonnet-20250514"
    } | ConvertTo-Json -Depth 5

    try {
      $response = Invoke-RestMethod -Method Post -Uri "$baseUri/chat/converse" -Body $payload -ContentType 'application/json'
      Write-Host "  ✓ Reply: $($response.reply)" -ForegroundColor Green
      Write-Host "  ✓ Translation: $($response.translation_help)" -ForegroundColor Green
      Write-Host "  ✓ Model: $($response.meta.model)" -ForegroundColor Green
    } catch {
      Write-Host "  ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "  Note: Check API key validity and quota" -ForegroundColor Yellow
    }
  } else {
    Write-Host "  ⊘ SKIPPED: ANTHROPIC_API_KEY not set" -ForegroundColor Yellow
  }
  Write-Host ""

  # Test 4: Google Provider (requires API key)
  Write-Host "[TEST 4] Google Chat Provider (requires GOOGLE_API_KEY)" -ForegroundColor Yellow
  if ($env:GOOGLE_API_KEY) {
    Write-Host "  API key found, testing..." -ForegroundColor Gray
    $payload = @{
      provider = "google"
      persona = "athenian_philosopher"
      message = "τί ἐστιν ἀρετή;"
      context = @()
      model = "gemini-2.5-flash"
    } | ConvertTo-Json -Depth 5

    try {
      $response = Invoke-RestMethod -Method Post -Uri "$baseUri/chat/converse" -Body $payload -ContentType 'application/json'
      Write-Host "  ✓ Reply: $($response.reply)" -ForegroundColor Green
      Write-Host "  ✓ Translation: $($response.translation_help)" -ForegroundColor Green
      Write-Host "  ✓ Model: $($response.meta.model)" -ForegroundColor Green
    } catch {
      Write-Host "  ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "  Note: Check API key validity and quota" -ForegroundColor Yellow
    }
  } else {
    Write-Host "  ⊘ SKIPPED: GOOGLE_API_KEY not set" -ForegroundColor Yellow
  }
  Write-Host ""

  # Test 5: Context management (conversation history)
  Write-Host "[TEST 5] Context Management (conversation history)" -ForegroundColor Yellow
  Write-Host "  Testing multi-turn conversation with echo provider..." -ForegroundColor Gray
  $payload = @{
    provider = "echo"
    persona = "athenian_merchant"
    message = "τί δέῃ;"
    context = @(
      @{ role = "user"; content = "χαῖρε" }
      @{ role = "assistant"; content = "χαῖρε, ὦ φίλε!" }
    )
  } | ConvertTo-Json -Depth 5

  try {
    $response = Invoke-RestMethod -Method Post -Uri "$baseUri/chat/converse" -Body $payload -ContentType 'application/json'
    Write-Host "  ✓ Context accepted (length: $($response.meta.context_length))" -ForegroundColor Green
    Write-Host "  ✓ Reply: $($response.reply)" -ForegroundColor Green
  } catch {
    Write-Host "  ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    throw
  }
  Write-Host ""

  Write-Host "================================" -ForegroundColor Cyan
  Write-Host "All Chat Tests Completed" -ForegroundColor Cyan
  Write-Host "================================" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Summary:" -ForegroundColor White
  Write-Host "  ✓ Echo provider working" -ForegroundColor Green
  if ($env:OPENAI_API_KEY) {
    Write-Host "  ✓ OpenAI provider tested" -ForegroundColor Green
  } else {
    Write-Host "  ⊘ OpenAI provider not tested (no API key)" -ForegroundColor Yellow
  }
  if ($env:ANTHROPIC_API_KEY) {
    Write-Host "  ✓ Anthropic provider tested" -ForegroundColor Green
  } else {
    Write-Host "  ⊘ Anthropic provider not tested (no API key)" -ForegroundColor Yellow
  }
  if ($env:GOOGLE_API_KEY) {
    Write-Host "  ✓ Google provider tested" -ForegroundColor Green
  } else {
    Write-Host "  ⊘ Google provider not tested (no API key)" -ForegroundColor Yellow
  }
  Write-Host ""
}
finally {
  & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') stop | Out-Host
  $env:UVICORN_PYTHON = $prevUvicornPython
}
