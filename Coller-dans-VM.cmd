@echo off
setlocal
rem Tape le presse-papiers Windows dans la fenetre active de la VM (sens Windows -> VM).
rem Prerequis : la VM tourne via Jouer-Presse-papiers.cmd (canal de controle local actif).
rem Avant de lancer : copie ton texte dans Windows, puis clique dans le champ cible de la VM.
powershell.exe -NoLogo -NoProfile -STA -File "%~dp0scripts\Paste-ToVM.ps1" %*
if errorlevel 1 pause
