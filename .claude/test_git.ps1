# Test full Git workflow
Get-Process ssh-agent -EA SilentlyContinue | Stop-Process -Force
Remove-Item tools\.secrets\agent.env -EA SilentlyContinue
Start-Sleep -Milliseconds 500

Write-Output "=== Starting agent ==="
. .\tools\ssh_agent_start.ps1

Write-Output "`n=== Verifying key loaded ==="
ssh-add -l

Write-Output "`n=== Testing Git push (dry-run) ==="
$env:GIT_SSH_COMMAND = 'ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new'
git push --dry-run --no-verify origin HEAD:main

if ($LASTEXITCODE -eq 0) {
    Write-Output "`n::GIT::AUTONOMOUS_VERIFIED"
} else {
    Write-Output "`n::GIT::FAILED (exit code: $LASTEXITCODE)"
    exit 1
}

Write-Output "`n=== Recent commits ==="
git log --oneline -n 3

[Environment]::Exit(0)