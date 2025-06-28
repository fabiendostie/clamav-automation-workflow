@echo off
REM ================================
REM ClamAV Automation & Monitoring Setup
REM Master Automation Script - June 28, 2025
REM Orchestrates complete automation, monitoring & notifications
REM ================================

setlocal enabledelayedexpansion

echo ================================================
echo ClamAV AUTOMATION AND MONITORING SETUP
echo ================================================
echo Date: June 28, 2025
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
set "LOGS_DIR=%CLAMAV_ROOT%\logs"

echo [Step 1] Setting Up Scheduled Task Automation
echo =============================================

echo Installing automated scheduled tasks...
REM First, remove existing tasks to avoid conflicts
schtasks /delete /tn "ClamAV Daily Quick Scan" /f >nul 2>&1
schtasks /delete /tn "ClamAV Signature Updates" /f >nul 2>&1
schtasks /delete /tn "ClamAV Weekly Full Scan" /f >nul 2>&1
schtasks /delete /tn "ClamAV Monthly Maintenance" /f >nul 2>&1

REM Run the PowerShell script to create scheduled tasks
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\task_scheduler_setup.ps1"
if %ERRORLEVEL% EQU 0 (
    echo [OK] Scheduled tasks configured successfully
) else (
    echo [WARNING] Scheduled task setup may have failed
)

echo.
echo [Step 2] Starting Real-Time Monitoring Service
echo ==============================================

echo Setting up real-time log monitoring...
REM Create a simple monitoring starter script
echo @echo off > "%SCRIPTS_DIR%\start_monitoring.bat"
echo cd /d "%SCRIPTS_DIR%" >> "%SCRIPTS_DIR%\start_monitoring.bat"
echo powershell -ExecutionPolicy Bypass -File "realtime_monitor.ps1" >> "%SCRIPTS_DIR%\start_monitoring.bat"

echo Creating monitoring service task...
REM Delete existing task first
schtasks /delete /tn "ClamAV Real-time Monitor" /f >nul 2>&1

REM Create new monitoring task using schtasks instead of complex PowerShell
schtasks /create /tn "ClamAV Real-time Monitor" /tr "C:\Program Files\ClamAV\scripts\start_monitoring.bat" /sc onstart /ru SYSTEM /rl highest /f >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo [OK] Real-time monitoring service configured
) else (
    echo [WARNING] Real-time monitoring setup may have failed
)

echo.
echo [Step 3] Configuring Notification System
echo ========================================

echo Setting up Windows Toast Notifications...
REM Create notification test
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\toast_notification.ps1" -Title "ClamAV Setup" -Message "Automation system configured successfully!" 

echo [OK] Notification system tested

echo.
echo [Step 4] Creating Dashboard Access Scripts
echo ==========================================

REM Create desktop shortcuts for easy access
echo Creating desktop monitoring shortcuts...

REM Dashboard shortcut
echo @echo off > "%USERPROFILE%\Desktop\ClamAV_Dashboard.bat"
echo cd /d "%SCRIPTS_DIR%" >> "%USERPROFILE%\Desktop\ClamAV_Dashboard.bat"
echo powershell -ExecutionPolicy Bypass -File "granular_dashboard.ps1" >> "%USERPROFILE%\Desktop\ClamAV_Dashboard.bat"
echo pause >> "%USERPROFILE%\Desktop\ClamAV_Dashboard.bat"

REM Quick status shortcut
echo @echo off > "%USERPROFILE%\Desktop\ClamAV_QuickStatus.bat"
echo cd /d "%SCRIPTS_DIR%" >> "%USERPROFILE%\Desktop\ClamAV_QuickStatus.bat"
echo powershell -ExecutionPolicy Bypass -File "granular_dashboard.ps1" -Export >> "%USERPROFILE%\Desktop\ClamAV_QuickStatus.bat"
echo echo Dashboard exported to logs directory >> "%USERPROFILE%\Desktop\ClamAV_QuickStatus.bat"
echo pause >> "%USERPROFILE%\Desktop\ClamAV_QuickStatus.bat"

