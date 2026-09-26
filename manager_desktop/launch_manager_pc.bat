@echo off
echo ========================================================
echo Starting Siaka Phones Manager Desktop (PC Workstation)
echo ========================================================
echo.
cd /d "%~dp0"
start "" "http://localhost:5050"
dart pub global run dhttpd --path build\web --port 5050 --host localhost
