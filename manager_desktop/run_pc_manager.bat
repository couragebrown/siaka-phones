@echo off
echo ========================================================
echo Launching Siaka Phones Manager Desktop (Windows PC)
echo ========================================================
echo.
cd /d "%~dp0"
start "" "build\windows\x64\runner\Release\manager_desktop.exe"
