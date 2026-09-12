@echo off
title JA IQ5 Reflash - Debug Mode
cd /d %~dp0

:: 1. If running inside the Release/dist folder where the .exe sits directly:
for %%i in (*.exe) do (
    start "" "%%i" --debug -debug
    exit /b 0
)

:: 2. If running with --flutter flag, force Flutter CLI debug mode
if "%1"=="--flutter" goto run_flutter
if "%1"=="-f" goto run_flutter

:: 3. If running from workspace root, check existing compiled binaries:
if exist "build\windows\x64\runner\Debug\ja_iq5_flash.exe" (
    echo [DEBUG] Launching Debug build binary with --debug...
    start "" "build\windows\x64\runner\Debug\ja_iq5_flash.exe" --debug -debug
    exit /b 0
)

if exist "build\windows\x64\runner\Release\ja_iq5_flash.exe" (
    echo [DEBUG] Launching Release build binary with --debug...
    start "" "build\windows\x64\runner\Release\ja_iq5_flash.exe" --debug -debug
    exit /b 0
)

if exist "dist\ja_iq5_flash.exe" (
    echo [DEBUG] Launching dist binary with --debug...
    start "" "dist\ja_iq5_flash.exe" --debug -debug
    exit /b 0
)

if exist "dist\JA_IQ5_Flash\ja_iq5_flash.exe" (
    echo [DEBUG] Launching dist binary with --debug...
    start "" "dist\JA_IQ5_Flash\ja_iq5_flash.exe" --debug -debug
    exit /b 0
)

:run_flutter
:: 4. Fallback: Launch Flutter CLI in Windows debug mode
echo [DEBUG] Launching Flutter app in Windows debug mode (--debug)...
call flutter run -d windows --debug
