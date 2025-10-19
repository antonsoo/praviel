# PowerShell script to fix Greek accents
$pythonPath = "C:\Users\thoma\miniconda3\envs\ancient-languages-py312\python.exe"
Set-Location "C:\Dev\AI_Projects\AncientLanguagesAppDirs\Current-working-dirs\AncientLanguages\backend"
& $pythonPath scripts\fix_greek_accents.py
