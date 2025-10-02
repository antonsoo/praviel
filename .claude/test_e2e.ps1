# End-to-end test - run unlock script in background, then test git
$ErrorActionPreference = 'Continue'

Write-Output "=== Phase 1: Kill existing agents ==="
Get-Process ssh-agent -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

Write-Output "`n=== Phase 2: Run unlock_ssh.ps1 in background job ==="
$job = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    & .\tools\unlock_ssh.ps1
}

Write-Output "Waiting for job (10 sec max)..."
$completed = Wait-Job $job -Timeout 10
if ($completed) {
    Write-Output "Job completed normally"
    Receive-Job $job
    Remove-Job $job
} else {
    Write-Output "Job timed out (expected) - checking if it succeeded anyway..."
    Start-Sleep -Seconds 1
    $output = Receive-Job $job
    Write-Output $output
    Remove-Job $job -Force

    if ($output -match '::SSH::READY') {
        Write-Output "::UNLOCK::SUCCESS (despite timeout)"
    } else {
        Write-Output "::UNLOCK::FAILED"
        exit 1
    }
}

Write-Output "`n=== Phase 3: Source the agent environment ==="
$agentEnv = Get-Content "tools\.secrets\agent.env" -Raw
foreach ($line in ($agentEnv -split "`n")) {
    if ($line -match '^(SSH_AUTH_SOCK|SSH_AGENT_PID)=(.+)$') {
        Set-Item -Path "Env:$($matches[1])" -Value $matches[2].Trim()
        Write-Output "Set $($matches[1]) = $($matches[2].Trim())"
    }
}

Write-Output "`n=== Phase 4: Verify agent has key ==="
ssh-add -l
if ($LASTEXITCODE -eq 0) {
    Write-Output "::KEYS::LISTED"
} else {
    Write-Output "::KEYS::FAILED"
    exit 1
}

Write-Output "`n=== Phase 5: Test Git operation ==="
$env:GIT_SSH_COMMAND = 'ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new'
git push --dry-run --no-verify origin HEAD:main 2>&1 | Write-Output
if ($LASTEXITCODE -eq 0) {
    Write-Output "::GIT::AUTONOMOUS_VERIFIED"
} else {
    Write-Output "::GIT::FAILED"
}

Write-Output "`n=== Final status ==="
git log --oneline -n 3
Write-Output ""
ssh-add -l