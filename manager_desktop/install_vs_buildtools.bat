@echo off
setlocal EnableDelayedExpansion

:: Ensure running from script directory
cd /d "%~dp0"

:: Ensure Flutter SDK is in PATH
set "PATH=%PATH%;C:\Users\coura\AppData\Local\flutter\bin"

title Installing Visual Studio C++ Build Tools for Windows PC
echo ======================================================================
echo    INSTALLING VISUAL STUDIO C++ BUILD TOOLS FOR NATIVE WINDOWS APP
echo ======================================================================
echo.
echo  Installing required Flutter Windows C++ toolchain:
echo    - MSVC v143 C++ x64/x86 Compiler Tools
echo    - Windows 10/11 SDK
echo    - C++ CMake tools for Windows
echo.
echo  Please keep this window open while the installation completes.
echo.

set "VS_INSTALLER=C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe"
set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"

if exist "%VS_INSTALLER%" (
    echo Launching Visual Studio Installer to add required C++ components...
    "%VS_INSTALLER%" modify --installPath "%VS_PATH%" --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.VC.CMake.Project --passive --norestart
) else (
    set "INSTALLER=C:\Users\coura\AppData\Local\Temp\WinGet\Microsoft.VisualStudio.2022.BuildTools.17.14.41\vs_BuildTools.exe"
    if not exist "!INSTALLER!" (
        set "INSTALLER=%TEMP%\vs_BuildTools.exe"
        if not exist "!INSTALLER!" (
            echo Downloading latest vs_BuildTools.exe installer...
            powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_BuildTools.exe' -OutFile '%TEMP%\vs_BuildTools.exe'"
        )
    )
    start /wait "" "!INSTALLER!" --passive --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.VC.CMake.Project
)

echo.
echo ======================================================================
echo    VERIFYING FLUTTER WINDOWS BUILD ENVIRONMENT
echo ======================================================================
echo.
call flutter doctor -v

echo.
echo ======================================================================
echo    INSTALLATION COMPLETE!
echo.
echo    You can now run 'run_pc_manager.bat' to compile and launch the
echo    native Siaka Phones Manager Desktop (.exe) application.
echo ======================================================================
echo.
pause
