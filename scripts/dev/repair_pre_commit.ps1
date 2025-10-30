[CmdletBinding()]
param(
  [switch]$Autoupdate = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command pre-commit -ErrorAction SilentlyContinue)) {
  Write-Host "Installing pre-commit into the current Python env..."
  pip install -U pre-commit | Out-Host
}

Write-Host "Cleaning pre-commit cache..."
pre-commit clean

# Remove any pre-push hook that might have been installed previously
pre-commit uninstall --hook-type pre-push 2>$null | Out-Null
# Reinstall only pre-commit hook
pre-commit uninstall --hook-type pre-commit 2>$null | Out-Null
pre-commit install --hook-type pre-commit

if ($Autoupdate) {
  Write-Host "Autoupdating hook versions..."
  pre-commit autoupdate
}

Write-Host "Priming cache by running on all files..."
pre-commit run --all-files
Write-Host "Done."
