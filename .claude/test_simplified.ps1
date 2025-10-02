# Test simplified stdin method
$vault = "tools\.secrets\ssh_pass.xml"
$sec = Import-Clixml $vault
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
    $pass = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# Start ssh-agent
$agentOut = & "C:\Program Files\Git\usr\bin\ssh-agent.exe" -s
foreach ($line in ($agentOut -split "`r?`n")) {
    if ($line -match '^(SSH_AUTH_SOCK|SSH_AGENT_PID)=([^;]+);') {
        Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
    }
}

# Add key via stdin (reliable method)
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519"
$sshAdd = "C:\Program Files\Git\usr\bin\ssh-add.exe"
cmd /c "echo $pass | `"$sshAdd`" `"$keyPath`" 2>&1"

# Verify
& $sshAdd -l
if ($LASTEXITCODE -eq 0) {
    Write-Output "::SIMPLIFIED::SUCCESS"
} else {
    Write-Output "::SIMPLIFIED::FAILED"
}