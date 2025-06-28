@echo off
REM Comprehensive ClamAV Scanning Script for Windows 11
REM File: C:\Program Files\ClamAV\scripts\automated_scan.bat

setlocal enabledelayedexpansion

set SCAN_LOG=C:\Program Files\ClamAV\logs\scan_results.log
set CLAMAV_PATH=C:\Program Files\ClamAV
set TIMESTAMP=%date% %time%
set THREATS_FOUND=0

echo [%TIMESTAMP%] Starting comprehensive ClamAV scan... >> "%SCAN_LOG%"
echo [%TIMESTAMP%] Starting comprehensive ClamAV scan...

REM Check if ClamAV daemon is running, if not start it
tasklist /FI "IMAGENAME eq clamd.exe" 2>NUL | find /I /N "clamd.exe">NUL
if "%ERRORLEVEL%"=="1" (
    echo [%TIMESTAMP%] Starting ClamAV daemon... >> "%SCAN_LOG%"
    start /b "ClamAV Daemon" "%CLAMAV_PATH%\clamd.exe" --config-file="%CLAMAV_PATH%\clamd.conf"
    timeout /t 10 /nobreak > nul
)

REM Update virus definitions first
echo [%TIMESTAMP%] Updating virus definitions... >> "%SCAN_LOG%"
echo Updating virus definitions...
"%CLAMAV_PATH%\freshclam.exe" --config-file="%CLAMAV_PATH%\freshclam.conf" --log="%SCAN_LOG%"

REM Function to scan directories
goto :SCAN_DIRECTORIES

:SCAN_DIR
set DIR_PATH=%~1
set DIR_DESC=%~2
echo [%TIMESTAMP%] Scanning %DIR_DESC%: %DIR_PATH% >> "%SCAN_LOG%"
echo Scanning %DIR_DESC%: %DIR_PATH%

REM Check if daemon is available, use clamdscan, otherwise use clamscan
tasklist /FI "IMAGENAME eq clamd.exe" 2>NUL | find /I /N "clamd.exe">NUL
if "%ERRORLEVEL%"=="0" (
    "%CLAMAV_PATH%\clamdscan.exe" --recursive --infected --log="%SCAN_LOG%" "%DIR_PATH%"
) else (
    "%CLAMAV_PATH%\clamscan.exe" --recursive --infected --log="%SCAN_LOG%" "%DIR_PATH%"
)

if %ERRORLEVEL% EQU 1 (
    echo [%TIMESTAMP%] %DIR_DESC% scan completed - THREATS FOUND! >> "%SCAN_LOG%"
    set THREATS_FOUND=1
) else if %ERRORLEVEL% EQU 0 (
    echo [%TIMESTAMP%] %DIR_DESC% scan completed - No threats found >> "%SCAN_LOG%"
) else (
    echo [%TIMESTAMP%] %DIR_DESC% scan failed with exit code %ERRORLEVEL% >> "%SCAN_LOG%"
)
goto :eof

:SCAN_DIRECTORIES

REM Scan critical Windows directories
call :SCAN_DIR "C:\Users\%USERNAME%\Downloads" "User Downloads"
call :SCAN_DIR "C:\Users\%USERNAME%\Desktop" "User Desktop"
call :SCAN_DIR "C:\Users\%USERNAME%\Documents" "User Documents"
call :SCAN_DIR "C:\Temp" "Windows Temp"
call :SCAN_DIR "C:\Windows\Temp" "System Temp"

REM Scan development directories (adjust for your setup)
if exist "C:\Users\fabie\dev" (
    call :SCAN_DIR "C:\Users\fabie\dev" "Development Directory"
)

REM Scan common web directories if they exist
if exist "C:\inetpub\wwwroot" (
    call :SCAN_DIR "C:\inetpub\wwwroot" "IIS Web Root"
)

REM Scan email directories if they exist
if exist "C:\Program Files\Microsoft\Exchange Server" (
    call :SCAN_DIR "C:\Program Files\Microsoft\Exchange Server" "Exchange Server"
)

REM Scan additional drives if mounted
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\" (
        echo Checking drive %%d:\
        call :SCAN_DIR "%%d:\" "Drive %%d"
    )
)

REM WSL scanning (if WSL is installed)
if exist "C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState\rootfs\home" (
    call :SCAN_DIR "C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState\rootfs\home" "WSL Home Directory"
)

REM Final report
set TIMESTAMP=%date% %time%
echo [%TIMESTAMP%] Comprehensive scan completed >> "%SCAN_LOG%"
echo Scan completed at %TIMESTAMP%

if %THREATS_FOUND% EQU 1 (
    echo [%TIMESTAMP%] WARNING: THREATS DETECTED! Check log for details. >> "%SCAN_LOG%"
    echo WARNING: THREATS DETECTED! Check %SCAN_LOG% for details.
    
    REM Send Windows notification
    powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $notify = New-Object System.Windows.Forms.NotifyIcon; $notify.Icon = [System.Drawing.SystemIcons]::Error; $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Error; $notify.BalloonTipText = 'Threats detected during scheduled scan! Check logs for details.'; $notify.BalloonTipTitle = 'ClamAV Security Alert'; $notify.Visible = $true; $notify.ShowBalloonTip(10000); Start-Sleep -Seconds 10; $notify.Dispose()}" > nul
    
    REM Optional: Send email notification
    REM powershell -Command "Send-MailMessage -SmtpServer 'your-smtp-server' -From 'clamav@yourdomain.com' -To 'admin@yourdomain.com' -Subject 'ClamAV Security Alert - Threats Detected' -Body 'ClamAV detected threats during scheduled scan. Check %SCAN_LOG% for details.'" > nul 2>&1
    
) else (
    echo [%TIMESTAMP%] No threats detected >> "%SCAN_LOG%"
    echo SUCCESS: No threats detected
)

REM Clean up old logs (keep last 30 days)
forfiles /P "C:\Program Files\ClamAV\logs" /S /M "*.log" /D -30 /C "cmd /c del @path" 2>nul

echo [%TIMESTAMP%] Scan process finished >> "%SCAN_LOG%"
echo Scan process finished
pause