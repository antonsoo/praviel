# Tests each provider with real API key from environment variables
# Usage: $env:ANTHROPIC_API_KEY = "sk-..."; $env:OPENAI_API_KEY = "sk-..."; .\test_real_providers.ps1

param(
    [string]$BaseUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Continue"
$OutputDir = Join-Path $PWD "artifacts"
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "=== Testing BYOK Providers with Real Keys ===" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir"
Write-Host ""

# Test Anthropic
if ($env:ANTHROPIC_API_KEY) {
    Write-Host "🧪 Testing Anthropic (Claude Sonnet 4.5)..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/lesson/generate" -Method Post `
            -Headers @{
                "Authorization" = "Bearer $env:ANTHROPIC_API_KEY"
                "Content-Type" = "application/json"
            } `
            -Body (@{
                provider = "anthropic"
                model = "claude-sonnet-4-5"
                language = "grc"
                profile = "beginner"
                sources = @("daily")
                exercise_types = @("match", "translate")
                k_canon = 0
            } | ConvertTo-Json -Depth 10) `
            -ErrorAction Stop

        $response | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/lesson_anthropic.json" -Encoding utf8
        Write-Host "✅ Anthropic: SUCCESS" -ForegroundColor Green
        Write-Host "   Saved to: $OutputDir/lesson_anthropic.json"
    }
    catch {
        Write-Host "❌ Anthropic: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}
else {
    Write-Host "⏭️  Skipping Anthropic (ANTHROPIC_API_KEY not set)" -ForegroundColor Gray
    Write-Host ""
}

# Test OpenAI
if ($env:OPENAI_API_KEY) {
    Write-Host "🧪 Testing OpenAI (GPT-5-mini)..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/lesson/generate" -Method Post `
            -Headers @{
                "Authorization" = "Bearer $env:OPENAI_API_KEY"
                "Content-Type" = "application/json"
            } `
            -Body (@{
                provider = "openai"
                model = "gpt-5-mini"
                language = "grc"
                profile = "beginner"
                sources = @("daily")
                exercise_types = @("match", "alphabet")
                k_canon = 0
            } | ConvertTo-Json -Depth 10) `
            -ErrorAction Stop

        $response | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/lesson_openai.json" -Encoding utf8
        Write-Host "✅ OpenAI: SUCCESS" -ForegroundColor Green
        Write-Host "   Saved to: $OutputDir/lesson_openai.json"
    }
    catch {
        Write-Host "❌ OpenAI: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}
else {
    Write-Host "⏭️  Skipping OpenAI (OPENAI_API_KEY not set)" -ForegroundColor Gray
    Write-Host ""
}

# Test Google
if ($env:GOOGLE_API_KEY) {
    Write-Host "🧪 Testing Google (Gemini 2.5 Flash)..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/lesson/generate" -Method Post `
            -Headers @{
                "Authorization" = "Bearer $env:GOOGLE_API_KEY"
                "Content-Type" = "application/json"
            } `
            -Body (@{
                provider = "google"
                model = "gemini-2.5-flash"
                language = "grc"
                profile = "beginner"
                sources = @("daily")
                exercise_types = @("match")
                k_canon = 0
            } | ConvertTo-Json -Depth 10) `
            -ErrorAction Stop

        $response | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/lesson_google.json" -Encoding utf8
        Write-Host "✅ Google: SUCCESS" -ForegroundColor Green
        Write-Host "   Saved to: $OutputDir/lesson_google.json"
    }
    catch {
        Write-Host "❌ Google: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}
else {
    Write-Host "⏭️  Skipping Google (GOOGLE_API_KEY not set)" -ForegroundColor Gray
    Write-Host ""
}

# Test Echo (no key needed)
Write-Host "🧪 Testing Echo (offline fallback)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/lesson/generate" -Method Post `
        -Headers @{
            "Content-Type" = "application/json"
        } `
        -Body (@{
            provider = "echo"
            language = "grc"
            profile = "beginner"
            sources = @("daily")
            exercise_types = @("match", "alphabet", "translate")
            k_canon = 0
        } | ConvertTo-Json -Depth 10) `
        -ErrorAction Stop

    $response | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/lesson_echo.json" -Encoding utf8
    Write-Host "✅ Echo: SUCCESS" -ForegroundColor Green
    Write-Host "   Saved to: $OutputDir/lesson_echo.json"
}
catch {
    Write-Host "❌ Echo: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Provider Testing Complete ===" -ForegroundColor Cyan
Write-Host "Review outputs in: $OutputDir"
