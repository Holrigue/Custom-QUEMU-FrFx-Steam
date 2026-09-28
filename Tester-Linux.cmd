@echo off
setlocal
powershell.exe -NoLogo -NoProfile -File "%~dp0scripts\Launch.ps1" -Live %*
if errorlevel 1 pause
