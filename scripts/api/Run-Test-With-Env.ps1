# Load .env file and run Test-LLMKeys.ps1
Get-Content backend\.env | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        Set-Item -Path "env:$key" -Value $val
    }
}

& "$PSScriptRoot\Test-LLMKeys.ps1" -SummaryPath ".\llmkeys.summary.json"
