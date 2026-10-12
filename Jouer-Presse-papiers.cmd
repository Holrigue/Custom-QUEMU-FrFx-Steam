@echo off
setlocal
rem Mode bureau AVEC le canal de controle local (loopback), requis par "Coller-dans-VM.cmd".
rem Permet de taper le presse-papiers Windows dans la VM (sens Windows -> VM). Clavier VM : US.
powershell.exe -NoLogo -NoProfile -File "%~dp0scripts\Launch.ps1" -Control %*
if errorlevel 1 pause
