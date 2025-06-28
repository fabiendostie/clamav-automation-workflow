# Super simple ClamAV alert checker
# Runs every minute and shows alerts for any virus detections

# Create a marker file to track what we've already alerted on
$markerFile = "C:\Program Files\ClamAV\logs\last_alert.txt"
$logFile = "C:\Program Files\ClamAV\logs\clamd.log"

# Create directory if needed
if (-not (Test-Path "C:\Program Files\ClamAV\logs")) {
    New-Item -Path "C:\Program Files\ClamAV\logs" -ItemType Directory -Force | Out-Null
}

# Initialize marker if it doesn't exist
if (-not (Test-Path $markerFile)) {
    Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath $markerFile -Force
}

# Get the last time we checked
$lastCheckTime = [datetime]::ParseExact((Get-Content $markerFile), "yyyy-MM-dd HH:mm:ss", $null)

# Check if log file exists
if (-not (Test-Path $logFile)) {
    exit
}

# Check if the log file was modified since our last check
$logLastModified = (Get-Item $logFile).LastWriteTime
if ($logLastModified -le $lastCheckTime) {
    # No changes since last check
    exit
}

# Read the log file
$logContent = Get-Content $logFile -Raw

# Look for virus detections
if ($logContent -match "FOUND") {
    # Create desktop alert file
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Extract detection lines
    $detections = @()
    foreach ($line in $logContent -split "`n") {
        if ($line -match "FOUND") {
            $detections += $line.Trim()
        }
    }
    
    # Create desktop alert
    $alertFile = "C:\Users\Public\Desktop\VIRUS_ALERT.txt"
    "VIRUS ALERT - ClamAV detected viruses!" | Out-File -FilePath $alertFile -Force
    "Alert Time: $timestamp" | Out-File -FilePath $alertFile -Append
    "=" * 50 | Out-File -FilePath $alertFile -Append
    $detections | Out-File -FilePath $alertFile -Append
    "=" * 50 | Out-File -FilePath $alertFile -Append

    # Create a simple VBScript for reliable UI popup
    $vbsFile = "$env:TEMP\clamav_alert.vbs"
    @"
    MsgBox "ClamAV has detected viruses on your system. Check the VIRUS_ALERT.txt file on your desktop for details.", 48, "ClamAV Security Alert"