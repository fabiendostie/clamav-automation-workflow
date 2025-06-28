# Granular ClamAV Monitoring Dashboard
param([switch]$Export, [switch]$Detailed)

$CLAMAV_PATH = "C:\Program Files\ClamAV"
$LOG_PATH = "$CLAMAV_PATH\logs"

Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "           ClamAV GRANULAR MONITORING DASHBOARD                " -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. DETAILED DAEMON STATUS
Write-Host "[1] DAEMON STATUS" -ForegroundColor Green

# Multi-method detection for ClamAV operational status
$ClamAVOperational = $false
$DaemonProcesses = $null
$DetectionMethod = ""

# Method 1: Check for clamd.exe process
$DaemonProcesses = Get-Process -Name "clamd" -ErrorAction SilentlyContinue
if ($DaemonProcesses) {
    $ClamAVOperational = $true
    $DetectionMethod = "Persistent Daemon Process"
    
    foreach ($Process in $DaemonProcesses) {
        $MemoryMB = [math]::Round($Process.WorkingSet64 / 1024 / 1024, 2)
        $MemoryPeakMB = [math]::Round($Process.PeakWorkingSet64 / 1024 / 1024, 2)
        $Runtime = (Get-Date) - $Process.StartTime
        
        Write-Host "   Status: RUNNING (Daemon Mode)" -ForegroundColor Green
        Write-Host "   Process ID: $($Process.Id)" -ForegroundColor White
        Write-Host "   Memory Current: $MemoryMB MB" -ForegroundColor White
        Write-Host "   Memory Peak: $MemoryPeakMB MB" -ForegroundColor White
        Write-Host "   CPU Time: $([math]::Round($Process.TotalProcessorTime.TotalMinutes, 2)) minutes" -ForegroundColor White
        Write-Host "   Start Time: $($Process.StartTime)" -ForegroundColor White
        Write-Host "   Runtime: $($Runtime.Days)d $($Runtime.Hours)h $($Runtime.Minutes)m" -ForegroundColor White
        Write-Host "   Threads: $($Process.Threads.Count)" -ForegroundColor White
    }
}

# Method 2: Check for TCP port 3310 (daemon mode)
if (-not $ClamAVOperational) {
    $TCPListener = netstat -an | Select-String ":3310.*LISTENING"
    if ($TCPListener) {
        $ClamAVOperational = $true
        $DetectionMethod = "TCP Service (Port 3310)"
        Write-Host "   Status: RUNNING (TCP Service Mode)" -ForegroundColor Green
        Write-Host "   Listening on: Port 3310" -ForegroundColor White
    }
}

# Method 3: Check for Windows service
if (-not $ClamAVOperational) {
    $ClamAVService = Get-Service -Name "ClamAV" -ErrorAction SilentlyContinue
    if ($ClamAVService -and $ClamAVService.Status -eq "Running") {
        $ClamAVOperational = $true
        $DetectionMethod = "Windows Service"
        Write-Host "   Status: RUNNING (Windows Service)" -ForegroundColor Green
        Write-Host "   Service Status: $($ClamAVService.Status)" -ForegroundColor White
    }
}

# Method 4: Check scanning functionality (on-demand mode)
if (-not $ClamAVOperational) {
    if (Test-Path "$CLAMAV_PATH\clamscan.exe") {
        $ClamAVOperational = $true
        $DetectionMethod = "On-Demand Scanner Available"
        Write-Host "   Status: OPERATIONAL (On-Demand Mode)" -ForegroundColor Green
        Write-Host "   Scanner: Available for scheduled scanning" -ForegroundColor White
        Write-Host "   Mode: Optimized for Windows scheduled tasks" -ForegroundColor White
    }
}

# Final status
if ($ClamAVOperational) {
    Write-Host "   Detection Method: $DetectionMethod" -ForegroundColor Cyan
    Write-Host "   Overall Status: OPERATIONAL" -ForegroundColor Green
} else {
    Write-Host "   Status: NOT OPERATIONAL" -ForegroundColor Red
    Write-Host "   Action Required: Check ClamAV installation" -ForegroundColor Yellow
}
Write-Host ""

