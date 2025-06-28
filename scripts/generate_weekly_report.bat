@echo off
REM ================================
REM Weekly Detection Report Generator
REM File: C:\Program Files\ClamAV\scripts\generate_weekly_report.bat
REM Args: %1 = current timestamp
REM ================================

setlocal enabledelayedexpansion

set "TIMESTAMP=%~1"
set "LOG_DIR=C:\Program Files\ClamAV\logs"
set "TRENDS_FILE=%LOG_DIR%\detection_trends.csv"
set "REPORT_FILE=%LOG_DIR%\weekly_report_%TIMESTAMP:~0,10%.txt"

echo ================================ > "%REPORT_FILE%"
echo ClamAV Weekly Security Report >> "%REPORT_FILE%"
echo Generated: %TIMESTAMP% >> "%REPORT_FILE%"
echo ================================ >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

REM ================================
REM Summary Statistics
REM ================================
echo === WEEKLY SUMMARY === >> "%REPORT_FILE%"

REM Count total detections this week
set "WEEK_COUNT=0"
if exist "%TRENDS_FILE%" (
    for /f %%i in ('powershell.exe -Command "& { $trends = Import-Csv '%TRENDS_FILE%'; ($trends | Where-Object { [DateTime]::ParseExact($_.Date, 'yyyy-MM-dd', $null) -gt (Get-Date).AddDays(-7) }).Count }"') do set "WEEK_COUNT=%%i"
)

echo Total detections this week: !WEEK_COUNT! >> "%REPORT_FILE%"

REM ================================
REM Top Threat Categories
REM ================================
echo. >> "%REPORT_FILE%"
echo === TOP THREAT CATEGORIES === >> "%REPORT_FILE%"

powershell.exe -ExecutionPolicy Bypass -Command "& { try { $trends = Import-Csv '%TRENDS_FILE%'; $last7days = $trends | Where-Object { [DateTime]::ParseExact($_.Date, 'yyyy-MM-dd', $null) -gt (Get-Date).AddDays(-7) }; $categories = $last7days | Group-Object Category | Sort-Object Count -Descending; $categories | ForEach-Object { \"$($_.Name): $($_.Count) detections\" } } catch { 'No trend data available' } }" >> "%REPORT_FILE%"

REM ================================
REM Detection Timeline
REM ================================
echo. >> "%REPORT_FILE%"
echo === DAILY BREAKDOWN === >> "%REPORT_FILE%"

powershell.exe -ExecutionPolicy Bypass -Command "& { try { $trends = Import-Csv '%TRENDS_FILE%'; $last7days = $trends | Where-Object { [DateTime]::ParseExact($_.Date, 'yyyy-MM-dd', $null) -gt (Get-Date).AddDays(-7) }; $daily = $last7days | Group-Object Date | Sort-Object Name; $daily | ForEach-Object { \"$($_.Name): $($_.Count) detections\" } } catch { 'No daily data available' } }" >> "%REPORT_FILE%"

REM ================================
REM Recommendations
REM ================================
echo. >> "%REPORT_FILE%"
echo === RECOMMENDATIONS === >> "%REPORT_FILE%"

if !WEEK_COUNT! EQU 0 (
    echo - No threats detected this week. System appears clean. >> "%REPORT_FILE%"
    echo - Consider running a full system scan if not done recently. >> "%REPORT_FILE%"
) else if !WEEK_COUNT! LSS 3 (
    echo - Low threat activity detected. Current protection appears effective. >> "%REPORT_FILE%"
    echo - Continue regular scanning schedule. >> "%REPORT_FILE%"
) else if !WEEK_COUNT! LSS 10 (
    echo - Moderate threat activity. Monitor for patterns. >> "%REPORT_FILE%"
    echo - Review excluded paths if many false positives detected. >> "%REPORT_FILE%"
) else (
    echo - High threat activity detected this week! >> "%REPORT_FILE%"
    echo - RECOMMENDED: Review security practices and scan frequency. >> "%REPORT_FILE%"
    echo - RECOMMENDED: Check for compromised systems or unsafe browsing. >> "%REPORT_FILE%"
)

REM ================================
REM System Health Check
REM ================================
echo. >> "%REPORT_FILE%"
echo === SYSTEM HEALTH === >> "%REPORT_FILE%"

REM Check database age
for /f "tokens=1,2" %%a in ('dir "C:\Program Files\ClamAV\database\*.cvd" /tc 2^>nul ^| findstr "/"') do (
    echo Database last updated: %%a %%b >> "%REPORT_FILE%"
    goto :db_found
)
:db_found

REM Check log file sizes
for %%f in ("%LOG_DIR%\*.log") do (
    for %%s in ("%%f") do (
        set "SIZE=%%~zs"
        set /a SIZE_MB=!SIZE!/1024/1024
        if !SIZE_MB! GTR 50 (
            echo WARNING: Large log file detected: %%~nxf (!SIZE_MB!MB) >> "%REPORT_FILE%"
        )
    )
)

REM Check quarantine directory
set "QUARANTINE_COUNT=0"
for %%f in ("C:\Program Files\ClamAV\quarantine\*.*") do set /a QUARANTINE_COUNT+=1
echo Files in quarantine: !QUARANTINE_COUNT! >> "%REPORT_FILE%"

if !QUARANTINE_COUNT! GTR 20 (
    echo WARNING: Many files in quarantine. Review and clean up old threats. >> "%REPORT_FILE%"
)

REM ================================
REM Signature Effectiveness
REM ================================
echo. >> "%REPORT_FILE%"
echo === SIGNATURE EFFECTIVENESS === >> "%REPORT_FILE%"

REM Find most common detections
powershell.exe -ExecutionPolicy Bypass -Command "& { try { $trends = Import-Csv '%TRENDS_FILE%'; $last30days = $trends | Where-Object { [DateTime]::ParseExact($_.Date, 'yyyy-MM-dd', $null) -gt (Get-Date).AddDays(-30) }; $common = $last30days | Group-Object VirusName | Sort-Object Count -Descending | Select-Object -First 5; if ($common) { 'Most frequent detections (last 30 days):'; $common | ForEach-Object { \"$($_.Name): $($_.Count) times\" } } else { 'No frequent patterns detected.' } } catch { 'Unable to analyze signature effectiveness.' } }" >> "%REPORT_FILE%"

echo. >> "%REPORT_FILE%"
echo === END OF REPORT === >> "%REPORT_FILE%"
echo Report saved to: %REPORT_FILE% >> "%REPORT_FILE%"

REM ================================
REM Email or notification (optional)
REM ================================
REM Uncomment the following lines to email the report
REM powershell.exe -Command "Send-MailMessage -To 'admin@company.com' -From 'clamav@server.com' -Subject 'ClamAV Weekly Report' -Body (Get-Content '%REPORT_FILE%' | Out-String) -SmtpServer 'smtp.company.com'"

echo Weekly report generated: %REPORT_FILE%
echo Review the report for security insights and recommendations.

endlocal