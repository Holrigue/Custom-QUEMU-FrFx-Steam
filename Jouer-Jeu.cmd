@echo off
setlocal
rem Mode jeu : SDL plein ecran + souris relative verrouillee, pour le Remote Play.
rem La souris ne sort plus de la fenetre (meme en multi-ecrans). Ctrl+Alt+G libere; Ctrl+Alt+F quitte le plein ecran.
powershell.exe -NoLogo -NoProfile -File "%~dp0scripts\Launch.ps1" -Gaming %*
if errorlevel 1 pause
