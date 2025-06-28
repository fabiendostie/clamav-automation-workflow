@echo off
REM Daily Quick Scan Script for ClamAV
REM Scans high-risk directories: Downloads, Desktop, Temp

setlocal enabledelayedexpansion
set TIMESTAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
set TIMESTAMP=!TIMESTAMP: =0!

set CLAMAV_PATH=C:\Program Files\ClamAV
set LOG_PATH=%CLAMAV_PATH%\logs
set SCAN_LOG=%LOG_PATH%\quick_scan_%TIMESTAMP%.log

echo ========================================== >> "%SCAN_LOG%"
echo ClamAV Quick Scan Started: %date% %time% >> "%SCAN_LOG%"
echo ========================================== >> "%SCAN_LOG%"

cd "%CLAMAV_PATH%"

echo Scanning Downloads folder... >> "%SCAN_LOG%"
clamscan.exe --recursive --infected --log="%SCAN_LOG%" "%USERPROFILE%\Downloads"

echo Scanning Desktop folder... >> "%SCAN_LOG%"
clamscan.exe --recursive --infected --log="%SCAN_LOG%" "%USERPROFILE%\Desktop"

echo Scanning Temp directories... >> "%SCAN_LOG%"
clamscan.exe --recursive --infected --log="%SCAN_LOG%" "C:\temp"
clamscan.exe --recursive --infected --log="%SCAN_LOG%" "%TEMP%"

echo Scanning Documents folder... >> "%SCAN_LOG%"
clamscan.exe --recursive --infected --log="%SCAN_LOG%" "%USERPROFILE%\Documents"

echo ========================================== >> "%SCAN_LOG%"
echo ClamAV Quick Scan Completed: %date% %time% >> "%SCAN_LOG%"
echo ========================================== >> "%SCAN_LOG%"

REM Check for infections and alert if found
findstr /i "FOUND" "%SCAN_LOG%" >nul
if %errorlevel%==0 (
    echo VIRUS DETECTED! Check log: "%SCAN_LOG%"
    call "%CLAMAV_PATH%\scripts\virus_alert.bat" "%SCAN_LOG%"
) else (
    echo Quick scan completed successfully - no threats found
)

endlocal