$env:GOOGLE_API_KEY = (Get-Content backend\.env | Select-String '^GOOGLE_API_KEY=' | ForEach-Object { ($_ -replace '^GOOGLE_API_KEY=', '') -replace ' *#.*', '' })
$body = @{
    contents = @(@{parts=@(@{text="Generate JSON: {`"tasks`":[{`"type`":`"match`"}]}"})})
    generationConfig = @{
        temperature = 0.9
        responseMimeType = "application/json"
    }
} | ConvertTo-Json -Depth 6
Write-Host "Sending:" $body
$headers = @{'x-goog-api-key' = $env:GOOGLE_API_KEY; 'Content-Type' = 'application/json'}
try {
  $response = Invoke-RestMethod -Method Post -Headers $headers -Uri 'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent' -Body $body
  Write-Host "SUCCESS"
  $response | ConvertTo-Json -Depth 10
} catch {
  Write-Host "Error: $($_.Exception.Message)"
  Write-Host "Details: $($_.ErrorDetails.Message)"
}
