<#
.SYNOPSIS
Autopilot Management and Diagnostics Toolkit

.DESCRIPTION
Provides comprehensive Autopilot management capabilities including:
- Remote assistance integration
- Configuration diagnostics
- Profile maintenance
- Device registration

.VERSION
2.0.1

.AUTHOR
Your Name

.NOTES
Last Updated: April 04, 2025
Requires: PowerShell 7.0+, Administrative Privileges
Tested OS: Windows 10 22H2, Windows 11 23H2

.LINK
https://learn.microsoft.com/en-us/autopilot
#>

#Requires -RunAsAdministrator

<#
.SYNOPSIS
Displays the main interactive menu
#>
function Show-Menu {
    Clear-Host
    Write-Host "=============== Autopilot Management Suite ===============" -ForegroundColor Cyan
    Write-Host " 1: Launch TeamViewer Quick Support" -ForegroundColor Yellow
    Write-Host " 2: Display Autopilot Configuration" -ForegroundColor Green
    Write-Host " 3: Reset Autopilot Profile & Reboot" -ForegroundColor Magenta
    Write-Host " 4: Register Device in Autopilot" -ForegroundColor Blue
    Write-Host " Q: Exit" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
}

<#
.SYNOPSIS
Downloads and launches TeamViewer QuickSupport client
.DESCRIPTION
- Downloads latest TeamViewer QuickSupport edition
- Executes the client directly from temp storage
#>
function Invoke-TeamViewerQuickSupport {
    try {
        $tvPath = "$env:TEMP\TeamViewerQS.exe"
        
        Write-Host "[$(Get-Date)] Downloading TeamViewer..." -ForegroundColor Gray
        Invoke-WebRequest -Uri "https://download.teamviewer.com/download/TeamViewerQS.exe" `
            -OutFile $tvPath -ErrorAction Stop

        if (Test-Path $tvPath) {
            Write-Host "Launching TeamViewer QuickSupport..." -ForegroundColor Cyan
            Start-Process -FilePath $tvPath
        }
    }
    catch {
        Write-Host "[ERROR] TeamViewer operation failed: $_" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
Displays current Autopilot configuration details
.DESCRIPTION
- Shows JSON configuration file in Notepad
- Displays registry settings
#>
function Show-AutopilotInfo {
    $configFile = "C:\Windows\ServiceState\wmansvc\AutopilotDDSZTDfile.json"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"

    # Display configuration file
    if (Test-Path $configFile) {
        try {
            Write-Host "Opening configuration file..." -ForegroundColor Cyan
            Start-Process notepad.exe $configFile
        }
        catch {
            Write-Host "[ERROR] File access denied: $configFile" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Configuration file not found" -ForegroundColor Yellow
    }

    # Display registry information
    if (Test-Path $regPath) {
        try {
            Write-Host "`nAutopilot Registry Configuration:" -ForegroundColor Cyan
            Get-ItemProperty -Path $regPath | Format-List *
        }
        catch {
            Write-Host "[ERROR] Registry access denied" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Registry keys not found" -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
Performs Autopilot profile cleanup
.DESCRIPTION
- Removes registry entries
- Deletes configuration files
- Optionally reboots system
#>
function Clear-AutopilotProfile {
    $configFile = "C:\Windows\ServiceState\wmansvc\AutopilotDDSZTDfile.json"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"

    # Remove registry entries
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "Registry entries cleared successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Failed to remove registry keys: $_" -ForegroundColor Red
        }
    }

    # Remove configuration file
    if (Test-Path $configFile) {
        try {
            Remove-Item -Path $configFile -Force
            Write-Host "Configuration file removed" -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Failed to delete configuration file: $_" -ForegroundColor Red
        }
    }

    # Reboot confirmation
    $choice = Read-Host "`nReboot required. Proceed? (Y/N)"
    if ($choice -in ('Y','y')) {
        Restart-Computer -Force
    }
}

<#
.SYNOPSIS
Registers device in Microsoft Autopilot
.DESCRIPTION
- Collects hardware hash
- Registers device with Microsoft Intune
- Requires valid GroupTag input
#>
function Register-AutopilotDevice {
    try {
        $groupTag = Read-Host "`nEnter GroupTag for registration"
        $workingDir = "C:\HWID"
        
        # Environment setup
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        New-Item -Path $workingDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Set-Location -Path $workingDir -ErrorAction Stop

        # Package management
        Write-Host "Configuring environment..." -ForegroundColor Gray
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
        Install-Script -Name Get-WindowsAutopilotInfo -Confirm:$false -Force -ErrorAction Stop | Out-Null

        # Generate output filename
        $outputFile = "AutopilotHWID-$($env:COMPUTERNAME).csv"

        # Execute registration
        Write-Host "Starting Autopilot registration..." -ForegroundColor Cyan
        Get-WindowsAutopilotInfo -GroupTag $groupTag -Online -OutputFile $outputFile -ErrorAction Stop
        
        Write-Host "`nRegistration successful!" -ForegroundColor Green
        Write-Host "Output file: $workingDir\$outputFile" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ERROR] Registration failed: $_" -ForegroundColor Red
    }
    finally {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Restricted -Force
    }
}

# Main execution loop
do {
    Show-Menu
    $selection = Read-Host "`nEnter selection"

    switch ($selection) {
        '1' { Invoke-TeamViewerQuickSupport }
        '2' { Show-AutopilotInfo }
        '3' { Clear-AutopilotProfile }
        '4' { Register-AutopilotDevice }
        'Q' { break }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }

    if ($selection -ne 'Q') {
        Pause
    }
} while ($selection -ne 'Q')

Write-Host "`nSession terminated" -ForegroundColor Cyan
