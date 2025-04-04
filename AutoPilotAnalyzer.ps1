<#
.SYNOPSIS
Autopilot Management Toolkit with Auto-Elevation and Execution Policy Bypass

.DESCRIPTION
Provides functionality for managing Autopilot profiles, including:
- Download and launch TeamViewer QuickSupport
- Display current Autopilot configuration
- Clean Autopilot profile and reboot
- Register device in Autopilot with dynamic GroupTag input

.VERSION
2.1.0

.AUTHOR
Your Name

.NOTES
Last Updated: April 04, 2025
Requires: PowerShell 7.0+, Administrative Privileges
Tested OS: Windows 10 22H2, Windows 11 23H2

.LINK
https://learn.microsoft.com/en-us/autopilot
#>

# Self-relaunch mechanism with execution policy bypass
if ((Get-ExecutionPolicy -Scope Process) -ne 'Bypass') {
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = @(
        '-ExecutionPolicy Bypass',
        '-NoProfile',
        '-File "{}"' -f $scriptPath
    ) -join ' '
    
    try {
        Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    }
    catch {
        Write-Host "Elevation failed: User canceled UAC prompt" -ForegroundColor Red
    }
    exit
}

# Requires admin from this point forward
#Requires -RunAsAdministrator

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

function Register-AutopilotDevice {
    try {
        $groupTag = Read-Host "`nEnter GroupTag for registration"
        $workingDir = "C:\HWID"
        
        # Environment setup for TLS and working directory creation.
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        New-Item -Path $workingDir -ItemType Directory -Force | Out-Null 
        Set-Location -Path $workingDir

        # Install required PowerShell modules and scripts.
        Install-PackageProvider `
            -Name NuGet `
            -MinimumVersion 2.8.5.201 `
            -Force | Out-Null
        
        Install-Script `
            -Name Get-WindowsAutopilotInfo `
            -Confirm:$false `
            -Force | Out-Null

        # Generate output filename based on computer name.
        $outputFile = "AutopilotHWID-$($env:COMPUTERNAME).csv"

        # Execute the script to collect hardware hash and register device.
        Get-WindowsAutopilotInfo `
            -GroupTag $groupTag `
            -Online `
            -OutputFile $outputFile
        
        Write-Host "`nRegistration successful!" `
            -ForegroundColor Green
        
        Write-Host "`nOutput file saved at: $workingDir\$outputFile" `
            -ForegroundColor Cyan

    }
    catch {
        Write-Host "[ERROR] Registration failed: $_" `
            -ForegroundColor Red

    }
}

# Main execution loop.
do {
    Show-Menu
    
    # Prompt user for menu selection.
    $selection = Read-Host "`nEnter selection"

    switch ($selection) {        
         '1' { Invoke-TeamViewerQuickSupport } 
         '2' { Show-AutopilotInfo } 
         '3' { Clear-AutopilotProfile } 
         '4' { Register-AutopilotDevice }         
         'Q' { break } 
         default {Write-host "`nInvalid selection!" `
             Foregroundcolor red}
     }
} while ($selection.ToUpper() ne 'Q')

Write-host "`Script terminated gracefully!" -ForegroundColor Green

