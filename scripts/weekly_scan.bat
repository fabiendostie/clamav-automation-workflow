@echo off
REM Weekly Comprehensive Scan Script for ClamAV
REM Full system scan with detailed logging

setlocal enabledelayedexpansion
set TIMESTAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
set TIMESTAMP=!TIMESTAMP: =0!

set CLAMAV_PATH=C:\Program Files\ClamAV
set LOG_PATH=%CLAMAV_PATH%\logs
set SCAN_LOG=%LOG_PATH%\weekly_scan_%TIMESTAMP%.log

echo ============================================== >> %SCAN_LOG%
echo ClamAV Weekly Full System Scan Started: %date% %time% >> %SCAN_LOG%
echo ============================================== >> %SCAN_LOG%

cd "%CLAMAV_PATH%"

echo Starting comprehensive system scan... >> %SCAN_LOG%
echo This may take several hours depending on system size >> %SCAN_LOG%

REM Scan all drives with comprehensive options
clamscan.exe --recursive --infected --log=%SCAN_LOG% --max-filesize=100M --max-scansize=100M --exclude-dir="C:\Windows\System32" --exclude-dir="C:\Windows\SysWOW64" --exclude-dir="C:\ProgramData\Microsoft\Windows Defender" C:\

REM Scan additional drives if they exist
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%d:\ (
        echo Scanning drive %%d:\ >> %SCAN_LOG%
        clamscan.exe --recursive --infected --log=%SCAN_LOG% --max-filesize=100M --max-scansize=100M %%d:\
    )
)

echo ============================================== >> %SCAN_LOG%
echo ClamAV Weekly Scan Completed: %date% %time% >> %SCAN_LOG%
echo ============================================== >> %SCAN_LOG%

REM Generate scan summary
echo. >> %SCAN_LOG%
echo SCAN SUMMARY: >> %SCAN_LOG%
findstr /i "scanned files\|infected files\|time:" %SCAN_LOG% >> %SCAN_LOG%

REM Check for infections and alert if found
findstr /i "FOUND" %SCAN_LOG% >nul
if %errorlevel%==0 (
    echo VIRUS DETECTED IN WEEKLY SCAN! Check log: %SCAN_LOG%
    call "%CLAMAV_PATH%\scripts\virus_alert.bat" "%SCAN_LOG%"
) else (
    echo Weekly comprehensive scan completed successfully - no threats found
)

endlocal