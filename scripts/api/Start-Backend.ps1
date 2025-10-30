# Start backend with .env loaded
Push-Location backend
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#=]+)=([^#]*)') {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        if ($key -and $val) {
            Set-Item -Path "env:$key" -Value $val
        }
    }
}
$env:PYTHONPATH = "backend"
py -m uvicorn app.main:app --reload
Pop-Location
