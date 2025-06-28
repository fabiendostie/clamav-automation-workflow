# ClamAV Log Monitor Script - Enhanced Version
# This script checks ClamAV logs for virus detections and shows alerts

# Configuration
$logFile = "C:\Program Files\ClamAV\logs\clamd.log"
$lastPositionFile = "C:\Program Files\ClamAV\logs\last_position.txt"
$alertLogFile = "C:\Program Files\ClamAV\logs\virus_alerts.log"
$desktopAlertFile = "C:\Users\Public\Desktop\VIRUS_ALERTS.txt"
$debugLogFile = "C:\Program Files\ClamAV\logs\monitor_debug.log"

# Create log directory if it doesn't exist
if (-not (Test-Path "C:\Program Files\ClamAV\logs")) {
    New-Item -Path "C:\Program Files\ClamAV\logs" -ItemType Directory -Force | Out-Null
}

# Debug logging function
function Write-DebugLog {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $message" | Out-File -FilePath $debugLogFile -Append
}

Write-DebugLog "Script started"

# Initialize last position if file doesn't exist
if (-not (Test-Path $lastPositionFile)) {
    "0" | Out-File -FilePath $lastPositionFile -Force
    Write-DebugLog "Created new last position file with value 0"
}

# Get last position in log file
$lastPosition = [long](Get-Content $lastPositionFile)
Write-DebugLog "Last position was: $lastPosition"

# Check if log file exists
if (-not (Test-Path $logFile)) {
    Write-DebugLog "Log file not found: $logFile"
    "ClamAV log file not found. Nothing to monitor." | Out-File -FilePath $alertLogFile -Append
    exit
}

# Get current file size
$currentSize = (Get-Item $logFile).Length
Write-DebugLog "Current log file size: $currentSize bytes"

# If file was rotated or truncated (current size smaller than last position)
if ($currentSize -lt $lastPosition) {
    Write-DebugLog "Log file appears to have been rotated or truncated. Resetting position."
    $lastPosition = 0
}

# If there's new content to process
if ($currentSize -gt $lastPosition) {
    Write-DebugLog "Found $($currentSize - $lastPosition) bytes of new content"
    
    # Open the file with a FileStream to ensure we get the latest content
    $fileStream = New-Object System.IO.FileStream($logFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $fileStream.Position = $lastPosition
    $streamReader = New-Object System.IO.StreamReader($fileStream, [System.Text.Encoding]::UTF8)
    $newContent = $streamReader.ReadToEnd()
    $streamReader.Close()
    $fileStream.Close()
    
    Write-DebugLog "Read new content from log file. Length: $($newContent.Length) bytes"
    
    # Search for various virus detection patterns
    $patterns = @("FOUND", "Virus FOUND", "Eicar-Test-Signature")
    $foundVirus = $false
    $detectedViruses = @()
    
    foreach ($pattern in $patterns) {
        Write-DebugLog "Searching for pattern: $pattern"
        $matches = Select-String -InputObject $newContent -Pattern $pattern -AllMatches
        
        if ($matches.Matches.Count -gt 0) {
            Write-DebugLog "Found $($matches.Matches.Count) matches for pattern: $pattern"
            $foundVirus = $true
            
            foreach ($match in $matches.Matches) {
                # Extract the full line containing the match
                $lineStart = $newContent.LastIndexOf("`n", $match.Index) + 1
                if ($lineStart -lt 0) { $lineStart = 0 }
                
                $lineEnd = $newContent.IndexOf("`n", $match.Index)
                if ($lineEnd -lt 0) { $lineEnd = $newContent.Length }
                
                $line = $newContent.Substring($lineStart, $lineEnd - $lineStart)
                Write-DebugLog "Extracted line: $line"
                $detectedViruses += $line
            }
        }
        else {
            Write-DebugLog "No matches found for pattern: $pattern"
        }
    }
    
    if ($foundVirus) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-DebugLog "Generating virus alert for $($detectedViruses.Count) detections"
        
        "[$timestamp] Virus detections found:" | Out-File -FilePath $alertLogFile -Append
        
        foreach ($detection in $detectedViruses) {
            "[$timestamp] $detection" | Out-File -FilePath $alertLogFile -Append
        }
        
        # Create desktop alert
        "VIRUS ALERT - ClamAV detected viruses!" | Out-File -FilePath $desktopAlertFile -Force
        "Time: $timestamp" | Out-File -FilePath $desktopAlertFile -Append
        "=" * 50 | Out-File -FilePath $desktopAlertFile -Append
        $detectedViruses | Out-File -FilePath $desktopAlertFile -Append
        "=" * 50 | Out-File -FilePath $desktopAlertFile -Append
        "Please check C:\Program Files\ClamAV\logs\virus_alerts.log for details." | Out-File -FilePath $desktopAlertFile -Append
        
        # Show a popup alert
        try {
            Write-DebugLog "Attempting to show popup alert"
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show("ClamAV has detected viruses on your system.`n`nCheck the desktop alert file for details.", "VIRUS ALERT!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            Write-DebugLog "Successfully displayed popup alert"
        }
        catch {
            Write-DebugLog "Failed to show popup alert: $_"
        }
    }
    else {
        Write-DebugLog "No virus detections found in the new content"
    }
    
    # Update last position
    $currentSize | Out-File -FilePath $lastPositionFile -Force
    Write-DebugLog "Updated last position to $currentSize"
}
else {
    Write-DebugLog "No new content to process"
}

Write-DebugLog "Script completed"