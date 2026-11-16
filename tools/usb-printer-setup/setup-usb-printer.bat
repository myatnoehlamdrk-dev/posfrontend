@echo off
setlocal
title Smart POS - USB Printer Setup
cd /d "%~dp0"

:: The zip is usually opened before it is extracted, in which case Windows
:: runs only this .bat from a temp copy and its helpers are not here. Say so
:: before anything else - especially before the elevation prompt.
if not exist "%~dp0setup.ps1" (
    echo.
    echo  This file must run from the extracted folder.
    echo.
    echo  Right-click usb-printer-setup.zip ^> Extract All,
    echo  then run setup-usb-printer.bat from the extracted folder.
    echo.
    pause
    exit /b 1
)

:: Driver installation needs administrator rights: relaunch elevated once.
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator permission...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
echo.
pause
