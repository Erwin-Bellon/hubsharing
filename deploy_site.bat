@ECHO OFF
SETLOCAL
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_site.ps1" %*
PAUSE
