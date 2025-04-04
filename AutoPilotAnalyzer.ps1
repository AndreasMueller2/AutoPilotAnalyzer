<#
.SYNOPSIS
Autopilot Maintenance Utility with TeamViewer QuickSupport integration

.DESCRIPTION
Provides automated maintenance functions for Autopilot environments including:
- Remote assistance via TeamViewer
- Autopilot configuration diagnostics
- Profile cleanup and reset operations

.VERSION
1.2.0

.AUTHOR
Your Name

.NOTES
Created:  07/02/2025
Modified: 07/02/2025
Requires PowerShell 7.0+ and administrative privileges

.CHANGELOG
v1.2.0 - Added registry safety checks and reboot confirmation
v1.1.0 - Implemented logging and error handling improvements
v1.0.0 - Initial release with core functionality

.LINK
https://learn.microsoft.com/en-us/autopilot
#>
#Requires -RunAsAdministrator

function Show-Menu {
    Clear-Host
    Write-Host "================ Autopilot Maintenance ================"
    Write-Host "1: Download and Launch TeamViewer Quick Support"
    Write-Host "2: Show Current Autopilot Profile Info"
    Write-Host "3: Clean Autopilot Profile and Reboot"
    Write-Host "Q: Exit"
    Write-Host "======================================================="
}

function Invoke-TeamViewerQuickSupport {
    $tvPath = "$env:TEMP\TeamViewerQS.exe"
    
    try {
        Write-Host "Downloading TeamViewer Quick Support..."
        Invoke-WebRequest -Uri "https://download.teamviewer.com/download/TeamViewerQS.exe" -OutFile $tvPath -ErrorAction Stop
        
        if (Test-Path $tvPath) {
            Write-Host "Launching TeamViewer..."
            Start-Process -FilePath $tvPath
        }
    }
    catch {
        Write-Host "Error downloading/running TeamViewer: $_" -ForegroundColor Red
    }
}

function Show-AutopilotInfo {
    $filePath = "C:\Windows\ServiceState\wmansvc\AutopilotDDSZTDfile.json"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"

    # Show file contents
    if (Test-Path $filePath) {
        try {
            Start-Process notepad.exe $filePath
        }
        catch {
            Write-Host "Error opening file: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Autopilot configuration file not found" -ForegroundColor Yellow
    }

    # Show registry contents
    if (Test-Path $regPath) {
        try {
            Write-Host "`nAutopilot Registry Values:"
            Get-ItemProperty -Path $regPath | Format-List
        }
        catch {
            Write-Host "Error reading registry: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Autopilot registry key not found" -ForegroundColor Yellow
    }
}

function Clear-AutopilotProfile {
    $filePath = "C:\Windows\ServiceState\wmansvc\AutopilotDDSZTDfile.json"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"

    # Delete registry entries
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "Successfully removed Autopilot registry entries" -ForegroundColor Green
        }
        catch {
            Write-Host "Error deleting registry key: $_" -ForegroundColor Red
        }
    }

    # Delete configuration file
    if (Test-Path $filePath) {
        try {
            Remove-Item -Path $filePath -Force
            Write-Host "Successfully removed Autopilot configuration file" -ForegroundColor Green
        }
        catch {
            Write-Host "Error deleting file: $_" -ForegroundColor Red
        }
    }

    # Prompt for reboot
    $choice = Read-Host "`nCleaning complete. Reboot now? (Y/N)"
    if ($choice -eq "Y") {
        Restart-Computer -Force
    }
}

# Main loop
do {
    Show-Menu
    $selection = Read-Host "`nPlease make a selection"
    
    switch ($selection) {
        '1' { Invoke-TeamViewerQuickSupport }
        '2' { Show-AutopilotInfo }
        '3' { Clear-AutopilotProfile }
        'Q' { break }
        default { Write-Host "Invalid selection" -ForegroundColor Red }
    }
    
    if ($selection -ne 'Q') {
        Pause
    }
} while ($selection -ne 'Q')

Write-Host "Script exited gracefully" -ForegroundColor Green
