[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SshAddPath {
    $command = Get-Command ssh-add -ErrorAction SilentlyContinue
    if (-not $command) {
        throw '[ssh-agent] ssh-add not found on PATH'
    }
    return $command.Source
}

function Start-AgentIfNeeded {
    param([string]$SshAdd)

    & $SshAdd -l *> $null
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 2) {
        return $exitCode
    }

    $output = & ssh-agent
    if ($LASTEXITCODE -ne 0) {
        throw '[ssh-agent] failed to start ssh-agent'
    }

    foreach ($line in $output -split "`n") {
        if ($line -match '^(SSH_AUTH_SOCK|SSH_AGENT_PID)=([^;]+);') {
                    Set-Item -Path ("Env:{0}" -f $matches[1]) -Value $matches[2]
        }
    }

    & $SshAdd -l *> $null
    return $LASTEXITCODE
}

function Try-AddDefaultKeys {
    param([string]$SshAdd)

    $userProfile = [Environment]::GetFolderPath('UserProfile')
    if (-not $userProfile) {
        return $false
    }

    $keyDir = Join-Path $userProfile '.ssh'
    if (-not (Test-Path $keyDir)) {
        return $false
    }

    $candidates = @('id_ed25519','id_rsa','id_ecdsa','id_dsa')
    foreach ($name in $candidates) {
        $keyPath = Join-Path $keyDir $name
        if (-not (Test-Path $keyPath)) {
            continue
        }

        $process = Start-Process -FilePath $SshAdd -ArgumentList @('-q', $keyPath) -NoNewWindow -PassThru
        if (-not $process.WaitForExit(3)) {
            try { $process.Kill() } catch {}
            return $false
        }
        if ($process.ExitCode -eq 0) {
            return $true
        }
    }

    return $false
}

try {
    $sshAddPath = Get-SshAddPath
    $status = Start-AgentIfNeeded -SshAdd $sshAddPath

    if ($status -eq 0) {
        Write-Output '::SSH::READY'
        exit 0
    }

    if ($status -ne 1) {
        throw '[ssh-agent] ssh-add -l failed'
    }

    if (Try-AddDefaultKeys -SshAdd $sshAddPath) {
        & $sshAddPath -l *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Output '::SSH::READY'
            exit 0
        }
    }

    Write-Output '::SSH::LOCKED'
    exit 2
} catch {
    Write-Output '::SSH::FAIL'
    Write-Error $_
    exit 1
}
