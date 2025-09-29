$ErrorActionPreference="Stop"
if ($env:AI_AGENT_SSH_PASSPHRASE) { [Console]::Out.Write($env:AI_AGENT_SSH_PASSPHRASE); exit 0 }
$path = Join-Path $PSScriptRoot '.secrets\ssh_passphrase.xml'
if (-not (Test-Path $path)) { exit 2 }
$sec = Import-Clixml -Path $path
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try { [Console]::Out.Write([Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
