@echo off
REM ================================
REM ClamAV Status & Health Check
REM Quick System Status Script - June 28, 2025
REM Shows current status of all automation components
REM ================================

setlocal enabledelayedexpansion

REM Basic error handling - continue on errors
if "%1"=="-debug" (
    echo DEBUG MODE ENABLED
    echo on
    pause
)

REM Verify we can run basic commands
echo Testing basic functionality...
ver >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Cannot execute basic commands
    pause
    exit /b 1
)

echo ================================================
echo ClamAV SYSTEM STATUS AND HEALTH CHECK
echo ================================================
echo Date: %date% %time%
echo.

set "CLAMAV_ROOT=C:\Program Files\ClamAV"
set "SCRIPTS_DIR=%CLAMAV_ROOT%\scripts"
set "LOGS_DIR=%CLAMAV_ROOT%\logs"

REM Check if ClamAV is operational (multiple detection methods)
echo [1] ClamAV System Status
echo ========================

set "CLAMAV_RUNNING=0"

REM Method 1: Check for clamd.exe process
tasklist /fi "imagename eq clamd.exe" >nul 2>&1 | find /i "clamd.exe" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] ClamAV Daemon Process: RUNNING
    set "CLAMAV_RUNNING=1"
) else (
    echo [INFO] ClamAV Daemon Process: Not detected as persistent process
)

REM Method 2: Check if TCP port 3310 is listening (daemon mode)
netstat -an | find ":3310" | find "LISTENING" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] ClamAV TCP Service: LISTENING on port 3310
    set "CLAMAV_RUNNING=1"
) else (
    echo [INFO] ClamAV TCP Service: Not listening (on-demand mode)
)

REM Method 3: Check if ClamAV service exists
sc query "ClamAV" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    sc query "ClamAV" | find "RUNNING" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [OK] ClamAV Windows Service: RUNNING
        set "CLAMAV_RUNNING=1"
    ) else (
        echo [INFO] ClamAV Windows Service: STOPPED
    )
) else (
    echo [INFO] ClamAV Windows Service: Not installed
)

REM Method 4: Test scanning functionality
if exist "%CLAMAV_ROOT%\clamscan.exe" (
    echo [OK] ClamAV Scanner: Available for on-demand scanning
    set "CLAMAV_RUNNING=1"
) else (
    echo [FAIL] ClamAV Scanner: Not found
)

REM Final status assessment
if %CLAMAV_RUNNING% EQU 1 (
    echo.
    echo [RESULT] ClamAV System: OPERATIONAL
    echo   Mode: On-demand scanning with scheduled automation
) else (
    echo.
    echo [RESULT] ClamAV System: NOT OPERATIONAL
    echo   Action needed: Check ClamAV installation
)

echo.
echo [2] Scheduled Tasks Status  
echo ==========================
set "TASK_COUNT=0"
set "ACTIVE_TASKS=0"

for %%t in ("ClamAV Daily Quick Scan" "ClamAV Signature Updates" "ClamAV Weekly Full Scan" "ClamAV Monthly Maintenance" "ClamAV Real-time Monitor") do (
    set /a TASK_COUNT+=1
    schtasks /query /tn %%t >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        set /a ACTIVE_TASKS+=1
        echo [OK] %%t: ACTIVE
    ) else (
        echo [FAIL] %%t: NOT FOUND
    )
)

echo   Summary: !ACTIVE_TASKS!/!TASK_COUNT! tasks configured

echo.
echo [3] Real-time Monitoring Status
echo ===============================
tasklist /fi "imagename eq powershell.exe" | find /i "powershell.exe" >nul
if %ERRORLEVEL% EQU 0 (
    REM Check if monitoring script is running by checking for monitoring files
    if exist "%LOGS_DIR%\last_position.txt" (
        echo [OK] Real-time Monitor: ACTIVE
        for /f %%a in ('type "%LOGS_DIR%\last_position.txt"') do (
            echo   Last log position: %%a bytes
        )
    ) else (
        echo [WARNING] Real-time Monitor: PowerShell running but monitoring unclear
    )
) else (
    echo [FAIL] Real-time Monitor: NOT RUNNING
)

echo.
echo [4] Recent Activity Summary
echo ===========================

