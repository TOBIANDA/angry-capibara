@echo off
setlocal EnableDelayedExpansion
title Angry Capibara - Godot 4.7+ Launcher
cd /d "%~dp0"

set "GODOT_BIN="

REM 1. Cek environment variable GODOT_EXE jika user sudah mengaturnya
if defined GODOT_EXE (
    if exist "%GODOT_EXE%" (
        set "GODOT_BIN=%GODOT_EXE%"
        goto :launch
    )
)

REM 2. Cek executable godot di PATH sistem
for %%G in (godot4.exe godot.exe) do (
    for /f "delims=" %%P in ('where %%G 2^>nul') do (
        if not defined GODOT_BIN set "GODOT_BIN=%%P"
    )
)
if defined GODOT_BIN goto :launch

REM 3. Cari otomatis di folder umum laptop Windows (Downloads, Desktop, LocalAppData, D:\Godot, C:\Godot, folder proyek)
for %%D in ("%~dp0" "%~dp0.." "%USERPROFILE%\Downloads" "%USERPROFILE%\Desktop" "%LOCALAPPDATA%\Programs" "D:\Godot" "C:\Godot" "C:\Program Files\Godot") do (
    if exist "%%~D" (
        for /f "delims=" %%F in ('dir /b /s /a-d "%%~D\Godot*win64*.exe" 2^>nul') do (
            echo %%~nxF | findstr /i "console" >nul
            if errorlevel 1 (
                if not defined GODOT_BIN set "GODOT_BIN=%%F"
            )
        )
    )
    if defined GODOT_BIN goto :launch
)

echo.
echo [ERROR] Godot Engine 4.7+ tidak ditemukan di laptop ini.
echo Solusi:
echo   1. Unduh Godot 4.7+ Win64 dari https://godotengine.org/download/windows/
echo   2. Letakkan file Godot_v4.7*_win64.exe di folder Downloads atau di folder proyek ini,
echo      ATAU set environment variable GODOT_EXE ke lokasi Godot.exe Anda.
echo.
pause
goto :eof

:launch
echo Menjalankan Angry Capibara dengan: "%GODOT_BIN%"
start "" "%GODOT_BIN%" --path "%~dp0."
endlocal
