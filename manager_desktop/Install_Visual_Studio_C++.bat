@echo off
title Installing Missing Visual Studio C++ Components for Flutter Windows
cd /d "%~dp0"
echo ======================================================================
echo    INSTALLING REQUIRED C++ COMPONENTS FOR WINDOWS APPS
echo ======================================================================
echo.
echo Visual Studio Build Tools base is installed! 
echo Now installing the 3 required Flutter C++ components:
echo   1. MSVC C++ x64/x86 Compiler Tools
echo   2. Windows 10/11 SDK
echo   3. C++ CMake Tools
echo.
echo (If Windows asks for administrator permission, click YES)
echo.

set "VS_INSTALLER=C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe"
set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"

if exist "%VS_INSTALLER%" (
    echo Launching Visual Studio Installer to add required C++ components...
    "%VS_INSTALLER%" modify --installPath "%VS_PATH%" --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.VC.CMake.Project --passive --norestart
) else (
    echo Launching setup...
    "C:\Users\coura\AppData\Local\Temp\WinGet\Microsoft.VisualStudio.2022.BuildTools.17.14.41\vs_BuildTools.exe" --passive --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.VC.CMake.Project
)

echo.
echo ======================================================================
echo    VERIFYING FLUTTER WINDOWS BUILD ENVIRONMENT
echo ======================================================================
echo.
set "PATH=%PATH%;C:\Users\coura\AppData\Local\flutter\bin"
call flutter doctor -v

echo.
echo ======================================================================
echo    ALL SET! You can now launch Siaka Phones Manager Desktop (.exe)
echo ======================================================================
pause
