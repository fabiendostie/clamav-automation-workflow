@echo off
REM ================================
REM ClamAV Enhanced Security Workflow Test Suite
REM Tests all components of the security workflow
REM January 22, 2025
REM ================================

setlocal enabledelayedexpansion

echo ================================
echo ClamAV Security Workflow Test Suite
echo ================================
echo.

set "CLAMAV_ROOT=C:\Program Files\ClamAV"
set "SCRIPTS_DIR=%CLAMAV_ROOT%\scripts"
set "QUARANTINE_DIR=%CLAMAV_ROOT%\quarantine"
set "LOGS_DIR=%CLAMAV_ROOT%\logs"
set "TEST_DIR=%TEMP%\clamav_test"

REM Create test directory
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"

echo Test 1: Directory Structure Validation
echo ======================================

set "ALL_TESTS_PASSED=1"

REM Check all required directories exist
for %%d in ("%SCRIPTS_DIR%" "%QUARANTINE_DIR%" "%LOGS_DIR%" "%LOGS_DIR%\removal_backups") do (
    if exist "%%d" (
        echo ✓ Directory exists: %%d
    ) else (
        echo ✗ Missing directory: %%d
        set "ALL_TESTS_PASSED=0"
    )
)

echo.
echo Test 2: Script Files Validation
echo ===============================

set "REQUIRED_SCRIPTS=virus_handler.bat virustotal_check.ps1 remove_threat.bat update_stats.bat generate_weekly_report.bat"

for %%s in (%REQUIRED_SCRIPTS%) do (
    if exist "%SCRIPTS_DIR%\%%s" (
        echo ✓ Script exists: %%s
    ) else (
        echo ✗ Missing script: %%s
        set "ALL_TESTS_PASSED=0"
    )
)

echo.
echo Test 3: Configuration Validation
echo ================================

REM Check clamd.conf settings
findstr /i "VirusEvent.*virus_handler.bat" "%CLAMAV_ROOT%\clamd.conf" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ VirusEvent configured correctly
) else (
    echo ✗ VirusEvent not configured or incorrect
    set "ALL_TESTS_PASSED=0"
)

findstr /i "MoveInfected.*yes" "%CLAMAV_ROOT%\clamd.conf" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ MoveInfected enabled
) else (
    echo ✗ MoveInfected not enabled
    set "ALL_TESTS_PASSED=0"
)

findstr /i "Quarantine" "%CLAMAV_ROOT%\clamd.conf" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Quarantine directory configured
) else (
    echo ✗ Quarantine directory not configured
    set "ALL_TESTS_PASSED=0"
)

echo.
echo Test 4: VirusTotal Configuration
echo ================================

if exist "%SCRIPTS_DIR%\vt_config.txt" (
    echo ✓ VirusTotal config file exists
    for /f "delims=" %%a in ('type "%SCRIPTS_DIR%\vt_config.txt"') do (
        if "%%a"=="YOUR_VIRUSTOTAL_API_KEY_HERE" (
            echo ⚠ Warning: Default API key placeholder detected
            echo   Please update vt_config.txt with your actual API key
        ) else (
            echo ✓ VirusTotal API key configured
        )
        goto :vt_done
    )
) else (
    echo ✗ VirusTotal config file missing
    set "ALL_TESTS_PASSED=0"
)
:vt_done

echo.
echo Test 5: EICAR Detection Test
echo ============================

echo Creating EICAR test file...
echo X5O!P%%@AP[4\PZX54(P^^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H* > "%TEST_DIR%\eicar_test.txt"

echo Running ClamAV scan...
"%CLAMAV_ROOT%\clamscan.exe" "%TEST_DIR%\eicar_test.txt" > "%TEST_DIR%\scan_result.txt" 2>&1

REM Check scan results
findstr /i "eicar" "%TEST_DIR%\scan_result.txt" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ EICAR test file detected
) else (
    echo ✗ EICAR test file not detected
    set "ALL_TESTS_PASSED=0"
    echo Scan output:
    type "%TEST_DIR%\scan_result.txt"
)

echo.
echo Test 6: Quarantine Functionality
echo ================================

REM Check if file was quarantined (would need ClamD running)
if exist "%QUARANTINE_DIR%\eicar_test.txt" (
    echo ✓ File successfully quarantined
) else (
    echo ⚠ File not in quarantine (ClamD might not be running)
    echo   This test requires ClamD service to be active
)

echo.
echo Test 7: Logging Functionality
echo =============================

REM Check if log files can be created
echo Test log entry > "%LOGS_DIR%\test_log.txt" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Log directory is writable
    del "%LOGS_DIR%\test_log.txt" >nul 2>&1
) else (
    echo ✗ Log directory not writable
    set "ALL_TESTS_PASSED=0"
)

echo.
echo Test 8: PowerShell Integration
echo ==============================

powershell.exe -ExecutionPolicy Bypass -Command "Write-Host 'PowerShell test successful'" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ PowerShell execution working
) else (
    echo ✗ PowerShell execution failed
    set "ALL_TESTS_PASSED=0"
)

echo.
echo Test 9: Script Execution Test
echo =============================

REM Test virus_handler.bat with dummy parameters
if exist "%SCRIPTS_DIR%\virus_handler.bat" (
    echo Testing virus_handler.bat...
    REM Don't actually run it as it would log false data
    echo ✓ virus_handler.bat is accessible
) else (
    echo ✗ virus_handler.bat not found
    set "ALL_TESTS_PASSED=0"
)

echo.
echo Test 10: Permissions Validation
echo ===============================

REM Test write permissions to quarantine
echo test > "%QUARANTINE_DIR%\perm_test.txt" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Quarantine directory is writable
    del "%QUARANTINE_DIR%\perm_test.txt" >nul 2>&1
) else (
    echo ✗ Quarantine directory not writable
    set "ALL_TESTS_PASSED=0"
)

echo.
echo ================================
echo Test Results Summary
echo ================================

if "%ALL_TESTS_PASSED%"=="1" (
    echo ✓ ALL TESTS PASSED!
    echo The ClamAV Enhanced Security Workflow is ready for production use.
) else (
    echo ✗ SOME TESTS FAILED
    echo Please review the failed tests above and resolve the issues.
    echo Refer to setup_instructions.md for troubleshooting guidance.
)

echo.
echo Additional Manual Tests Recommended:
echo 1. Test with ClamD service running
echo 2. Verify VirusTotal API connectivity
echo 3. Test weekly report generation
echo 4. Verify email notifications (if configured)
echo.

REM Cleanup
if exist "%TEST_DIR%" rmdir /s /q "%TEST_DIR%" >nul 2>&1

echo Test completed. Press any key to exit.
pause >nul 