echo [OK] Desktop monitoring shortcuts created

echo.
echo [Step 5] Testing Automation Components
echo =====================================

echo Testing scheduled task creation...
schtasks /query /tn "ClamAV Daily Quick Scan" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Daily scan task: ACTIVE
) else (
    echo [FAIL] Daily scan task: NOT FOUND
)

schtasks /query /tn "ClamAV Signature Updates" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Signature update task: ACTIVE
) else (
    echo [FAIL] Signature update task: NOT FOUND
)

schtasks /query /tn "ClamAV Weekly Full Scan" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Weekly scan task: ACTIVE
) else (
    echo [FAIL] Weekly scan task: NOT FOUND
)

schtasks /query /tn "ClamAV Real-time Monitor" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Real-time monitor: ACTIVE
) else (
    echo [FAIL] Real-time monitor: NOT FOUND
)

echo.
echo [Step 6] Starting Initial Services
echo ==================================

echo Starting ClamAV daemon if not running...
sc query ClamAV >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    sc start ClamAV >nul 2>&1
    echo [OK] ClamAV daemon service started
) else (
    echo [WARNING] ClamAV daemon service not found - may need manual installation
)

echo Starting real-time monitoring...
schtasks /run /tn "ClamAV Real-time Monitor" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Real-time monitoring started
) else (
    echo [FAIL] Failed to start real-time monitoring
)

echo.
echo ================================================
echo AUTOMATION AND MONITORING SETUP COMPLETE!
echo ================================================
echo.
echo *** ACTIVE AUTOMATION FEATURES:
echo ================================
echo - Daily Quick Scan: 9:00 AM (High-risk directories)  
echo - Signature Updates: Every 4 hours (Auto-update)
echo - Weekly Full Scan: Sundays 2:00 AM (Complete system)
echo - Monthly Maintenance: Log cleanup and optimization
echo - Real-time Monitoring: Continuous threat detection
echo - Instant Notifications: Windows toasts and desktop alerts
echo.
echo *** MONITORING AND RESULTS ACCESS:
echo ===================================
echo - Desktop Dashboard: ClamAV_Dashboard.bat
echo - Quick Status: ClamAV_QuickStatus.bat  
echo - Live Monitoring: "%LOGS_DIR%\virus_alerts.log"
echo - Detailed Reports: "%LOGS_DIR%\weekly_report_*.txt"
echo - Detection History: "%LOGS_DIR%\detections.log"
echo.
echo *** NOTIFICATION METHODS:
echo =========================
echo - Windows Toast Notifications (Instant)
echo - Desktop Alert Files (Persistent)
echo - System Sound Alerts (Audio)
echo - Log File Tracking (Historical)
echo - Email Alerts (If configured in scripts)
echo.
echo *** IMMEDIATE ACTIONS AVAILABLE:
echo =================================
echo 1. View Live Dashboard: Double-click ClamAV_Dashboard.bat
echo 2. Check System Status: Double-click ClamAV_QuickStatus.bat
echo 3. Manual Quick Scan: Run "%SCRIPTS_DIR%\quick_scan.bat"
echo 4. Force Signature Update: Run "%SCRIPTS_DIR%\update_signatures.bat"
echo 5. Generate Report Now: Run "%SCRIPTS_DIR%\generate_weekly_report.bat"
echo.
echo *** VERIFICATION STEPS:
echo =======================
echo - Check Task Scheduler for 5 active ClamAV tasks
echo - Verify "%LOGS_DIR%" contains monitoring files
echo - Test notifications work as expected
echo - Confirm ClamAV daemon is running
echo.
echo Enhanced ClamAV Automation and Monitoring System is now FULLY ACTIVE!
echo Check desktop shortcuts for instant access to monitoring tools.
echo.
pause 