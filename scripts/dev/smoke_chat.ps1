Param(
  [int]$Port = 0
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $root

function Get-PythonCommand {
  $candidates = @('python', 'python3', 'py')
  foreach ($candidate in $candidates) {
    $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and $cmd.Source -notlike '*WindowsApps*') {
      if ($candidate -eq 'py') {
        return [pscustomobject]@{ Exe = 'py'; Args = @('-3') }
      }
      return [pscustomobject]@{ Exe = $candidate; Args = @() }
    }
  }
  throw "Python interpreter not found; activate the project environment."
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

  Write-Host "[chat] Testing /chat/converse with athenian_merchant"
  $payload = '{"message":"χαῖρε","persona":"athenian_merchant","provider":"echo"}'
  $uri = "http://127.0.0.1:$Port/chat/converse"
  $response = Invoke-RestMethod -Method Post -Uri $uri -Body $payload -ContentType 'application/json'
  $response | ConvertTo-Json -Depth 5 | Out-Host

  Write-Host "[chat] Testing /lesson/generate with text_range"
  $payload = '{"language":"grc","profile":"beginner","text_range":{"ref_start":"1.1","ref_end":"1.5"},"exercise_types":["match","cloze"],"provider":"echo"}'
  $uri = "http://127.0.0.1:$Port/lesson/generate"
  $response = Invoke-RestMethod -Method Post -Uri $uri -Body $payload -ContentType 'application/json'
  $response | ConvertTo-Json -Depth 5 | Out-Host

  Write-Host "[chat] Testing /lesson/generate with register=colloquial"
  $payload = '{"language":"grc","profile":"beginner","register":"colloquial","exercise_types":["match","translate"],"provider":"echo"}'
  $uri = "http://127.0.0.1:$Port/lesson/generate"
  $response = Invoke-RestMethod -Method Post -Uri $uri -Body $payload -ContentType 'application/json'
  $response | ConvertTo-Json -Depth 5 | Out-Host

  Write-Host "[chat] All smoke tests passed!"
}
finally {
  & (Join-Path $root 'scripts/dev/serve_uvicorn.ps1') stop | Out-Host
  $env:UVICORN_PYTHON = $prevUvicornPython
}
