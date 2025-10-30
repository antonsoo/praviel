$ErrorActionPreference = 'Stop'

$pyCandidates = @(
  "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
  "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
  "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
  "$env:USERPROFILE\Anaconda3\python.exe",
  "$env:USERPROFILE\anaconda3\python.exe",
  "$env:USERPROFILE\miniconda3\python.exe"
) | Where-Object { $_ -and (Test-Path $_) -and ($_ -notlike "*WindowsApps*") }

$pythonExe = $pyCandidates | Select-Object -First 1
$usePyLauncher = $false
if (-not $pythonExe) {
  $pyLauncher = (Get-Command py.exe -ErrorAction SilentlyContinue)?.Source
  if ($pyLauncher) { $usePyLauncher = $true }
}

if ($usePyLauncher) {
  py -3 -m pip --version *> $null; if ($LASTEXITCODE -ne 0) { py -3 -m ensurepip --upgrade *> $null }
  py -3 -m pip install --user --disable-pip-version-check pre-commit *> $null
  py -3 -m pre_commit @args
  exit $LASTEXITCODE
} elseif ($pythonExe) {
  & $pythonExe -m pip --version *> $null; if ($LASTEXITCODE -ne 0) { & $pythonExe -m ensurepip --upgrade *> $null }
  & $pythonExe -m pip install --user --disable-pip-version-check pre-commit *> $null
  & $pythonExe -m pre_commit @args
  exit $LASTEXITCODE
} else {
  Write-Error "No usable Python found; install Python 3.12+ or ensure 'py.exe' is available."
}
