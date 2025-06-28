# ================================
# VirusTotal Hash Verification Script  
# File: C:\Program Files\ClamAV\scripts\virustotal_check.ps1
# Args: $args[0] = original file path, $args[1] = virus name, $args[2] = timestamp
# Exit codes: 0=safe/unknown, 1=confirmed malicious, 2=likely false positive
# ================================

param(
    [string]$FilePath,
    [string]$VirusName,
    [string]$Timestamp
)

# Configuration
$VT_API_KEY = "YOUR_VIRUSTOTAL_API_KEY_HERE"  # Replace with your actual API key
$LogFile = "C:\Program Files\ClamAV\logs\virustotal.log"
$ConfigFile = "C:\Program Files\ClamAV\scripts\vt_config.txt"

# Load API key from config file if exists
if (Test-Path $ConfigFile) {
    $VT_API_KEY = Get-Content $ConfigFile -First 1
}

function Write-VTLog {
    param([string]$Message)
    "[$Timestamp] $Message" | Add-Content $LogFile
    Write-Host $Message
}

function Get-FileHashSafe {
    param([string]$Path)
    try {
        if (Test-Path $Path) {
            return (Get-FileHash $Path -Algorithm SHA256).Hash
        } else {
            # File might be in quarantine, try to get hash from quarantine
            $QuarantineFile = "C:\Program Files\ClamAV\quarantine\$(Split-Path $Path -Leaf)"
            if (Test-Path $QuarantineFile) {
                return (Get-FileHash $QuarantineFile -Algorithm SHA256).Hash
            }
        }
        return $null
    }
    catch {
        Write-VTLog "ERROR: Failed to calculate hash for $Path - $($_.Exception.Message)"
        return $null
    }
}

function Query-VirusTotal {
    param([string]$Hash)
    
    if ([string]::IsNullOrEmpty($VT_API_KEY) -or $VT_API_KEY -eq "YOUR_VIRUSTOTAL_API_KEY_HERE") {
        Write-VTLog "WARNING: No VirusTotal API key configured. Skipping VT check."
        return $null
    }
    
    try {
        $Headers = @{
            'x-apikey' = $VT_API_KEY
        }
        
        $Uri = "https://www.virustotal.com/api/v3/files/$Hash"
        Write-VTLog "Querying VirusTotal for hash: $Hash"
        
        $Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get -TimeoutSec 30
        return $Response
        
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-VTLog "Hash not found in VirusTotal database: $Hash"
            return "NOT_FOUND"
        }
        elseif ($_.Exception.Response.StatusCode -eq 429) {
            Write-VTLog "VirusTotal API rate limit reached. Waiting..."
            Start-Sleep 60
            return "RATE_LIMITED"
        }
        else {
            Write-VTLog "ERROR: VirusTotal query failed - $($_.Exception.Message)"
            return $null
        }
    }
}

function Analyze-VTResults {
    param($VTResponse, [string]$ClamAVDetection)
    
    if ($VTResponse -eq "NOT_FOUND") {
        Write-VTLog "File not in VT database - treating as unknown"
        return 0  # Unknown/safe
    }
    
    if ($VTResponse -eq "RATE_LIMITED" -or $VTResponse -eq $null) {
        Write-VTLog "VT check failed - defaulting to ClamAV detection"
        return 1  # Trust ClamAV detection
    }
    
    $Malicious = $VTResponse.data.attributes.last_analysis_stats.malicious
    $Suspicious = $VTResponse.data.attributes.last_analysis_stats.suspicious
    $Clean = $VTResponse.data.attributes.last_analysis_stats.harmless + $VTResponse.data.attributes.last_analysis_stats.undetected
    $Total = $Malicious + $Suspicious + $Clean
    
    Write-VTLog "VT Results: $Malicious malicious, $Suspicious suspicious, $Clean clean out of $Total engines"
    
    # Analysis logic
    if ($Malicious -ge 3) {
        Write-VTLog "CONFIRMED: Multiple engines ($Malicious) detect as malicious"
        return 1  # Confirmed malicious
    }
    elseif ($Malicious -eq 0 -and $Suspicious -eq 0) {
        Write-VTLog "LIKELY FALSE POSITIVE: No engines detect as malicious"
        return 2  # Likely false positive
    }
    elseif ($Malicious -le 2 -and $Total -gt 50) {
        Write-VTLog "POSSIBLE FALSE POSITIVE: Very few detections ($Malicious/$Total)"
        return 2  # Possible false positive
    }
    else {
        Write-VTLog "INCONCLUSIVE: $Malicious detections - needs manual review"
        return 1  # Default to treating as malicious
    }
}

# Main execution
try {
    Write-VTLog "=== Starting VirusTotal verification ==="
    Write-VTLog "File: $FilePath | Detection: $VirusName"
    
    # Get file hash
    $FileHash = Get-FileHashSafe $FilePath
    if ($FileHash -eq $null) {
        Write-VTLog "ERROR: Could not calculate file hash"
        exit 1  # Default to malicious if we can't verify
    }
    
    Write-VTLog "File hash: $FileHash"
    
    # Query VirusTotal
    $VTResult = Query-VirusTotal $FileHash
    
    # Analyze results
    $ExitCode = Analyze-VTResults $VTResult $VirusName
    
    Write-VTLog "=== VirusTotal verification completed with exit code: $ExitCode ==="
    exit $ExitCode
    
}
catch {
    Write-VTLog "FATAL ERROR: $($_.Exception.Message)"
    exit 1  # Default to malicious on error
}
