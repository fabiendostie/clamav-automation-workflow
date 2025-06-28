# Clean ClamAV Dashboard
Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                ClamAV STATUS DASHBOARD                        " -ForegroundColor Yellow  
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Daemon Status
$Daemon = Get-Process -Name "clamd" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($Daemon) {
    $MemoryMB = [math]::Round($Daemon.WorkingSet64 / 1024 / 1024, 2)
    Write-Host "DAEMON: RUNNING ($MemoryMB MB)" -ForegroundColor Green
} else {
    Write-Host "DAEMON: STOPPED" -ForegroundColor Red
}

# Signatures
try {
    $MainSigs = (& "C:\Program Files\ClamAV\sigtool.exe" --info="C:\Program Files\ClamAV\database\main.cvd" | Select-String "Signatures:").ToString().Split(":")[1].Trim()
    $DailySigs = (& "C:\Program Files\ClamAV\sigtool.exe" --info="C:\Program Files\ClamAV\database\daily.cld" | Select-String "Signatures:").ToString().Split(":")[1].Trim()
    $Total = [int]$MainSigs + [int]$DailySigs
    Write-Host "SIGNATURES: $Total total ($MainSigs main + $DailySigs daily)" -ForegroundColor Yellow
} catch {
    Write-Host "SIGNATURES: Error reading databases" -ForegroundColor Red
    $Total = 0
}

# Tasks
$TaskCount = 0
$Tasks = @("ClamAV Daily Quick Scan", "ClamAV Signature Updates", "ClamAV Weekly Full Scan")
foreach ($TaskName in $Tasks) {
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($Task -and $Task.State -eq "Ready") { $TaskCount++ }
}
Write-Host "SCHEDULED TASKS: $TaskCount of 3 ready" -ForegroundColor $(if ($TaskCount -eq 3) {"Green"} else {"Yellow"})

# System Info
$RAM = Get-CimInstance -ClassName Win32_ComputerSystem
$OS = Get-CimInstance -ClassName Win32_OperatingSystem  
$TotalGB = [math]::Round($RAM.TotalPhysicalMemory / 1GB, 1)
$FreeGB = [math]::Round($OS.FreePhysicalMemory / 1024 / 1024, 1)
$CPU = (Get-CimInstance -ClassName Win32_Processor).LoadPercentage
Write-Host "SYSTEM: $TotalGB GB RAM ($FreeGB GB free), CPU $CPU%" -ForegroundColor White

# Health Score
$Score = 0
if ($Daemon) { $Score++ }
if ($Total -gt 8000000) { $Score++ }  
if ($TaskCount -eq 3) { $Score++ }
if ((Get-ChildItem "C:\Program Files\ClamAV\logs" -Filter "*.log" -ErrorAction SilentlyContinue).Count -gt 0) { $Score++ }

$Percent = [math]::Round(($Score / 4) * 100)
$Color = if ($Percent -ge 90) {"Green"} elseif ($Percent -ge 70) {"Yellow"} else {"Red"}

Write-Host ""
Write-Host "OVERALL HEALTH: $Score/4 ($Percent%)" -ForegroundColor $Color

# Status Details
Write-Host ""
Write-Host "STATUS DETAILS:" -ForegroundColor Cyan
Write-Host "  Daemon Running: $(if ($Daemon) {"YES"} else {"NO"})" -ForegroundColor $(if ($Daemon) {"Green"} else {"Red"})
Write-Host "  Signatures OK: $(if ($Total -gt 8000000) {"YES"} else {"NO"})" -ForegroundColor $(if ($Total -gt 8000000) {"Green"} else {"Red"})
Write-Host "  Tasks Ready: $(if ($TaskCount -eq 3) {"YES"} else {"NO"})" -ForegroundColor $(if ($TaskCount -eq 3) {"Green"} else {"Red"})
Write-Host "  Logs Present: $(if ((Get-ChildItem "C:\Program Files\ClamAV\logs" -Filter "*.log" -ErrorAction SilentlyContinue).Count -gt 0) {"YES"} else {"NO"})" -ForegroundColor $(if ((Get-ChildItem "C:\Program Files\ClamAV\logs" -Filter "*.log" -ErrorAction SilentlyContinue).Count -gt 0) {"Green"} else {"Red"})

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "ClamAV Enterprise Security: $(if ($Score -eq 4) {"FULLY OPERATIONAL"} elseif ($Score -ge 3) {"MOSTLY OPERATIONAL"} else {"NEEDS ATTENTION"})" -ForegroundColor $Color
Write-Host "================================================================" -ForegroundColor Cyan