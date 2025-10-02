# Test different piping methods
$ErrorActionPreference = 'Continue'

$vault = "tools\.secrets\ssh_pass.xml"
$sec = Import-Clixml $vault
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
    $pass = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

Get-Process ssh-agent -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$agentOut = & "C:\Program Files\Git\usr\bin\ssh-agent.exe" -s
foreach ($line in ($agentOut -split "`r?`n")) {
    if ($line -match '^(SSH_AUTH_SOCK|SSH_AGENT_PID)=([^;]+);') {
        Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
    }
}

$keyPath = "$env:USERPROFILE\.ssh\id_ed25519"
$sshAdd = "C:\Program Files\Git\usr\bin\ssh-add.exe"

Write-Output "Method 1: Using temporary expect-style script"
$expectScript = @"
#!/usr/bin/expect -f
spawn "$sshAdd" "$keyPath"
expect "Enter passphrase"
send "$pass\r"
expect eof
"@

# Method 2: Direct environment variable (if ssh-add supports it)
Write-Output "`nMethod 2: Check if key needs passphrase at all"
& $sshAdd -l 2>&1 | Write-Output
$needsAdd = $LASTEXITCODE -ne 0

if ($needsAdd) {
    Write-Output "`nMethod 3: Using SSH_ASKPASS with dummy display"
    $askScript = [System.IO.Path]::GetTempFileName() + ".ps1"
    Set-Content -Path $askScript -Value "Write-Output '$pass'"

    $env:SSH_ASKPASS_REQUIRE = 'force'
    $env:SSH_ASKPASS = "powershell.exe -NoProfile -File `"$askScript`""
    $env:DISPLAY = ':0'

    Write-Output "Running ssh-add with ASKPASS..."
    $job = Start-Job -ScriptBlock {
        param($sshAdd, $keyPath)
        & $sshAdd $keyPath 2>&1
    } -ArgumentList $sshAdd, $keyPath

    Wait-Job $job -Timeout 5 | Out-Null
    Receive-Job $job
    Remove-Job $job -Force -ErrorAction SilentlyContinue

    Remove-Item $askScript -Force -ErrorAction SilentlyContinue
    Remove-Item Env:SSH_ASKPASS_REQUIRE, Env:SSH_ASKPASS, Env:DISPLAY -ErrorAction SilentlyContinue
}

Write-Output "`nFinal check:"
& $sshAdd -l
Write-Output "Exit code: $LASTEXITCODE"