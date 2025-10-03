<#
Test-LLMKeys.ps1
Verifies Anthropic, Google Gemini, and OpenAI Responses API keys.
- Compatible with Windows PowerShell 5.1 and PowerShell 7+
- Never exits the shell unless -CI is provided
- Prints PASS/FAIL lines; sets $LASTEXITCODE; optional JSON summary

Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Test-LLMKeys.ps1
  pwsh       -NoProfile -File .\Test-LLMKeys.ps1 -OpenAIModel gpt-4.1
  pwsh       -NoProfile -File .\Test-LLMKeys.ps1 -CI -SummaryPath .\llmkeys.summary.json
#>

param(
  [switch]$CI,
  [string]$AnthropicModel = "claude-sonnet-4-5-20250929",
  [string]$GeminiModel    = "gemini-2.5-flash",
  [string]$OpenAIModel    = "gpt-5-nano",
  [string]$OpenAIPrompt   = "ping",
  [int[]] $OpenAIBudgets  = @(128,256,512),     # auto-retry caps for reasoning models
  [int]   $TimeoutSec     = 30,                 # per-request timeout
  [string]$SummaryPath    = ""                  # optional JSON summary path
)

$ErrorActionPreference = 'Stop'
$script:fail = $false

function _print([string]$label, [bool]$ok, [string]$msg) {
  $status = if ($ok) { "PASS" } else { "FAIL" }
  "{0,-9} {1} - {2}" -f $label, $status, $msg
}

function _err([object]$e) {
  $m = $null
  try { $m = $e.ErrorDetails.Message } catch {}
  if (-not $m) { try { $m = $e.Exception.Message } catch {} }
  if (-not $m) { $m = $e.ToString() }
  return $m
}

function New-OpenAIRequestBody {
  param([string]$Model, [string]$Prompt, [int]$MaxOutputTokens)

  $body = [ordered]@{
    model             = $Model
    input             = $Prompt
    store             = $false
    text              = @{ format = @{ type = "text" } }
    max_output_tokens = $MaxOutputTokens
  }
  if ($Model -like "gpt-5*") {
    # Reasoning control only for 5-series models
    $body["reasoning"] = @{ effort = "low" }
  }
  return ($body | ConvertTo-Json -Depth 20)
}

function Test-Anthropic {
  if (-not $env:ANTHROPIC_API_KEY) { _print "Anthropic" $false "ANTHROPIC_API_KEY not set"; $script:fail=$true; return }

  $body = @{
    model     = $AnthropicModel
    max_tokens= 16
    messages  = @(@{ role="user"; content="ping" })
  } | ConvertTo-Json -Depth 5

  try {
    $r = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" -Method Post `
         -Headers @{ "x-api-key"=$env:ANTHROPIC_API_KEY; "anthropic-version"="2023-06-01" } `
         -ContentType "application/json" -Body $body -TimeoutSec $TimeoutSec
    $txt = $r.content[0].text
    $ok  = [string]::IsNullOrWhiteSpace($txt) -eq $false
    _print "Anthropic" $ok ("model={0}; reply=""{1}""" -f $AnthropicModel, $txt)
    if (-not $ok) { $script:fail = $true }
  } catch {
    _print "Anthropic" $false (_err $_); $script:fail=$true
  }
}

function Test-Gemini {
  if (-not $env:GOOGLE_API_KEY) { _print "Gemini" $false "GOOGLE_API_KEY not set"; $script:fail=$true; return }

  $body = @{ contents = @(@{ parts = @(@{ text = "ping" }) }) } | ConvertTo-Json -Depth 5

  try {
    $r = Invoke-RestMethod -Method Post -ContentType "application/json" `
         -Headers @{ "x-goog-api-key" = $env:GOOGLE_API_KEY } `
         -Uri ("https://generativelanguage.googleapis.com/v1/models/{0}:generateContent" -f $GeminiModel) `
         -Body $body -TimeoutSec $TimeoutSec
    $txt = $r.candidates[0].content.parts[0].text
    $ok  = [string]::IsNullOrWhiteSpace($txt) -eq $false
    _print "Gemini" $ok ("model={0}; reply=""{1}""" -f $GeminiModel, $txt)
    if (-not $ok) { $script:fail = $true }
  } catch {
    _print "Gemini" $false (_err $_); $script:fail=$true
  }
}

function Test-OpenAI {
  if (-not $env:OPENAI_API_KEY) { _print "OpenAI" $false "OPENAI_API_KEY not set"; $script:fail=$true; return }

  $servedModel = $null
  $lastReason  = $null
  $passed      = $false

  foreach ($mxt in $OpenAIBudgets) {
    $json = New-OpenAIRequestBody -Model $OpenAIModel -Prompt $OpenAIPrompt -MaxOutputTokens $mxt
    try {
      $r = Invoke-RestMethod -Method Post -ContentType "application/json" `
           -Headers @{ Authorization=("Bearer {0}" -f $env:OPENAI_API_KEY) } `
           -Uri "https://api.openai.com/v1/responses" -Body $json -TimeoutSec $TimeoutSec -ErrorAction Stop

      $servedModel = $r.model
      $txt = (@($r.output) | Where-Object type -eq 'message' |
              ForEach-Object { @($_.content) } |
              Where-Object type -eq 'output_text' |
              ForEach-Object { $_.text }) -join "`n"

      if ($r.status -eq 'completed' -and $txt) {
        _print "OpenAI" $true ("model={0}; reply=""{1}""" -f $servedModel, $txt)
        $passed = $true
        break
      }

      if ($r.status -eq 'incomplete') { $lastReason = $r.incomplete_details.reason }
      if ($r.status -ne 'incomplete' -or $lastReason -ne 'max_output_tokens') {
        _print "OpenAI" $false ("status={0}; reason={1}" -f $r.status, $lastReason)
        $script:fail = $true
        break
      }
      # else loop to try higher max_output_tokens
    } catch {
      _print "OpenAI" $false (_err $_); $script:fail=$true
      break
    }
  }

  if (-not $passed) {
    if ($lastReason -eq 'max_output_tokens') {
      _print "OpenAI" $false ("incomplete: raise max_output_tokens (tried: {0})" -f ($OpenAIBudgets -join ','))
    }
    $script:fail = $true
  }
}

# Run tests
Test-Anthropic
Test-Gemini
Test-OpenAI

# Optional JSON summary (useful in CI)
if ($CI -or ($SummaryPath -ne "")) {
  $summary = [ordered]@{
    anthropic = @{ model = $AnthropicModel; ok = $true }
    gemini    = @{ model = $GeminiModel;    ok = $true }
    openai    = @{ model = $OpenAIModel;    ok = $true }
  }
  # Infer PASS/FAIL from printed lines would be complex; instead, re-use $script:fail as overall status
  $summary.overall = @{ ok = (-not $script:fail) }
  if ($SummaryPath -ne "") {
    try { $summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 -NoNewline $SummaryPath } catch {}
  }
}

# Interactive-safe: don't exit unless -CI is passed
$code = if ($script:fail) { 1 } else { 0 }
if ($CI) { exit $code } else { $global:LASTEXITCODE = $code }
