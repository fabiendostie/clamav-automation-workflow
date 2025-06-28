@echo off
REM ================================
REM Statistics Update Script
REM File: C:\Program Files\ClamAV\scripts\update_stats.bat
REM Args: %1 = virus name, %2 = timestamp
REM ================================

setlocal enabledelayedexpansion

set "VIRUS_NAME=%~1"
set "TIMESTAMP=%~2"
set "LOG_DIR=C:\Program Files\ClamAV\logs"
set "STATS_FILE=%LOG_DIR%\detection_stats.txt"
set "TRENDS_FILE=%LOG_DIR%\detection_trends.csv"

REM ================================
REM Update detection counters
REM ================================

REM Initialize stats file if it doesn't exist
if not exist "%STATS_FILE%" (
    echo # ClamAV Detection Statistics > "%STATS_FILE%"
    echo # Last updated: %TIMESTAMP% >> "%STATS_FILE%"
    echo TOTAL_DETECTIONS=0 >> "%STATS_FILE%"
    echo FALSE_POSITIVES=0 >> "%STATS_FILE%"
    echo CONFIRMED_THREATS=0 >> "%STATS_FILE%"
    echo MANUAL_REVIEWS=0 >> "%STATS_FILE%"
)

REM Read current values
for /f "tokens=1,2 delims==" %%a in ('type "%STATS_FILE%" ^| findstr "="') do (
    set "%%a=%%b"
)

REM Increment total detections
set /a TOTAL_DETECTIONS+=1

REM Update the stats file
(
    echo # ClamAV Detection Statistics
    echo # Last updated: %TIMESTAMP%
    echo TOTAL_DETECTIONS=!TOTAL_DETECTIONS!
    echo FALSE_POSITIVES=!FALSE_POSITIVES!
    echo CONFIRMED_THREATS=!CONFIRMED_THREATS!
    echo MANUAL_REVIEWS=!MANUAL_REVIEWS!
) > "%STATS_FILE%"

REM ================================
REM Log to trends CSV for analysis
REM ================================

REM Initialize trends file if it doesn't exist
if not exist "%TRENDS_FILE%" (
    echo Date,Time,VirusName,Category,Action > "%TRENDS_FILE%"
)

REM Extract date and time
set "DATE_PART=%TIMESTAMP:~0,10%"
set "TIME_PART=%TIMESTAMP:~11,8%"

REM Categorize the virus for trend analysis
set "CATEGORY=Unknown"
echo %VIRUS_NAME% | findstr /i "trojan" >nul && set "CATEGORY=Trojan"
echo %VIRUS_NAME% | findstr /i "adware" >nul && set "CATEGORY=Adware"
echo %VIRUS_NAME% | findstr /i "pup\|potentially" >nul && set "CATEGORY=PUP"
echo %VIRUS_NAME% | findstr /i "virus" >nul && set "CATEGORY=Virus"
echo %VIRUS_NAME% | findstr /i "worm" >nul && set "CATEGORY=Worm"
echo %VIRUS_NAME% | findstr /i "ransomware" >nul && set "CATEGORY=Ransomware"
echo %VIRUS_NAME% | findstr /i "backdoor" >nul && set "CATEGORY=Backdoor"
echo %VIRUS_NAME% | findstr /i "rootkit" >nul && set "CATEGORY=Rootkit"

REM Log the detection
echo %DATE_PART%,%TIME_PART%,"%VIRUS_NAME%",%CATEGORY%,Detected >> "%TRENDS_FILE%"

REM ================================
REM Generate weekly summary (if it's Sunday)
REM ================================
for /f "tokens=1" %%a in ('wmic path win32_localtime get dayofweek /value ^| findstr "="') do set %%a
if %DayOfWeek% EQU 0 (
    call "%~dp0generate_weekly_report.bat" "%TIMESTAMP%"
)

REM ================================
REM Update signature effectiveness tracking
REM ================================
set "SIG_STATS=%LOG_DIR%\signature_stats.txt"

REM Track which signatures are most effective
echo %TIMESTAMP%: %VIRUS_NAME% >> "%SIG_STATS%"

REM ================================
REM Check for patterns that might need exclusions
REM ================================
set "PATTERN_LOG=%LOG_DIR%\pattern_analysis.log"

REM Count recent detections of this same virus
set "RECENT_COUNT=0"
for /f %%i in ('findstr /c:"%VIRUS_NAME%" "%TRENDS_FILE%" 2^>nul') do set "RECENT_COUNT=%%i"

if !RECENT_COUNT! GEQ 5 (
    echo [%TIMESTAMP%] PATTERN: %VIRUS_NAME% detected !RECENT_COUNT! times - review for false positive >> "%PATTERN_LOG%"
)

REM ================================
REM Optimize scan exclusions based on patterns
REM ================================
powershell.exe -ExecutionPolicy Bypass -Command "& { $trends = Import-Csv '%TRENDS_FILE%'; $last7days = $trends | Where-Object { [DateTime]::ParseExact($_.Date, 'yyyy-MM-dd', $null) -gt (Get-Date).AddDays(-7) }; $commonPaths = $last7days | Group-Object Category | Sort-Object Count -Descending | Select-Object -First 3; Write-Host 'Top threat categories this week:'; $commonPaths | ForEach-Object { Write-Host \"$($_.Name): $($_.Count) detections\" } }" >> "%LOG_DIR%\weekly_patterns.log" 2>&1

echo Detection statistics updated:
echo - Total detections: !TOTAL_DETECTIONS!
echo - Virus category: %CATEGORY%
echo - Trend data logged to: %TRENDS_FILE%

endlocal