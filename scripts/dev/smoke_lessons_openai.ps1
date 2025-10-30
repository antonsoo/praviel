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

  Write-Host "[lessons-openai] Starting Postgres via docker compose"
  docker compose up -d db | Out-Host

  Write-Host "[lessons-openai] Applying migrations"
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

  # TEST WITH REAL OPENAI GPT-5
  # Use API key from .env file (already loaded by serve_uvicorn.ps1)
  $payload = '{"language":"grc","profile":"beginner","sources":["daily"],"exercise_types":["alphabet","match","translate"],"k_canon":0,"include_audio":false,"provider":"openai","model":"gpt-5-nano-2025-08-07","task_count":5}'
  Write-Host "[lessons-openai] Hitting /lesson/generate on port $Port with REAL OpenAI GPT-5 Nano"
  Write-Host "[lessons-openai] This will use real API credits - testing with 5 tasks only"
  $uri = "http://127.0.0.1:$Port/lesson/generate"

  # Get API key from .env
  $envFile = Join-Path $root 'backend\.env'
  $apiKey = $null
  if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
      if ($_ -match '^OPENAI_API_KEY=(.+)$') {
        $apiKey = $matches[1]
      }
    }
  }

  if ($null -eq $apiKey) {
    Write-Host "[lessons-openai] ERROR: OPENAI_API_KEY not found in backend/.env"
    exit 1
  }

  Write-Host "[lessons-openai] Using API key: $($apiKey.Substring(0,20))..."

  # Send request with API key in header
  $headers = @{
    "Content-Type" = "application/json"
    "X-OpenAI-API-Key" = $apiKey
  }

  $response = Invoke-RestMethod -Method Post -Uri $uri -Body $payload -ContentType 'application/json' -Headers $headers
  Write-Host "[lessons-openai] SUCCESS! Generated lesson with $($response.tasks.Count) tasks"
  Write-Host "[lessons-openai] Provider: $($response.meta.provider)"
  Write-Host "[lessons-openai] Model: $($response.meta.model)"
  Write-Host ""
  Write-Host "[lessons-openai] First task:"
  $response.tasks[0] | ConvertTo-Json -Depth 3 | Out-Host
}
finally {
  & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') stop | Out-Host
  $env:UVICORN_PYTHON = $prevUvicornPython
}
