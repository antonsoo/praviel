param([SecureString]$Passphrase)
$ErrorActionPreference="Stop"
$dir = Join-Path $PSScriptRoot '.secrets'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$path = Join-Path $dir 'ssh_passphrase.xml'
if (-not $Passphrase) { $Passphrase = Read-Host -AsSecureString -Prompt "SSH key passphrase (never logged)" }
$Passphrase | Export-Clixml -Path $path
Write-Output "::SECRET::STORED"
