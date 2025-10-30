# tools/never_stuck.ps1
# Run a command with timeout + targeted remediation; emits non-zero only after retries.
param(
  [Parameter(Mandatory=$true)][string]$Cmd,
  [int]$TimeoutSec = 300,
  [int]$Retries = 1
)

$ErrorActionPreference = "Stop"

function Invoke-Once {
  param(
    [string]$Command,
    [int]$TimeoutSeconds
  )

  $outFile = [System.IO.Path]::GetTempFileName()
  $errFile = [System.IO.Path]::GetTempFileName()
  $result = @{
    Code = 0
    OutFile = $outFile
    ErrFile = $errFile
  }

  try {
    $process = Start-Process -FilePath "pwsh" -ArgumentList "-NoLogo","-NoProfile","-Command",$Command -PassThru -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
      try { $process.Kill() } catch {}
      $result["Code"] = 124
      return $result
    }
    $result["Code"] = $process.ExitCode
    return $result
  } catch {
    Remove-Item -Path $outFile -ErrorAction SilentlyContinue
    Remove-Item -Path $errFile -ErrorAction SilentlyContinue
    throw
  }
}

$unlockScript = Join-Path $PSScriptRoot "unlock_ssh.ps1"
for ($attempt = 0; $attempt -le $Retries; $attempt++) {
  $run = Invoke-Once -Command $Cmd -TimeoutSeconds $TimeoutSec
  $code = [int]$run["Code"]
  $outFile = $run["OutFile"]
  $errFile = $run["ErrFile"]
  $stdout = if (Test-Path $outFile) { Get-Content -Path $outFile -Raw } else { "" }
  $stderr = if (Test-Path $errFile) { Get-Content -Path $errFile -Raw } else { "" }
  Remove-Item -Path $outFile -ErrorAction SilentlyContinue
  Remove-Item -Path $errFile -ErrorAction SilentlyContinue

  if ($code -eq 0) {
    if ($stdout) {
      Write-Output $stdout
    }
    exit 0
  }

  if ($stderr -match "Enter passphrase|Permission denied|Authentication failed|SSH.*LOCKED") {
    if (Test-Path $unlockScript) {
      & $unlockScript 2>$null
    }
  } elseif ($stderr -match "Host key verification failed") {
    $env:GIT_SSH_COMMAND = "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
  }

  if ($attempt -eq $Retries) {
    if ($stderr) {
      Write-Error $stderr
    }
    exit $code
  }
}
