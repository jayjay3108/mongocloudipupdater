# MongoDB IP Monitor Service
# Save as mongo-ip-monitor.ps1

# MongoDB Atlas credentials
$PROJECT_ID = "your-project-id"
$PUBLIC_KEY = "your-public-key"
$PRIVATE_KEY = "your-private-key"
$IP_FILE = "C:\MongoIPMonitor\last-ip.txt"
$LOG_FILE = "C:\MongoIPMonitor\ip-monitor.log"
$COMPUTER_NAME = $env:COMPUTERNAME
$USERNAME = $env:USERNAME
$LOCATION = "Home"

# Create directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "C:\MongoIPMonitor"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Add-Content -Path $LOG_FILE
    Write-Host "$timestamp - $Message"
}

function Get-CurrentIP {
    try {
        $ip = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
        return $ip.Trim()
    }
    catch {
        Write-Log "Error getting IP: $_"
        return $null
    }
}

function Remove-OldIP {
    param($CurrentIP)
    
    try {
        # Get existing IP entries
        $url = "https://cloud.mongodb.com/api/atlas/v1.0/groups/$PROJECT_ID/accessList"
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PUBLIC_KEY}:${PRIVATE_KEY}"))
        $headers = @{
            "Authorization" = "Basic $auth"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
        
        # Filter entries that contain our computer name but not the current IP
        foreach ($entry in $response.results) {
            if ($entry.comment -like "*PC: $COMPUTER_NAME*" -and $entry.ipAddress -ne $CurrentIP) {
                $deleteUrl = "https://cloud.mongodb.com/api/atlas/v1.0/groups/$PROJECT_ID/accessList/$($entry.ipAddress)"
                try {
                    Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers
                    Write-Log "Removed old IP entry: $($entry.ipAddress)"
                }
                catch {
                    Write-Log "Failed to remove old IP entry: $($entry.ipAddress)"
                }
            }
        }
    }
    catch {
        Write-Log "Error managing old IP entries: $_"
    }
}

function Update-MongoDBAccess {
    param($IP)
    
    $url = "https://cloud.mongodb.com/api/atlas/v1.0/groups/$PROJECT_ID/accessList"
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PUBLIC_KEY}:${PRIVATE_KEY}"))
    $headers = @{
        "Authorization" = "Basic $auth"
        "Content-Type" = "application/json"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commentBody = @{
        ipAddress = $IP
        comment = "Auto-updated: $LOCATION | PC: $COMPUTER_NAME | User: $USERNAME | Updated: $timestamp"
    }
    
    $body = @([PSCustomObject]$commentBody) | ConvertTo-Json
    
    try {
        # First, remove any old IP entries for this computer
        Remove-OldIP -CurrentIP $IP
        
        # Add new IP
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        Write-Log "Successfully updated MongoDB Network Access with IP: $IP"
        Write-Log "Added comment: $($commentBody.comment)"
        
        return $true
    }
    catch {
        Write-Log "Failed to update MongoDB Network Access: $_"
        return $false
    }
}

# Create scheduled task for automatic running
$taskName = "MongoDBIPMonitor"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1)
    $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Monitors and updates home IP address in MongoDB Atlas"
    Write-Log "Created scheduled task: $taskName"
}

# Main monitoring loop
Write-Log "Starting MongoDB IP Monitor..."

while ($true) {
    $currentIP = Get-CurrentIP
    
    if ($currentIP) {
        $lastIP = if (Test-Path $IP_FILE) { Get-Content $IP_FILE } else { "" }
        
        if ($currentIP -ne $lastIP) {
            Write-Log "IP changed from $lastIP to $currentIP"
            if (Update-MongoDBAccess $currentIP) {
                $currentIP | Set-Content $IP_FILE
                Write-Log "IP update completed successfully"
            }
        }
        else {
            Write-Log "IP hasn't changed: $currentIP"
        }
    }
    else {
        Write-Log "Failed to get current IP address"
    }
    
    # Wait 15 minutes before next check
    Write-Log "Waiting 15 minutes before next check..."
    Start-Sleep -Seconds 900
}
