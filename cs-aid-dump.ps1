function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

# Function to retrieve the hostname
function Get-Hostname {
    Write-Log "Retrieving hostname..."
    try {
        $Hostname = $env:COMPUTERNAME
        Write-Log "Hostname: $Hostname"
        return $Hostname
    } catch {
        Write-Log "Failed to retrieve hostname: $_"
        throw "Failed to get hostname."
    }
}

# Function to retrieve the Agent ID (AID)
function Get-AgentID {
    Write-Log "Retrieving Agent ID (AID)..."
    try {
        # Ensure Falcon sensor service is running
        $ServiceName = "CSFalconService"

        #Wait for the service to start (check every 5 seconds)
        $MaxAttempts = 12 
        $WaitTime = 5

        $Attempts = 0
        while ($Attempts -lt $MaxAttempts) {
            $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($Service -and $Service.Status -eq "Running") {
                Write-Log "Falcon sensor service is running."
                break
            }
            $Attempts++
            Write-Log "Attempt $Attempts of $MaxAttempts. Waiting for service to start..."
            Start-Sleep -Seconds $WaitTime
        }

        if ($Attempts -ge $MaxAttempts) {
            Write-Log "Falcon sensor service did not start within the expected time."
            throw "Falcon sensor service not running after $($MaxAttempts * $WaitTime) seconds."
        }

        #Add wait time to ensure Falcon sensor is initialized fully
        Write-Log "Waiting for Falcon sensor to fully initialize..."
        Start-Sleep -Seconds 30

    } catch {
        Write-Log "Failed to retrieve Agent ID: $_"
        throw "Failed to get Agent ID (AID)."
    }
}

# Main script execution
try {

    # Step 3: Retrieve hostname
    $Hostname = Get-Hostname

    # Step 4: Retrieve Agent ID (AID)
    $AgentID = Get-AgentID

    # Output results
    Write-Log "Please copy and paste the below results to the Zendesk ticket. Thank you!"
    Write-Log "Hostname: $Hostname"
    reg query "HKLM\System\CurrentControlSet\Services\CSAgent\Sim" /f AG
    nslookup myip.opendns.com resolver1.opendns.com # get external IP address
    
} finally {
    Write-Log "Done."
}
