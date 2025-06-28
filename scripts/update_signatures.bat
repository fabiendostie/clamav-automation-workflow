@echo off
REM ClamAV Signature Update Script
REM Updates official ClamAV signature databases

setlocal enabledelayedexpansion
set TIMESTAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
set TIMESTAMP=!TIMESTAMP: =0!

set CLAMAV_PATH=C:\Program Files\ClamAV
set LOG_PATH=%CLAMAV_PATH%\logs
set UPDATE_LOG=%LOG_PATH%\signature_update_%TIMESTAMP%.log

echo ========================================== >> %UPDATE_LOG%
echo ClamAV Signature Update Started: %date% %time% >> %UPDATE_LOG%
echo ========================================== >> %UPDATE_LOG%

cd "%CLAMAV_PATH%"

REM Run freshclam to update signatures
echo Running freshclam to update virus signatures... >> %UPDATE_LOG%
freshclam.exe >> %UPDATE_LOG% 2>&1

REM Check update status
if %errorlevel%==0 (
    echo Signature update completed successfully >> %UPDATE_LOG%
    echo Signature databases are now up to date
) else (
    echo Signature update failed - check network connection >> %UPDATE_LOG%
    echo WARNING: Signature update failed! Check log: %UPDATE_LOG%
)

REM Display current signature count
echo. >> %UPDATE_LOG%
echo Current signature database info: >> %UPDATE_LOG%
sigtool.exe --info="database\main.cvd" >> %UPDATE_LOG% 2>&1
sigtool.exe --info="database\daily.cld" >> %UPDATE_LOG% 2>&1

echo ========================================== >> %UPDATE_LOG%
echo ClamAV Signature Update Completed: %date% %time% >> %UPDATE_LOG%
echo ========================================== >> %UPDATE_LOG%

REM Restart daemon if it was running to reload new signatures
tasklist /fi "imagename eq clamd.exe" 2>nul | find /i "clamd.exe" >nul
if %errorlevel%==0 (
    echo Restarting ClamAV daemon to load new signatures... >> %UPDATE_LOG%
    taskkill /f /im clamd.exe >nul 2>&1
    timeout /t 2 >nul
    start "" "%CLAMAV_PATH%\clamd.exe" --config-file=clamd.conf
    echo Daemon restarted successfully >> %UPDATE_LOG%
)

endlocal