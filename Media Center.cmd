@echo off
setlocal
title USB-VM Linux Media Center (portable)
set "PS=%~dp0system\scripts"

:menu
cls
echo ==================================================
echo    USB-VM LINUX MEDIA CENTER  -  portable QEMU kit
echo ==================================================
echo.
echo    [1]  Play             (fullscreen, for Remote Play)
echo    [2]  Desktop mode     (windowed, for setup / browsing)
echo    [3]  Paste clipboard into the VM
echo         (start the VM first, then open this menu again)
echo    [4]  First-time setup (install Linux - run once)
echo    [5]  Hardware check   (WHPX diagnostic)
echo.
echo    [0]  Quit
echo.
set "choice="
set /p "choice=Type a number and press Enter: "

if "%choice%"=="1" goto play
if "%choice%"=="2" goto desktop
if "%choice%"=="3" goto paste
if "%choice%"=="4" goto setup
if "%choice%"=="5" goto check
if "%choice%"=="0" goto end
goto menu

:play
powershell.exe -NoLogo -NoProfile -File "%PS%\Launch.ps1" -Gaming -Control
if errorlevel 1 pause
goto menu

:desktop
powershell.exe -NoLogo -NoProfile -File "%PS%\Launch.ps1" -Control
if errorlevel 1 pause
goto menu

:paste
powershell.exe -NoLogo -NoProfile -STA -File "%PS%\Paste-ToVM.ps1"
if errorlevel 1 pause
goto menu

:setup
powershell.exe -NoLogo -NoProfile -File "%PS%\Launch.ps1" -Install
if errorlevel 1 pause
goto menu

:check
powershell.exe -NoLogo -NoProfile -File "%PS%\Launch.ps1" -CheckOnly
pause
goto menu

:end
endlocal