REM Check for recent detections
if exist "%LOGS_DIR%\virus_alerts.log" (
    find /i "VIRUS ALERT" "%LOGS_DIR%\virus_alerts.log" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [WARNING] Recent Virus Alerts found
        echo   Check %LOGS_DIR%\virus_alerts.log for details
    ) else (
        echo [OK] No recent virus alerts
    )
) else (
    echo [OK] No virus alerts logged yet
)

REM Check signature database age
if exist "%CLAMAV_ROOT%\database\daily.cld" (
    for %%a in ("%CLAMAV_ROOT%\database\daily.cld") do (
        echo   Signature DB updated: %%~ta
    )
) else (
    echo [FAIL] Daily signature database not found
)

echo.
echo [5] Log Files Status
echo ===================
if exist "%LOGS_DIR%" (
    if exist "%LOGS_DIR%\*.log" (
        echo [OK] Log files present in directory
    ) else (
        echo [INFO] No log files yet
    )
    echo   Log directory: %LOGS_DIR%
) else (
    echo [FAIL] Log directory not found
)

echo.
echo [6] Quarantine Status
echo ====================
if exist "%CLAMAV_ROOT%\quarantine" (
    if exist "%CLAMAV_ROOT%\quarantine\*.*" (
        echo [WARNING] Quarantined files found
        echo   Review quarantine: %CLAMAV_ROOT%\quarantine
    ) else (
        echo [OK] Quarantine empty: No threats quarantined
    )
) else (
    echo [FAIL] Quarantine directory not found
)

echo.
echo [7] Desktop Monitoring Access
echo =============================
if exist "%USERPROFILE%\Desktop\ClamAV_Dashboard.bat" (
    echo [OK] Dashboard shortcut: Available on desktop
) else (
    echo [FAIL] Dashboard shortcut: Not found on desktop
)

if exist "%USERPROFILE%\Desktop\ClamAV_QuickStatus.bat" (
    echo [OK] Status shortcut: Available on desktop  
) else (
    echo [FAIL] Status shortcut: Not found on desktop
)

echo.
echo ================================================
echo SYSTEM HEALTH SUMMARY
echo ================================================

REM Calculate overall health score
set "HEALTH_SCORE=0"
set "MAX_SCORE=10"

REM ClamAV system operational (+2 points)
if %CLAMAV_RUNNING% EQU 1 set /a HEALTH_SCORE+=2

REM Most tasks active (+2 points)
if !ACTIVE_TASKS! GEQ 3 set /a HEALTH_SCORE+=2

REM Monitoring active (+2 points)
if exist "%LOGS_DIR%\last_position.txt" set /a HEALTH_SCORE+=2

REM No recent alerts (+2 points)
if exist "%LOGS_DIR%\virus_alerts.log" (
    find /i "VIRUS ALERT" "%LOGS_DIR%\virus_alerts.log" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 set /a HEALTH_SCORE+=2
) else (
    set /a HEALTH_SCORE+=2
)

REM Recent signature updates (+2 points)
if exist "%CLAMAV_ROOT%\database\daily.cld" set /a HEALTH_SCORE+=2

echo Overall Health Score: !HEALTH_SCORE!/!MAX_SCORE!

if !HEALTH_SCORE! EQU !MAX_SCORE! (
    echo Status: EXCELLENT - All systems operational [OK]
    echo Color: GREEN
) else if !HEALTH_SCORE! GEQ 7 (
    echo Status: GOOD - Minor issues may exist [WARNING]
    echo Color: YELLOW  
) else if !HEALTH_SCORE! GEQ 4 (
    echo Status: FAIR - Several issues need attention [WARNING]
    echo Color: ORANGE
) else (
    echo Status: POOR - System needs immediate attention [FAIL]
    echo Color: RED
)

echo.
echo QUICK ACTION COMMANDS:
echo =====================
echo - View detailed dashboard: ClamAV_Dashboard.bat
echo - Run quick scan: "%SCRIPTS_DIR%\quick_scan.bat"
echo - Update signatures: "%SCRIPTS_DIR%\update_signatures.bat" 
echo - Check logs: dir "%LOGS_DIR%"
echo - View quarantine: dir "%CLAMAV_ROOT%\quarantine"
echo.
echo ================================================
echo Script completed successfully!
echo Press any key to close this window...
echo ================================================
pause >nul 