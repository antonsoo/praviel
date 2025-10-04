# Minimal test - exactly what the docs say worked
$ErrorActionPreference = 'Stop'

# Load passphrase
$vault = "tools\.secrets\ssh_pass.xml"
$sec = Import-Clixml $vault
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
    $pass = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# Kill any existing agents
Get-Process ssh-agent -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Start ssh-agent and capture environment
$agentOut = & "C:\Program Files\Git\usr\bin\ssh-agent.exe" -s
Write-Output "Agent output:"
Write-Output $agentOut

foreach ($line in ($agentOut -split "`r?`n")) {
    if ($line -match '^(SSH_AUTH_SOCK|SSH_AGENT_PID)=([^;]+);') {
        Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
        Write-Output "Set $($matches[1]) = $($matches[2])"
    }
}

# Verify environment
Write-Output "`nEnvironment check:"
Write-Output "SSH_AUTH_SOCK = $env:SSH_AUTH_SOCK"
Write-Output "SSH_AGENT_PID = $env:SSH_AGENT_PID"

# Add key - exactly as docs show
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519"
$sshAdd = "C:\Program Files\Git\usr\bin\ssh-add.exe"

Write-Output "`nAdding key..."
Write-Output "Command: echo pass | ssh-add keypath"

# This is what worked according to the docs
$output = cmd /c "echo $pass | `"$sshAdd`" `"$keyPath`" 2>&1"
Write-Output "Output: $output"
Write-Output "Exit code: $LASTEXITCODE"

# List keys
Write-Output "`nListing keys..."
& $sshAdd -l
Write-Output "List exit code: $LASTEXITCODE"

if ($LASTEXITCODE -eq 0) {
    Write-Output "`n::SUCCESS::"
} else {
    Write-Output "`n::FAILED::"
}
