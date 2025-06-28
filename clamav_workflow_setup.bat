@echo off
REM ================================
REM ClamAV Enhanced Security Workflow Setup
REM Master Setup Script - June 28, 2025
REM Follows setup_instructions.md exactly
REM ================================

setlocal enabledelayedexpansion

echo ================================
echo ClamAV Enhanced Security Workflow Setup
echo ================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

set "CLAMAV_ROOT=C:\Program Files\ClamAV"
set "SCRIPTS_DIR=%CLAMAV_ROOT%\scripts"
set "QUARANTINE_DIR=%CLAMAV_ROOT%\quarantine"
set "LOGS_DIR=%CLAMAV_ROOT%\logs"
set "BACKUP_DIR=%LOGS_DIR%\removal_backups"

echo Step 1: Creating Directory Structure
echo ====================================

REM Create scripts directory
if not exist "%SCRIPTS_DIR%" (
    mkdir "%SCRIPTS_DIR%"
    echo ✓ Created: %SCRIPTS_DIR%
) else (
    echo ✓ Exists: %SCRIPTS_DIR%
)

REM Create quarantine directory
if not exist "%QUARANTINE_DIR%" (
    mkdir "%QUARANTINE_DIR%"
    echo ✓ Created: %QUARANTINE_DIR%
) else (
    echo ✓ Exists: %QUARANTINE_DIR%
)

REM Create logs directory
if not exist "%LOGS_DIR%" (
    mkdir "%LOGS_DIR%"
    echo ✓ Created: %LOGS_DIR%
) else (
    echo ✓ Exists: %LOGS_DIR%
)

REM Create removal backups directory
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
    echo ✓ Created: %BACKUP_DIR%
) else (
    echo ✓ Exists: %BACKUP_DIR%
)

echo.
echo Step 2: Setting Directory Permissions
echo =====================================

echo Setting permissions for ClamAV service...

REM Grant ClamAV service write access to logs and quarantine
icacls "%LOGS_DIR%" /grant "NT AUTHORITY\SYSTEM":F /T
if %ERRORLEVEL% EQU 0 (
    echo ✓ Logs directory permissions set
) else (
    echo ✗ Warning: Failed to set logs permissions
)

icacls "%QUARANTINE_DIR%" /grant "NT AUTHORITY\SYSTEM":F /T
if %ERRORLEVEL% EQU 0 (
    echo ✓ Quarantine directory permissions set
) else (
    echo ✗ Warning: Failed to set quarantine permissions
)

icacls "%SCRIPTS_DIR%" /grant "NT AUTHORITY\SYSTEM":R /T
if %ERRORLEVEL% EQU 0 (
    echo ✓ Scripts directory permissions set
) else (
    echo ✗ Warning: Failed to set scripts permissions
)

echo.
echo Step 3: Verifying Configuration Files
echo =====================================

REM Check if clamd.conf has required settings
findstr /i "VirusEvent" "%CLAMAV_ROOT%\clamd.conf" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ clamd.conf has VirusEvent configured
) else (
    echo ✗ Warning: clamd.conf may need VirusEvent configuration
)

findstr /i "Quarantine" "%CLAMAV_ROOT%\clamd.conf" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ clamd.conf has Quarantine configured
) else (
    echo ✗ Warning: clamd.conf may need Quarantine configuration
)

echo.
echo Step 4: Verifying Script Files
echo ==============================

set "REQUIRED_SCRIPTS=virus_handler.bat virustotal_check.ps1 remove_threat.bat update_stats.bat generate_weekly_report.bat"

for %%s in (%REQUIRED_SCRIPTS%) do (
    if exist "%SCRIPTS_DIR%\%%s" (
        echo ✓ Found: %%s
    ) else (
        echo ✗ Missing: %%s
        echo   Please copy %%s to %SCRIPTS_DIR%
    )
)

echo.
echo Step 5: Creating VirusTotal Configuration
echo =========================================

set "VT_CONFIG=%SCRIPTS_DIR%\vt_config.txt"
if not exist "%VT_CONFIG%" (
    echo YOUR_VIRUSTOTAL_API_KEY_HERE > "%VT_CONFIG%"
    echo ✓ Created: %VT_CONFIG%
    echo   Please edit this file and add your VirusTotal API key
    echo   Get free API key from: https://www.virustotal.com/gui/join-us
) else (
    echo ✓ Exists: %VT_CONFIG%
)

echo.
echo Step 6: Testing PowerShell Execution Policy
echo ===========================================

powershell.exe -Command "Get-ExecutionPolicy" | findstr "Restricted" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✗ PowerShell execution policy is Restricted
    echo   Run as Administrator: powershell Set-ExecutionPolicy RemoteSigned
    echo   This is required for VirusTotal integration
) else (
    echo ✓ PowerShell execution policy allows script execution
)

echo.
echo Step 7: Creating Test Files
echo ===========================

echo Creating EICAR test file...
echo X5O!P%%@AP[4\PZX54(P^^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H* > "%TEMP%\eicar_test.txt"
echo ✓ EICAR test file created at: %TEMP%\eicar_test.txt

echo.
echo ================================
echo Setup Complete!
echo ================================
echo.
echo Next Steps:
echo 1. Edit %VT_CONFIG% with your VirusTotal API key
echo 2. Ensure all script files are in %SCRIPTS_DIR%
echo 3. Run test: clamscan "%TEMP%\eicar_test.txt"
echo 4. Check logs in %LOGS_DIR%
echo.
echo The enhanced ClamAV security workflow is now ready!
echo See setup_instructions.md for detailed information.
echo.
pause 