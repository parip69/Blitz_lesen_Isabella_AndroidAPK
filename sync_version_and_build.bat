@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_version_and_build.ps1" %*
endlocal & exit /b %ERRORLEVEL%
