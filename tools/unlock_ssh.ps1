param([string]$Key="$env:USERPROFILE\.ssh\id_ed25519",[int]$TimeoutSec=20)
$ErrorActionPreference="Stop"
$gitUsr=Join-Path $env:ProgramFiles "Git\usr\bin"
if (Test-Path $gitUsr) {
  if (-not (($env:Path -split ';') -contains $gitUsr)) {
    $env:Path = "$gitUsr;$env:Path"
  }
}

function Resolve-GitCommand {
  param([string]$Name)
  $candidate = Join-Path $gitUsr $Name
  if (Test-Path $candidate) { return $candidate }
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "$Name not found" }
  return $cmd.Source
}

$sshAdd   = Resolve-GitCommand "ssh-add.exe"
$sshAgent = Resolve-GitCommand "ssh-agent.exe"

$secretsDir = Join-Path $PSScriptRoot '.secrets'
New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null
$sockFile = Join-Path $secretsDir 'agent.sock'

if (-not $env:SSH_AUTH_SOCK) {
  $output = & $sshAgent -s
  foreach ($line in $output -split "`n") {
    if ($line -match "^(SSH_AUTH_SOCK|SSH_AGENT_PID)=([^;]+);") {
      Set-Item ("Env:{0}" -f $matches[1]) ($matches[2])
    }
  }
}

if (-not $env:SSH_AUTH_SOCK) { throw "ssh-agent unavailable" }

$env:SSH_AUTH_SOCK | Set-Content -Path $sockFile -Encoding ASCII

$existing = & $sshAdd -l
if ($LASTEXITCODE -eq 0 -and $existing -match [Regex]::Escape((Resolve-Path $Key))) {
  Write-Output "::SSH::READY"
  exit 0
}

$ask = Join-Path $PSScriptRoot 'git_askpass.cmd'
if (-not (Test-Path $ask)) {
  Set-Content -Path $ask -Value @(
    '@echo off',
    'setlocal',
    'powershell -NoLogo -NoProfile -File "%~dp0get_ssh_pass.ps1"'
  ) -Encoding ASCII
}

$secretFile = Join-Path $secretsDir 'ssh_passphrase.xml'
if (-not $env:AI_AGENT_SSH_PASSPHRASE -and -not (Test-Path $secretFile)) {
  Write-Output "::BLOCKED::NEED_SECRET"
  exit 10
}

$env:SSH_ASKPASS = $ask
$env:SSH_ASKPASS_REQUIRE = "force"
$env:DISPLAY = "dummy:0"

$process = Start-Process -FilePath $sshAdd -ArgumentList (Resolve-Path $Key) -PassThru -WindowStyle Hidden
if (-not $process.WaitForExit($TimeoutSec * 1000)) {
  try { $process.Kill() } catch { }
  throw "ssh-add timeout"
}

if ($process.ExitCode -ne 0) {
  throw "ssh-add failed: $($process.ExitCode)"
}

Write-Output "::SSH::READY"
