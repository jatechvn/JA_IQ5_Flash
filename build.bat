@echo off
setlocal enabledelayedexpansion
title Build JA IQ5 Reflash - Release Packager

echo =======================================================================
echo                 JA IQ5 REFLASH - BUILD AND PACKAGER
echo =======================================================================
echo.

set WORKSPACE_DIR=%~dp0
cd /d "%WORKSPACE_DIR%"

:: Read app version from pubspec.yaml so release naming never drifts out of sync
for /f "tokens=2 delims= " %%v in ('findstr /b "version:" pubspec.yaml') do set PUBSPEC_VERSION=%%v
for /f "tokens=1 delims=+" %%v in ("%PUBSPEC_VERSION%") do set APP_VERSION=%%v
if "%APP_VERSION%"=="" set APP_VERSION=1.2.0
echo Detected app version: v%APP_VERSION%
echo.

:: 0. Kill running instances of the app
echo [0/5] Terminating any active ja_iq5_flash.exe instances...
taskkill /IM ja_iq5_flash.exe /F 2>nul
ping 127.0.0.1 -n 2 >nul
echo.

:: 1. Clean up old dist folder
echo [1/5] Clearing previous distribution folder...
if exist "dist" (
    rmdir /s /q "dist"
)
mkdir "dist"
echo.

:: 2. Build Windows App in Release mode
echo [2/5] Compiling Windows application (Release mode)...
call flutter build windows --release

if %ERRORLEVEL% neq 0 (
    echo.
    echo [WARN] Initial build failed, attempting cache cleanup and retry...
    if exist "build\windows\x64\CMakeCache.txt" del /f /q "build\windows\x64\CMakeCache.txt"
    if exist "windows\flutter\ephemeral" rmdir /s /q "windows\flutter\ephemeral"
    call flutter build windows --release
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Flutter build failed with error code %ERRORLEVEL%!
    pause
    exit /b %ERRORLEVEL%
)

set RELEASE_DIR=build\windows\x64\runner\Release

:: Remove old runtime data left behind by any previous run
if exist "%RELEASE_DIR%\config.json" del /f /q "%RELEASE_DIR%\config.json"
if exist "%RELEASE_DIR%\config.ini" del /f /q "%RELEASE_DIR%\config.ini"
if exist "%RELEASE_DIR%\logs" rmdir /s /q "%RELEASE_DIR%\logs"

echo.
:: 3. Copy bin, assets, debug script, and documentation to build output
echo [3/5] Bundling embedded binaries (bin\), assets, and docs to build output...
if exist "bin" (
    echo Copying bin/ ^(fh_loader.exe, DLLs^) to %RELEASE_DIR%\bin\...
    xcopy /e /i /y /q "bin" "%RELEASE_DIR%\bin\"
)
if exist "assets" (
    echo Copying assets/...
    xcopy /e /i /y /q "assets" "%RELEASE_DIR%\assets\"
)
if exist "debug.bat" copy /y "debug.bat" "%RELEASE_DIR%\" >nul
if exist "ABOUT.txt" copy /y "ABOUT.txt" "%RELEASE_DIR%\" >nul
if exist "README.md" copy /y "README.md" "%RELEASE_DIR%\" >nul
if exist "FLASH_TROUBLESHOOTING.md" copy /y "FLASH_TROUBLESHOOTING.md" "%RELEASE_DIR%\" >nul
if exist "LICENSE" copy /y "LICENSE" "%RELEASE_DIR%\" >nul
if exist "license.key.example" copy /y "license.key.example" "%RELEASE_DIR%\" >nul

:: Create .Release.lnk shortcut at workspace root pointing to dist\
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('.Release.lnk'); $Shortcut.TargetPath = Join-Path (Get-Item .).FullName 'dist'; $Shortcut.Save()"

echo.
:: 4. Copy fully self-contained release to dist/ (unpacked at root like Showcase)
echo [4/5] Copying complete self-contained release directly to dist\...
xcopy /e /i /y /q "%RELEASE_DIR%\*.*" "dist\"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Failed to copy release files to dist!
    pause
    exit /b %ERRORLEVEL%
)

echo.
:: 5. Create standalone ZIP package wrapped in Parent Folder
echo [5/5] Packaging standalone ZIP release wrapped in parent folder...
set PACK_NAME=JA_IQ5_Flash_v%APP_VERSION%_Windows_x64
if exist "dist_pack" rmdir /s /q "dist_pack"
mkdir "dist_pack\%PACK_NAME%"
xcopy /e /i /y /q "%RELEASE_DIR%\*.*" "dist_pack\%PACK_NAME%\"
powershell -NoProfile -Command "Compress-Archive -Path 'dist_pack\*' -DestinationPath 'dist\%PACK_NAME%.zip' -Force"
if exist "dist_pack" rmdir /s /q "dist_pack"

echo.
echo =======================================================================
echo  BUILD AND PACKAGING COMPLETED SUCCESSFULLY!
echo =======================================================================
echo.
echo Self-contained build directory (unpacked):
echo   %WORKSPACE_DIR%dist\
echo.
echo Standalone parent-folder ZIP package:
echo   %WORKSPACE_DIR%dist\%PACK_NAME%.zip
echo.
echo Quick access shortcut created:
echo   %WORKSPACE_DIR%.Release.lnk
echo.
pause
