# MongoDB IP Monitor Service
# Save as monitor-ip.ps1

# MongoDB Atlas credentials
$PROJECT_ID = "your-project-id"
$PUBLIC_KEY = "your-public-key"
$PRIVATE_KEY = "your-private-key"
$IP_FILE = "C:\MongoIPMonitor\last-ip.txt"
$LOG_FILE = "C:\MongoIPMonitor\ip-monitor.log"
$COMPUTER_NAME = $env:COMPUTERNAME
$USERNAME = $env:USERNAME
$LOCATION = "Home"  # You can change this to any location identifier

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

function Update-MongoDBAccess {
    param($IP)
    
    $url = "https://cloud.mongodb.com/api/atlas/v1.0/groups/$PROJECT_ID/accessList"
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PUBLIC_KEY}:${PRIVATE_KEY}"))
    $headers = @{
        "Authorization" = "Basic $auth"
        "Content-Type" = "application/json"
    }
    
    # Create a detailed comment including computer name, user, location, and timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commentBody = @{
        ipAddress = $IP
        comment = "Auto-updated: $LOCATION | PC: $COMPUTER_NAME | User: $USERNAME | Updated: $timestamp"
    }
    
    $body = @([PSCustomObject]$commentBody) | ConvertTo-Json
    
    try {
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

# Create a scheduled task to run this script
$taskName = "MongoDBIPMonitor"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

if (!(Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Description "Monitors and updates home IP address in MongoDB Atlas"
    Write-Log "Created scheduled task: $taskName"
}

# Main monitoring logic
while ($true) {
    $currentIP = Get-CurrentIP
    
    if ($currentIP) {
        $lastIP = if (Test-Path $IP_FILE) { Get-Content $IP_FILE } else { "" }
        
        if ($currentIP -ne $lastIP) {
            Write-Log "IP changed from $lastIP to $currentIP"
            if (Update-MongoDBAccess $currentIP) {
                $currentIP | Set-Content $IP_FILE
            }
        }
        else {
            Write-Log "IP hasn't changed: $currentIP"
        }
    }
    
    # Wait 15 minutes before next check
    Start-Sleep -Seconds 900
}
