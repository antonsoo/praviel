Param(
  [int]$Port = 8000
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path

function Get-PythonCommand {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if ($python -and $python.Source -and $python.Source -notlike '*WindowsApps*') {
    return [pscustomobject]@{ Exe = 'python'; Args = @() }
  }
  $python3 = Get-Command python3 -ErrorAction SilentlyContinue
  if ($python3 -and $python3.Source -and $python3.Source -notlike '*WindowsApps*') {
    return [pscustomobject]@{ Exe = 'python3'; Args = @() }
  }
  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) {
    return [pscustomobject]@{ Exe = 'py'; Args = @('-3') }
  }
  throw "Python interpreter not found; activate the project environment."
}

$python = Get-PythonCommand
$pythonExe = $python.Exe
$pythonArgs = $python.Args

$env:PYTHONPATH = Join-Path $root "backend"
$env:LESSONS_ENABLED = "1"

Write-Host "[lessons] Starting Postgres via docker compose"
docker compose up -d db | Out-Host

Write-Host "[lessons] Applying migrations"
$alembicArgs = $pythonArgs + @('-m', 'alembic', '-c', (Join-Path $root 'alembic.ini'), 'upgrade', 'head')
& $pythonExe $alembicArgs

$uvicornArgs = $pythonArgs + @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', $Port, '--log-level', 'warning')
Write-Host "[lessons] Launching API on port $Port"
$server = Start-Process -FilePath $pythonExe -ArgumentList $uvicornArgs -PassThru -WindowStyle Hidden
try {
  Start-Sleep -Seconds 3
  $payload = '{"language":"grc","profile":"beginner","sources":["daily","canon"],"exercise_types":["alphabet","match","cloze","translate"],"k_canon":2,"include_audio":false,"provider":"echo"}'
  Write-Host "[lessons] Hitting /lesson/generate"
  $uri = "http://127.0.0.1:$Port/lesson/generate"
  $response = Invoke-RestMethod -Method Post -Uri $uri -Body $payload -ContentType 'application/json'
  $response | ConvertTo-Json -Depth 5 | Out-Host
}
finally {
  if ($server -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force
  }
}
