@echo off
REM ClamAV Virus Alert Script
REM Called when viruses are detected during scans

setlocal enabledelayedexpansion
set SCAN_LOG=%1
set TIMESTAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
set TIMESTAMP=!TIMESTAMP: =0!

set CLAMAV_PATH=C:\Program Files\ClamAV
set LOG_PATH=%CLAMAV_PATH%\logs
set ALERT_LOG=%LOG_PATH%\virus_alerts.log

echo ========================================== >> %ALERT_LOG%
echo VIRUS ALERT - %date% %time% >> %ALERT_LOG%
echo ========================================== >> %ALERT_LOG%
echo Scan log: %SCAN_LOG% >> %ALERT_LOG%

REM Extract infected files from scan log
echo Infected files found: >> %ALERT_LOG%
findstr /i "FOUND" "%SCAN_LOG%" >> %ALERT_LOG%
echo. >> %ALERT_LOG%

REM Create Windows notification
powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $notify = New-Object System.Windows.Forms.NotifyIcon; $notify.Icon = [System.Drawing.SystemIcons]::Warning; $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning; $notify.BalloonTipText = 'ClamAV has detected malware on your system. Check the logs for details.'; $notify.BalloonTipTitle = 'ClamAV Virus Alert'; $notify.Visible = $true; $notify.ShowBalloonTip(10000); Start-Sleep -Seconds 10; $notify.Dispose()}"

REM Optional: Play system alert sound
powershell -c "(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Critical Stop.wav').PlaySync();"

echo Alert notifications sent >> %ALERT_LOG%
echo ========================================== >> %ALERT_LOG%

REM Optional: Auto-quarantine infected files (uncomment to enable)
mkdir "C:\ClamAV_Quarantine" 2>nul
for /f "tokens=1 delims=:" %%a in ('findstr /i "FOUND" "%SCAN_LOG%"') do (
    if exist "%%a" (
         echo Moving %%a to quarantine >> %ALERT_LOG%
         move "%%a" "C:\ClamAV_Quarantine\" >> %ALERT_LOG%
     )
 )

echo Check %ALERT_LOG% for details
echo Review scan log: %SCAN_LOG%

endlocal