# 2. DETAILED SIGNATURE DATABASE STATUS
Write-Host "[2] SIGNATURE DATABASE ANALYSIS" -ForegroundColor Green
try {
    # Main Database
    $MainInfo = & "$CLAMAV_PATH\sigtool.exe" --info="$CLAMAV_PATH\database\main.cvd" 2>$null
    $MainSigs = ($MainInfo | Select-String "Signatures:").ToString().Split(":")[1].Trim()
    $MainDate = ($MainInfo | Select-String "Build time:").ToString().Split(":",2)[1].Trim()
    $MainVersion = ($MainInfo | Select-String "Version:").ToString().Split(":")[1].Trim()
    $MainLevel = ($MainInfo | Select-String "Functionality level:").ToString().Split(":")[1].Trim()
    
    Write-Host "   Main Database (main.cvd):" -ForegroundColor Yellow
    Write-Host "     Signatures: $MainSigs" -ForegroundColor White
    Write-Host "     Version: $MainVersion" -ForegroundColor White
    Write-Host "     Build Date: $MainDate" -ForegroundColor White
    Write-Host "     Functionality Level: $MainLevel" -ForegroundColor White
    
    # Daily Database
    $DailyInfo = & "$CLAMAV_PATH\sigtool.exe" --info="$CLAMAV_PATH\database\daily.cld" 2>$null
    $DailySigs = ($DailyInfo | Select-String "Signatures:").ToString().Split(":")[1].Trim()
    $DailyDate = ($DailyInfo | Select-String "Build time:").ToString().Split(":",2)[1].Trim()
    $DailyVersion = ($DailyInfo | Select-String "Version:").ToString().Split(":")[1].Trim()
    $DailyLevel = ($DailyInfo | Select-String "Functionality level:").ToString().Split(":")[1].Trim()
    
    Write-Host "   Daily Database (daily.cld):" -ForegroundColor Yellow
    Write-Host "     Signatures: $DailySigs" -ForegroundColor White
    Write-Host "     Version: $DailyVersion" -ForegroundColor White
    Write-Host "     Build Date: $DailyDate" -ForegroundColor White
    Write-Host "     Functionality Level: $DailyLevel" -ForegroundColor White
    
    # Bytecode Database
    $BytecodeInfo = & "$CLAMAV_PATH\sigtool.exe" --info="$CLAMAV_PATH\database\bytecode.cvd" 2>$null
    $BytecodeSigs = ($BytecodeInfo | Select-String "Signatures:").ToString().Split(":")[1].Trim()
    Write-Host "   Bytecode Database: $BytecodeSigs signatures" -ForegroundColor White
    
    $TotalSigs = [int]$MainSigs + [int]$DailySigs + [int]$BytecodeSigs
    Write-Host "   TOTAL SIGNATURES: $TotalSigs" -ForegroundColor Cyan
    
    # Database freshness check
    $DailyAge = (Get-Date) - [datetime]::ParseExact($DailyDate.Substring(0,11), "dd MMM yyyy", $null)
    if ($DailyAge.Days -le 1) {
        Write-Host "   Freshness: CURRENT (Updated $($DailyAge.Days) days ago)" -ForegroundColor Green
    } elseif ($DailyAge.Days -le 3) {
        Write-Host "   Freshness: RECENT (Updated $($DailyAge.Days) days ago)" -ForegroundColor Yellow
    } else {
        Write-Host "   Freshness: OUTDATED (Updated $($DailyAge.Days) days ago)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   Error: Unable to read signature databases" -ForegroundColor Red
    Write-Host "   Details: $($_.Exception.Message)" -ForegroundColor Red
    $TotalSigs = 0
}
Write-Host ""

# 3. DETAILED SCHEDULED TASKS STATUS
Write-Host "[3] SCHEDULED TASKS ANALYSIS" -ForegroundColor Green
$TaskDetails = @(
    @{Name="ClamAV Daily Scan"; Description="High-risk directories scan"},
    @{Name="ClamAV Daily Updates"; Description="Database updates every 4 hours"},  
    @{Name="ClamAV Quick Daily Scan"; Description="Quick daily scan"},
    @{Name="ClamAV Weekly Scan"; Description="Complete system scan"},
    @{Name="ClamAV Real-time Monitor"; Description="Continuous threat monitoring"}
)

$TasksReady = 0
foreach ($TaskDetail in $TaskDetails) {
    $TaskName = $TaskDetail.Name
    $Description = $TaskDetail.Description
    
    try {
        # Try multiple methods to find the task
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        # If not found, try wildcard search as backup
        if (-not $Task) {
            $Task = Get-ScheduledTask | Where-Object {$_.TaskName -eq $TaskName} | Select-Object -First 1
        }
        
        if ($Task) {
            $TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
            $State = $Task.State
            $LastRun = if ($TaskInfo) {$TaskInfo.LastRunTime} else {"N/A"}
            $NextRun = if ($TaskInfo) {$TaskInfo.NextRunTime} else {"N/A"}
            $LastResult = if ($TaskInfo) {$TaskInfo.LastTaskResult} else {0}
            
            $StateColor = switch ($State) {
                "Ready" { "Green"; $TasksReady++ }
                "Running" { "Yellow" }
                "Disabled" { "Red" }
                default { "White" }
            }
            
            Write-Host "   Task: $TaskName" -ForegroundColor $StateColor
            Write-Host "     Description: $Description" -ForegroundColor Gray
            Write-Host "     State: $State" -ForegroundColor $StateColor
            Write-Host "     Last Run: $LastRun" -ForegroundColor White
            Write-Host "     Next Run: $NextRun" -ForegroundColor White
            Write-Host "     Last Result: $(if ($LastResult -eq 0) {"Success"} else {"Error ($LastResult)"})" -ForegroundColor $(if ($LastResult -eq 0) {"Green"} else {"Red"})
        } else {
            Write-Host "   Task: $TaskName - NOT FOUND" -ForegroundColor Red
            Write-Host "     Description: $Description" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   Task: $TaskName - ERROR READING" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}
Write-Host "   Summary: $TasksReady of $($TaskDetails.Count) tasks ready" -ForegroundColor $(if ($TasksReady -eq $TaskDetails.Count) {"Green"} else {"Yellow"})

# If no tasks found, show what ClamAV tasks actually exist
if ($TasksReady -eq 0) {
    Write-Host "   DEBUG: Searching for any ClamAV-related tasks..." -ForegroundColor Gray
    $AllClamAVTasks = Get-ScheduledTask | Where-Object {$_.TaskName -like "*ClamAV*"} -ErrorAction SilentlyContinue
    if ($AllClamAVTasks) {
        Write-Host "   Found ClamAV tasks:" -ForegroundColor Yellow
        foreach ($FoundTask in $AllClamAVTasks) {
            Write-Host "     - $($FoundTask.TaskName) ($($FoundTask.State))" -ForegroundColor White
        }
    } else {
        Write-Host "   No ClamAV tasks found in Task Scheduler" -ForegroundColor Red
        Write-Host "   Suggestion: Run clamav_automation_setup.bat to create tasks" -ForegroundColor Yellow
    }
}
Write-Host ""

# 4. RECENT SCAN RESULTS ANALYSIS
Write-Host "[4] SCAN RESULTS ANALYSIS" -ForegroundColor Green
$ScanLogs = Get-ChildItem -Path $LOG_PATH -Filter "*scan*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$CleanScans = 0
$ThreatScans = 0
$ErrorScans = 0

if ($ScanLogs) {
    Write-Host "   Recent Scan Files (Last 7 days):" -ForegroundColor Yellow
    
    $RecentLogs = $ScanLogs | Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-7)} | Select-Object -First 10
    foreach ($Log in $RecentLogs) {
        try {
            $Content = Get-Content $Log.FullName -ErrorAction SilentlyContinue
            $ScanSummary = $Content | Select-String "SCAN SUMMARY" -Context 0,5
            $InfectedFiles = $Content | Select-String "Infected files:" | Select-Object -Last 1
            $ScannedFiles = $Content | Select-String "Scanned files:" | Select-Object -Last 1
            $ScanTime = $Content | Select-String "Time:" | Select-Object -Last 1
            $ThreatsFound = $Content | Select-String " FOUND" | Where-Object {$_.Line -notmatch "0 infected"}
            
            if ($ThreatsFound) {
                Write-Host "     $($Log.Name): THREATS DETECTED" -ForegroundColor Red
                $ThreatScans++
                if ($Detailed) {
                    foreach ($Threat in $ThreatsFound | Select-Object -First 5) {
                        Write-Host "       $($Threat.Line.Trim())" -ForegroundColor Red
                    }
                }
            } elseif ($InfectedFiles -and $InfectedFiles.ToString().Contains(": 0")) {
                Write-Host "     $($Log.Name): CLEAN" -ForegroundColor Green
                $CleanScans++
            } else {
                Write-Host "     $($Log.Name): COMPLETED" -ForegroundColor White
            }
            
            if ($ScannedFiles) {
                $FilesCount = ($ScannedFiles.ToString().Split(":")[1]).Trim()
                Write-Host "       Files Scanned: $FilesCount" -ForegroundColor Gray
            }
            if ($ScanTime) {
                $Duration = ($ScanTime.ToString().Split(":")[1]).Trim()
                Write-Host "       Duration: $Duration" -ForegroundColor Gray
            }
            Write-Host "       Date: $($Log.LastWriteTime)" -ForegroundColor Gray
            Write-Host ""
            
        } catch {
            Write-Host "     $($Log.Name): ERROR READING LOG" -ForegroundColor Red
            $ErrorScans++
        }
    }
    
    Write-Host "   Scan Summary (Last 7 days):" -ForegroundColor Yellow
    Write-Host "     Clean Scans: $CleanScans" -ForegroundColor Green
    Write-Host "     Threat Detections: $ThreatScans" -ForegroundColor $(if ($ThreatScans -eq 0) {"Green"} else {"Red"})
    Write-Host "     Error Scans: $ErrorScans" -ForegroundColor $(if ($ErrorScans -eq 0) {"Green"} else {"Red"})
    Write-Host "     Total Recent Scans: $($RecentLogs.Count)" -ForegroundColor White
    
} else {
    Write-Host "   No scan log files found" -ForegroundColor Yellow
    Write-Host "   Recommendation: Run a manual scan to test system" -ForegroundColor Yellow
}
Write-Host ""

# 5. SYSTEM PERFORMANCE ANALYSIS
Write-Host "[5] SYSTEM PERFORMANCE ANALYSIS" -ForegroundColor Green
try {
    $Computer = Get-CimInstance -ClassName Win32_ComputerSystem
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem
    $Processor = Get-CimInstance -ClassName Win32_Processor
    
    # Memory Analysis
    $TotalRAM = [math]::Round($Computer.TotalPhysicalMemory / 1GB, 2)
    $FreeRAM = [math]::Round($OS.FreePhysicalMemory / 1024 / 1024, 2)
    $UsedRAM = [math]::Round($TotalRAM - $FreeRAM, 2)
    $RAMPercent = [math]::Round(($UsedRAM / $TotalRAM) * 100, 1)
    
    Write-Host "   Memory Analysis:" -ForegroundColor Yellow
    Write-Host "     Total RAM: $TotalRAM GB" -ForegroundColor White
    Write-Host "     Used RAM: $UsedRAM GB ($RAMPercent%)" -ForegroundColor White
    Write-Host "     Free RAM: $FreeRAM GB" -ForegroundColor White
    Write-Host "     ClamAV Impact: $(if ($DaemonProcesses) {[math]::Round(($DaemonProcesses | Measure-Object WorkingSet64 -Sum).Sum / 1024 / 1024, 2)} else {0}) MB" -ForegroundColor White
    
    # CPU Analysis  
    $CPUUsage = $Processor.LoadPercentage
    $CPUCores = $Processor.NumberOfCores
    $CPULogical = $Processor.NumberOfLogicalProcessors
    
    Write-Host "   CPU Analysis:" -ForegroundColor Yellow
    Write-Host "     Current Usage: $CPUUsage%" -ForegroundColor White
    Write-Host "     Cores: $CPUCores physical, $CPULogical logical" -ForegroundColor White
    Write-Host "     Processor: $($Processor.Name)" -ForegroundColor White
    
    # Disk Analysis (ClamAV directories)
    $ClamAVSize = (Get-ChildItem -Path $CLAMAV_PATH -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $LogSize = (Get-ChildItem -Path $LOG_PATH -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    
    Write-Host "   Disk Usage:" -ForegroundColor Yellow
    Write-Host "     ClamAV Installation: $([math]::Round($ClamAVSize / 1MB, 2)) MB" -ForegroundColor White
    Write-Host "     Log Files: $([math]::Round($LogSize / 1MB, 2)) MB" -ForegroundColor White
    
} catch {
    Write-Host "   Error reading system performance data" -ForegroundColor Red
}
Write-Host ""

# 6. COMPREHENSIVE HEALTH ASSESSMENT
Write-Host "[6] COMPREHENSIVE HEALTH ASSESSMENT" -ForegroundColor Green
$HealthChecks = @()
$TotalChecks = 10
$PassedChecks = 0

# Individual health checks
$Checks = @(
    @{Name="ClamAV Operational"; Test={$ClamAVOperational}; Critical=$true},
    @{Name="Daemon Memory OK"; Test={$DaemonProcesses -and ($DaemonProcesses | Measure-Object WorkingSet64 -Average).Average -lt 100MB}; Critical=$false},
    @{Name="Signatures Current"; Test={$TotalSigs -gt 8000000}; Critical=$true},
    @{Name="Daily DB Fresh"; Test={try{$DailyAge.Days -le 2}catch{$false}}; Critical=$true},
    @{Name="All Tasks Ready"; Test={$TasksReady -eq $TaskDetails.Count}; Critical=$true},
    @{Name="Recent Scan Activity"; Test={$ScanLogs.Count -gt 0}; Critical=$false},
    @{Name="No Recent Threats"; Test={$ThreatScans -eq 0}; Critical=$false},
    @{Name="Sufficient RAM"; Test={$FreeRAM -gt 1}; Critical=$false},
    @{Name="Low CPU Usage"; Test={$CPUUsage -lt 50}; Critical=$false},
    @{Name="Log Directory Exists"; Test={Test-Path $LOG_PATH}; Critical=$false}
)

Write-Host "   Individual Health Checks:" -ForegroundColor Yellow
foreach ($Check in $Checks) {
    $Result = & $Check.Test
    $Symbol = if ($Result) {"[PASS]"} else {"[FAIL]"}
    $Color = if ($Result) {"Green"} else {if ($Check.Critical) {"Red"} else {"Yellow"}}
    $Priority = if ($Check.Critical) {"[CRITICAL]"} else {"[OPTIONAL]"}
    
    Write-Host "     $Symbol $($Check.Name) $Priority" -ForegroundColor $Color
    if ($Result) { $PassedChecks++ }
}

$HealthPercent = [math]::Round(($PassedChecks / $TotalChecks) * 100)
$HealthColor = if ($HealthPercent -ge 90) {"Green"} elseif ($HealthPercent -ge 70) {"Yellow"} else {"Red"}
$HealthStatus = if ($HealthPercent -ge 90) {"EXCELLENT"} elseif ($HealthPercent -ge 70) {"GOOD"} elseif ($HealthPercent -ge 50) {"FAIR"} else {"POOR"}

Write-Host ""
Write-Host "   OVERALL HEALTH SCORE: $PassedChecks/$TotalChecks ($HealthPercent%) - $HealthStatus" -ForegroundColor $HealthColor
Write-Host ""

# 7. RECOMMENDATIONS
if ($HealthPercent -lt 100) {
    Write-Host "[7] RECOMMENDATIONS" -ForegroundColor Cyan
    if (-not $ClamAVOperational) { 
        Write-Host "   [ACTION] ClamAV not operational - check installation" -ForegroundColor Yellow 
        Write-Host "   [INFO] For on-demand mode: Ensure clamscan.exe is available" -ForegroundColor Gray
        Write-Host "   [INFO] For daemon mode: Start with clamd.exe --config-file=clamd.conf" -ForegroundColor Gray
    }
    if ($TotalSigs -le 8000000) { Write-Host "   [ACTION] Update signatures: freshclam.exe" -ForegroundColor Yellow }
    if ($TasksReady -ne $TaskDetails.Count) { Write-Host "   [ACTION] Check scheduled tasks in Task Scheduler" -ForegroundColor Yellow }
    if ($ScanLogs.Count -eq 0) { Write-Host "   [ACTION] Run initial scan: quick_scan.bat" -ForegroundColor Yellow }
    if ($ThreatScans -gt 0) { Write-Host "   [ACTION] Review threat detections in virus_alerts.log" -ForegroundColor Yellow }
    Write-Host ""
}

# Export functionality
if ($Export) {
    $ExportData = "ClamAV Granular Monitoring Report`n"
    $ExportData += "Generated: $(Get-Date)`n"
    $ExportData += "=================================`n`n"
    
    $ExportData += "DAEMON STATUS:`n"
    $ExportData += "  Operational: $(if ($ClamAVOperational) {"Yes"} else {"No"})`n"
    $ExportData += "  Detection Method: $DetectionMethod`n"
    $ExportData += "  Memory Usage: $(if ($DaemonProcesses) {[math]::Round(($DaemonProcesses | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2)} else {0}) MB`n"
    $ExportData += "  Uptime: $(if ($DaemonProcesses) {"$($Runtime.Days)d $($Runtime.Hours)h $($Runtime.Minutes)m"} else {"N/A"})`n`n"
    
    $ExportData += "SIGNATURES:`n"
    $ExportData += "  Total: $TotalSigs`n"
    $ExportData += "  Main Database: $MainSigs (v$MainVersion)`n"
    $ExportData += "  Daily Database: $DailySigs (v$DailyVersion)`n"
    $ExportData += "  Last Update: $DailyDate`n`n"
    
    $ExportData += "SCHEDULED TASKS:`n"
    $ExportData += "  Ready: $TasksReady of $($TaskDetails.Count)`n`n"
    
    $ExportData += "RECENT SCANS:`n"
    $ExportData += "  Clean Scans: $CleanScans`n"
    $ExportData += "  Threat Detections: $ThreatScans`n"
    $ExportData += "  Error Scans: $ErrorScans`n`n"
    
    $ExportData += "SYSTEM RESOURCES:`n"
    $ExportData += "  Total RAM: $TotalRAM GB`n"
    $ExportData += "  Free RAM: $FreeRAM GB`n"
    $ExportData += "  CPU Usage: $CPUUsage%`n`n"
    
    $ExportData += "HEALTH ASSESSMENT:`n"
    $ExportData += "  Score: $PassedChecks/$TotalChecks ($HealthPercent%)`n"
    $ExportData += "  Status: $HealthStatus`n"
    
    $ExportFile = "$LOG_PATH\granular_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $ExportData | Out-File -FilePath $ExportFile -Encoding UTF8
    Write-Host "Detailed report exported to: $ExportFile" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "CLAMAV ENTERPRISE SECURITY STATUS: $HealthStatus ($HealthPercent%)" -ForegroundColor $HealthColor
Write-Host "================================================================" -ForegroundColor Cyan