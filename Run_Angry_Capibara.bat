@echo off
title Angry Capibara - Launcher
cd /d "%~dp0"

set "GODOT_EXE=C:\Users\kuahs\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"
if not exist "%GODOT_EXE%" (
    set "GODOT_EXE=C:\Users\kuahs\Downloads\Godot_v4.7.1-stable_win64.exe"
)

if not exist "%GODOT_EXE%" (
    echo [ERROR] Executable Godot tidak ditemukan di:
    echo %GODOT_EXE%
    echo Silakan cek letak file Godot Anda.
    pause
    exit /b 1
)

echo Membuka Angry Capibara...
start "" "%GODOT_EXE%" --path "%~dp0godot_project"
exit
