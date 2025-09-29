@echo off
setlocal
py -3 -m pre_commit %*
exit /b %ERRORLEVEL%
