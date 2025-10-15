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
            Write-Log "Crowdstrike isn't installed on this device."
            throw "Falcon sensor service not running after $($MaxAttempts * $WaitTime) seconds."
        }

        #Add wait time to ensure Falcon sensor is initialized fully
        Write-Log "Waiting for Falcon sensor to fully initialize..."
        Start-Sleep -Seconds 30

    } catch {
        Write-Log "Crowdstrike isn't installed on this device. Failed to retrieve Agent ID: $_"
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
   # Output results
Write-Log "Confirming Crowdstrike is installed on the device!"
Write-Log "Hostname: $Hostname"

# AID — PowerShell registry provider + null-safe fallback
Write-Log ("Agent ID: " + ((Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\CSAgent\Sim' -ErrorAction SilentlyContinue).AID | Select-Object -First 1 | ForEach-Object { if ($_){$_} else {'Not found'} }))

# External IP — keep it null-safe just in case DNS lookup fails
Write-Log ("External IP Address: " + ((nslookup myip.opendns.com resolver1.opendns.com 2>$null | Select-String 'Address:' | Select-Object -Last 1 | ForEach-Object { $_.ToString().Split()[-1] }) | ForEach-Object { if ($_){$_} else {'Not found'} }))

# Internal IP
Write-Log "Internal IP Address: $((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1 -ExpandProperty IPAddress))"

# Serial Number — expand property (no object)
Write-Log "Serial Number: $((Get-CimInstance Win32_BIOS).SerialNumber)"

# Device Model
Write-Log "Device Model: $((Get-CimInstance -ClassName Win32_ComputerSystem).Model)"

# Current Time (AEST literal; won’t auto-switch to AEDT)
Write-Log "First Sync (AEST): $((Get-Date).ToUniversalTime().AddHours(10).ToString('yyyy-MM-dd HH:mm:ss'))"

# MAC Address — prefer physical adapter to avoid virtuals
Write-Log "MAC Address: $((Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1 -ExpandProperty MacAddress))"
    
} finally {
    Write-Log "Please copy and paste all of the above to the Spreadsheet and Zendesk ticket as an internal note. Thank you!"
}
