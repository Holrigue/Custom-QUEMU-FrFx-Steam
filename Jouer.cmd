@echo off
setlocal
rem -Control ouvre le canal de controle local (loopback 127.0.0.1) requis par Coller-dans-VM.cmd.
powershell.exe -NoLogo -NoProfile -File "%~dp0scripts\Launch.ps1" -Control %*
if errorlevel 1 pause
