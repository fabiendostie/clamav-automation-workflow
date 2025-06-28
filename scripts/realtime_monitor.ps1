# ClamAV Real-Time Log Monitor
# This script continuously watches the ClamAV log file for virus detections

# Configuration
$logFile = "C:\Program Files\ClamAV\logs\clamd.log"
$lastPositionFile = "C:\Program Files\ClamAV\logs\last_position.txt"
$alertLogFile = "C:\Program Files\ClamAV\logs\virus_alerts.log"
$desktopAlertFile = "C:\Users\Public\Desktop\VIRUS_ALERTS.txt"

# Create logs directory if it doesn't exist
if (-not (Test-Path "C:\Program Files\ClamAV\logs")) {
    New-Item -Path "C:\Program Files\ClamAV\logs" -ItemType Directory -Force | Out-Null
}

# Initialize last position if file doesn't exist
if (-not (Test-Path $lastPositionFile)) {
    "0" | Out-File -FilePath $lastPositionFile -Force
}

# Function to check for virus detections
function Check-ForViruses {
    # Get last position in log file
    $lastPosition = [long](Get-Content $lastPositionFile)
    
    # Check if log file exists
    if (-not (Test-Path $logFile)) {
        return
    }
    
    # Get current file size
    $fileInfo = Get-Item $logFile
    $currentSize = $fileInfo.Length
    
    # If file was rotated or truncated (current size smaller than last position)
    if ($currentSize -lt $lastPosition) {
        $lastPosition = 0
    }
    
    # If there's new content to process
    if ($currentSize -gt $lastPosition) {
        # Read new content
        $fileStream = New-Object System.IO.FileStream($logFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $fileStream.Position = $lastPosition
        $streamReader = New-Object System.IO.StreamReader($fileStream, [System.Text.Encoding]::UTF8)
        $newContent = $streamReader.ReadToEnd()
        $streamReader.Close()
        $fileStream.Close()
        
        # Search for virus detection patterns
        $patterns = @("FOUND", "Eicar-Test-Signature")
        $foundVirus = $false
        $detectedViruses = @()
        
        foreach ($pattern in $patterns) {
            $matches = Select-String -InputObject $newContent -Pattern $pattern -AllMatches
            
            if ($matches.Matches.Count -gt 0) {
                $foundVirus = $true
                
                foreach ($match in $matches.Matches) {
                    # Extract the full line containing the match
                    $lineStart = $newContent.LastIndexOf("`n", $match.Index) + 1
                    if ($lineStart -lt 0) { $lineStart = 0 }
                    
                    $lineEnd = $newContent.IndexOf("`n", $match.Index)
                    if ($lineEnd -lt 0) { $lineEnd = $newContent.Length }
                    
                    $line = $newContent.Substring($lineStart, $lineEnd - $lineStart)
                    $detectedViruses += $line
                }
            }
        }
        
        if ($foundVirus) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            
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
                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.MessageBox]::Show("ClamAV has detected viruses on your system.`n`nCheck the desktop alert file for details.", "VIRUS ALERT!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
            catch {
                # Fallback if popup fails
            }
        }
        
        # Update last position
        $currentSize | Out-File -FilePath $lastPositionFile -Force
    }
}

# Set up filesystem watcher to monitor the log file in real-time
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = Split-Path -Parent $logFile
$watcher.Filter = Split-Path -Leaf $logFile
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $true

# Also do an initial check
Check-ForViruses

# Create event handlers
$action = {
    # Wait a moment for the file to be fully written
    Start-Sleep -Milliseconds 500
    Check-ForViruses
}

# Register the event handler
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -SourceIdentifier ClamAVLogWatcher | Out-Null

Write-Host "ClamAV real-time log monitoring started. Press Ctrl+C to stop."

# Keep the script running
try {
    while ($true) {
        Start-Sleep -Seconds 60
        # Periodically check in case we missed an event
        Check-ForViruses
    }
}
finally {
    # Clean up when script is stopped
    Unregister-Event -SourceIdentifier ClamAVLogWatcher -ErrorAction SilentlyContinue
    $watcher.Dispose()
    Write-Host "ClamAV log monitoring stopped"
}