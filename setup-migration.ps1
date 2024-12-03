$Host.UI.RawUI.WindowTitle = 'Creates a migration.exe for the mongo ip
update script!'

# Migration Setup Script
# Save as setup-migration.ps1

# Configuration
$GOPATH = [Environment]::GetEnvironmentVariable("GOPATH", "User")
if (-not $GOPATH) {
    $GOPATH = "$env:USERPROFILE\go"
    [Environment]::SetEnvironmentVariable("GOPATH", $GOPATH, "User")
}

function Write-Log {
    param($Message)
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

function Install-GoLang {
    try {
        # Download Go installer
        Write-Log "Downloading Go installer..."
        $goInstaller = "https://go.dev/dl/go1.21.6.windows-amd64.msi"
        $installerPath = "$env:TEMP\go_installer.msi"
        Invoke-WebRequest -Uri $goInstaller -OutFile $installerPath
        
        # Install Go
        Write-Log "Installing Go..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $installerPath, "/quiet" -Wait
        
        # Clean up
        Remove-Item $installerPath
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Log "Go installation completed"
        return $true
    }
    catch {
        Write-Log "Error installing Go: $_"
        return $false
    }
}

function Install-MigrateTool {
    try {
        # Install golang-migrate
        Write-Log "Installing golang-migrate..."
        go install -tags 'mongodb' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
        
        # Copy migrate.exe to a more accessible location
        $migrateExe = "$GOPATH\bin\migrate.exe"
        $destinationPath = "C:\Tools\migrate.exe"
        
        # Create destination directory if it doesn't exist
        New-Item -ItemType Directory -Force -Path "C:\Tools"
        
        # Copy migrate.exe
        Copy-Item -Path $migrateExe -Destination $destinationPath -Force
        
        # Add to PATH if not already there
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if (-not $currentPath.Contains("C:\Tools")) {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\Tools", "User")
        }
        
        Write-Log "Migration tool installed successfully at $destinationPath"
        return $true
    }
    catch {
        Write-Log "Error installing migration tool: $_"
        return $false
    }
}

# Main installation process
Write-Log "Starting migration tool setup..."

# Check if Go is installed
if (-not (Get-Command "go" -ErrorAction SilentlyContinue)) {
    Write-Log "Go is not installed. Installing..."
    if (-not (Install-GoLang)) {
        Write-Log "Failed to install Go. Exiting..."
        exit 1
    }
}

# Install migrate tool
if (Install-MigrateTool) {
    Write-Log "Setup completed successfully!"
    Write-Log "You can now use migrate.exe from any terminal"
    
    # Example migration commands
    Write-Log "`nExample commands:"
    Write-Log "1. Create a new migration:"
    Write-Log "   migrate create -ext .sql -dir migrations -seq my_migration"
    Write-Log "`n2. Run migrations:"
    Write-Log "   migrate -database 'mongodb://your-connection-string' -path ./migrations up"
    Write-Log "`n3. Rollback migrations:"
    Write-Log "   migrate -database 'mongodb://your-connection-string' -path ./migrations down"
}
else {
    Write-Log "Failed to install migration tool"
    exit 1
}
