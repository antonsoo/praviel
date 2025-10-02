@echo off
REM Kill all Python processes
taskkill /F /IM python.exe /T 2>nul
timeout /t 2 /nobreak >nul
echo All Python processes terminated
