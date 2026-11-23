@echo off
title Angry Capibara - Visual Studio OpenGL Asset Forge
cd /d "%~dp0"
if exist "bin\Release\AngryCapibaraAssets.exe" (
    start "" "%~dp0bin\Release\AngryCapibaraAssets.exe"
    goto :eof
)
if exist "bin\Debug\AngryCapibaraAssets.exe" (
    start "" "%~dp0bin\Debug\AngryCapibaraAssets.exe"
    goto :eof
)
echo AngryCapibaraAssets.exe belum dibuild. Buka AngryCapibaraAssets.sln di Visual Studio lalu Build Win32.
pause
