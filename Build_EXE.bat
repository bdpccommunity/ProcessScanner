@echo off
title Process Scanner - EXE Builder
color 0A

echo ==========================================
echo   Process Security Scanner - EXE Builder
echo ==========================================
echo.
echo [*] ps2exe install হচ্ছে...
powershell -ExecutionPolicy Bypass -Command "if (-not (Get-Module -ListAvailable -Name ps2exe)) { Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber; Write-Host 'ps2exe installed!' } else { Write-Host 'ps2exe already installed.' }"

echo.
echo [*] EXE তৈরি হচ্ছে...
echo.

powershell -ExecutionPolicy Bypass -Command "Import-Module ps2exe; Invoke-ps2exe -InputFile '%~dp0ProcessScanner.ps1' -OutputFile '%~dp0ProcessScanner.exe' -RequireAdmin -Title 'Process Security Scanner' -Description 'Full C drive Process Security Scanner with VirusTotal'"

echo.
if exist "%~dp0ProcessScanner.exe" (
    echo [OK] সফলভাবে EXE তৈরি হয়েছে!
    echo      File: %~dp0ProcessScanner.exe
) else (
    echo [ERROR] EXE তৈরি হয়নি।
    echo.
    echo PowerShell Admin এ এই commands চালান:
    echo.
    echo   Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
    echo   Import-Module ps2exe
    echo   Invoke-ps2exe -InputFile ProcessScanner.ps1 -OutputFile ProcessScanner.exe -RequireAdmin
)

echo.
pause
