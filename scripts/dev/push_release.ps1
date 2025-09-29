[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
$withGitEnv = Join-Path $root 'scripts/dev/with_git_env.ps1'
$toolsDir = Join-Path $root 'tools'
$unlockScript = Join-Path $toolsDir 'unlock_ssh.ps1'
$neverStuckScript = Join-Path $toolsDir 'never_stuck.ps1'

function Invoke-ResilientCommand {
    param(
        [string]$Command,
        [int]$Timeout = 300
    )

    if (Test-Path $neverStuckScript) {
        & $neverStuckScript -Cmd $Command -TimeoutSec $Timeout -Retries 1
        return $LASTEXITCODE
    }

    & pwsh -NoLogo -NoProfile -Command $Command
    return $LASTEXITCODE
}

try {
    & $withGitEnv | ForEach-Object { Write-Output $_ }

    if (Test-Path $unlockScript) {
        & $unlockScript 2>$null
    }

    $env:GIT_SSH_COMMAND = "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"

    Push-Location -LiteralPath $root
    try {
        & pre-commit run --all-files
        if ($LASTEXITCODE -ne 0) {
            Write-Output '::PUSH::FAIL::PRECOMMIT'
            exit $LASTEXITCODE
        }

        $probe = Invoke-ResilientCommand -Command 'git ls-remote --heads origin' -Timeout 60
        if ($probe -ne 0) {
            if (Test-Path $unlockScript) {
                & $unlockScript 2>$null
            }
            $probe = Invoke-ResilientCommand -Command 'git ls-remote --heads origin' -Timeout 60
            if ($probe -ne 0) {
                Write-Output '::PUSH::FAIL::GIT_PROBE'
                exit $probe
            }
        }

        $push = Invoke-ResilientCommand -Command 'git push origin HEAD:main --follow-tags'
        if ($push -ne 0) {
            if (Test-Path $unlockScript) {
                & $unlockScript 2>$null
            }
            $push = Invoke-ResilientCommand -Command 'git push origin HEAD:main --follow-tags'
            if ($push -ne 0) {
                Write-Output '::PUSH::FAIL::GIT_PUSH'
                exit $push
            }
        }
    } finally {
        Pop-Location
    }

    Write-Output '::PUSH::OK'
    exit 0
} catch {
    Write-Output '::PUSH::FAIL::UNEXPECTED'
    Write-Error $_
    exit 1
}
