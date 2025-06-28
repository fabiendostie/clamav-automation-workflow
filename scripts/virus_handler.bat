@echo off
REM ================================
REM ClamAV Virus Handler Script
REM File: C:\Program Files\ClamAV\scripts\virus_handler.bat
REM Args: %1 = virus name, %2 = file path
REM ================================

setlocal enabledelayedexpansion

REM Get parameters
set "VIRUS_NAME=%~1"
set "FILE_PATH=%~2"
set "TIMESTAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "TIMESTAMP=!TIMESTAMP: =0!"

REM Log paths
set "LOG_DIR=C:\Program Files\ClamAV\logs"
set "DETECTION_LOG=%LOG_DIR%\detections.log"
set "QUARANTINE_DIR=C:\Program Files\ClamAV\quarantine"
set "SCRIPTS_DIR=C:\Program Files\ClamAV\scripts"

REM ================================
REM STEP 1: Log the detection
REM ================================
echo [%TIMESTAMP%] DETECTION: %VIRUS_NAME% found in %FILE_PATH% >> "%DETECTION_LOG%"
echo Detection logged: %VIRUS_NAME% in %FILE_PATH%

REM ================================
REM STEP 2: File already quarantined by ClamAV (MoveInfected=yes)
REM Let's verify and log quarantine status
REM ================================
set "QUARANTINED_FILE=%QUARANTINE_DIR%\%~nx2"
if exist "%QUARANTINED_FILE%" (
    echo [%TIMESTAMP%] QUARANTINED: %FILE_PATH% moved to quarantine >> "%DETECTION_LOG%"
    echo File quarantined successfully
) else (
    echo [%TIMESTAMP%] WARNING: Quarantine failed for %FILE_PATH% >> "%DETECTION_LOG%"
    echo WARNING: Quarantine may have failed
)

REM ================================
REM STEP 3: VirusTotal Verification
REM ================================
echo Verifying with VirusTotal...
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\virustotal_check.ps1" "%FILE_PATH%" "%VIRUS_NAME%" "%TIMESTAMP%"

REM Check PowerShell exit code
if %ERRORLEVEL% EQU 1 (
    echo [%TIMESTAMP%] VIRUSTOTAL: Confirmed malicious - %FILE_PATH% >> "%DETECTION_LOG%"
    echo VirusTotal: CONFIRMED MALICIOUS
    
    REM ================================
    REM STEP 4: Permanent removal for confirmed threats
    REM ================================
    call "%SCRIPTS_DIR%\remove_threat.bat" "%QUARANTINED_FILE%" "%VIRUS_NAME%" "%TIMESTAMP%"
    
) else if %ERRORLEVEL% EQU 2 (
    echo [%TIMESTAMP%] VIRUSTOTAL: Likely false positive - %FILE_PATH% >> "%DETECTION_LOG%"
    echo VirusTotal: LIKELY FALSE POSITIVE - Review manually
    
) else (
    echo [%TIMESTAMP%] VIRUSTOTAL: Check failed or inconclusive - %FILE_PATH% >> "%DETECTION_LOG%"
    echo VirusTotal: CHECK FAILED - Manual review required
)

REM ================================
REM STEP 5: Update scan statistics
REM ================================
call "%SCRIPTS_DIR%\update_stats.bat" "%VIRUS_NAME%" "%TIMESTAMP%"

echo ================================
echo Virus handling completed: %VIRUS_NAME%
echo Check %DETECTION_LOG% for details
echo ================================

endlocal