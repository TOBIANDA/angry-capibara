@echo off
setlocal
title Angry Capibara - Visual Studio OpenGL Asset Forge
cd /d "%~dp0"

if exist "bin\Release\AngryCapibaraAssets.exe" goto :run_release
if exist "bin\Debug\AngryCapibaraAssets.exe" goto :run_debug

echo [INFO] Binary belum ditemukan. Mencoba build otomatis dengan MSBuild...
set "MSBUILD="
for %%M in (
    "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
) do (
    if exist %%M (
        if not defined MSBUILD set "MSBUILD=%%~M"
    )
)

if defined MSBUILD (
    "%MSBUILD%" "AngryCapibaraAssets.sln" /p:Configuration=Release /p:Platform=Win32 /m /v:minimal
    if exist "bin\Release\AngryCapibaraAssets.exe" goto :run_release
)

echo.
echo [ERROR] AngryCapibaraAssets.exe belum dibuild.
echo Buka AngryCapibaraAssets.sln di Visual Studio lalu Build Win32 ^(Release^).
echo Pastikan library OpenGL ^(freeglut/glew/glm^) tersedia di C:\OpenGLwrappers.
echo.
pause
goto :eof

:run_release
start "" "%~dp0bin\Release\AngryCapibaraAssets.exe"
goto :eof

:run_debug
start "" "%~dp0bin\Debug\AngryCapibaraAssets.exe"
goto :eof
