# PowerShell script to fix Greek accents
$pythonPath = "C:\Users\thoma\miniconda3\envs\praviel\python.exe"
Set-Location "C:\work\projects\praviel_files\praviel\backend"
& $pythonPath scripts\fix_greek_accents.py
