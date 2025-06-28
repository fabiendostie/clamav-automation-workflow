# ClamAV Task Scheduler Setup Script
# Run as Administrator

# Task 1: Daily Quick Scan at 9 AM
$Action1 = New-ScheduledTaskAction -Execute "C:\Program Files\ClamAV\scripts\quick_scan.bat" -WorkingDirectory "C:\Program Files\ClamAV\scripts"
$Trigger1 = New-ScheduledTaskTrigger -Daily -At 9AM
$Principal1 = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings1 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Task1 = New-ScheduledTask -Action $Action1 -Trigger $Trigger1 -Principal $Principal1 -Settings $Settings1 -Description "ClamAV daily quick scan of high-risk directories"
Register-ScheduledTask -TaskName "ClamAV Daily Quick Scan" -InputObject $Task1

# Task 2: Signature Updates Every 4 Hours
$Action2 = New-ScheduledTaskAction -Execute "C:\Program Files\ClamAV\scripts\update_signatures.bat" -WorkingDirectory "C:\Program Files\ClamAV\scripts"
$Trigger2 = New-ScheduledTaskTrigger -Once -At 12AM -RepetitionInterval (New-TimeSpan -Hours 4) -RepetitionDuration (New-TimeSpan -Days 365)
$Principal2 = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings2 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Task2 = New-ScheduledTask -Action $Action2 -Trigger $Trigger2 -Principal $Principal2 -Settings $Settings2 -Description "ClamAV signature database updates every 4 hours"
Register-ScheduledTask -TaskName "ClamAV Signature Updates" -InputObject $Task2

# Task 3: Weekly Full Scan on Sunday at 2 AM
$Action3 = New-ScheduledTaskAction -Execute "C:\Program Files\ClamAV\scripts\weekly_scan.bat" -WorkingDirectory "C:\Program Files\ClamAV\scripts"
$Trigger3 = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At 2AM
$Principal3 = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings3 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Task3 = New-ScheduledTask -Action $Action3 -Trigger $Trigger3 -Principal $Principal3 -Settings $Settings3 -Description "ClamAV weekly comprehensive system scan"
Register-ScheduledTask -TaskName "ClamAV Weekly Full Scan" -InputObject $Task3

# Task 4: Monthly Log Cleanup
$Action4 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Get-ChildItem 'C:\Program Files\ClamAV\logs' -Name '*.log' | Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force`""
$Trigger4 = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At 3AM
$Principal4 = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings4 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Task4 = New-ScheduledTask -Action $Action4 -Trigger $Trigger4 -Principal $Principal4 -Settings $Settings4 -Description "ClamAV monthly log cleanup - removes logs older than 30 days"
Register-ScheduledTask -TaskName "ClamAV Monthly Maintenance" -InputObject $Task4

Write-Host "ClamAV scheduled tasks created successfully!" -ForegroundColor Green
Write-Host "Tasks created:" -ForegroundColor Yellow
Write-Host "  1. ClamAV Daily Quick Scan - Daily at 9:00 AM" -ForegroundColor White
Write-Host "  2. ClamAV Signature Updates - Every 4 hours" -ForegroundColor White  
Write-Host "  3. ClamAV Weekly Full Scan - Sundays at 2:00 AM" -ForegroundColor White
Write-Host "  4. ClamAV Monthly Maintenance - First Monday of month at 3:00 AM" -ForegroundColor White
Write-Host ""
Write-Host "Check Task Scheduler to verify tasks are properly configured." -ForegroundColor Cyan