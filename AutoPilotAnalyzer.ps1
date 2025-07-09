<#
.SYNOPSIS
Autopilot Management Toolkit – Kompatibel mit Windows PowerShell 5.1

.DESCRIPTION
- TeamViewer QuickSupport herunterladen und starten
- Autopilot-Konfiguration anzeigen
- Autopilot-Profil zurücksetzen und neu starten
- Gerät in Autopilot registrieren
- Community Diagnostics Script ausführen
- TPM Attestation Check
- Process Explorer herunterladen und starten

.VERSION
2.4.1

.AUTHOR
Andreas Müller 2

.NOTES
Getestet mit Windows PowerShell 5.1 (Windows 10 22H2, Windows 11 24H2)
#>

# TLS 1.2 aktivieren für Web-Downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Show-Menu {
    Clear-Host
    Write-Host "=============== Autopilot Management Suite ===============" -ForegroundColor Cyan
    Write-Host " 1: Launch TeamViewer Quick Support" -ForegroundColor Yellow
    Write-Host " 2: Display Autopilot Configuration" -ForegroundColor Green
    Write-Host " 3: Reset Autopilot Profile & Reboot" -ForegroundColor Magenta
    Write-Host " 4: Register Device in Autopilot" -ForegroundColor Blue
    Write-Host " 5: Run Community Diagnostics Script" -ForegroundColor DarkCyan
    Write-Host " 6: Perform TPM Attestation Check" -ForegroundColor DarkMagenta
    Write-Host " 7: Download and Launch Process Explorer" -ForegroundColor DarkYellow
    Write-Host " Q: Exit" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Invoke-TeamViewerQuickSupport {
    try {
        $tvPath = "$env:TEMP\TeamViewerQS.exe"
        Write-Host "[$(Get-Date)] Downloading TeamViewer..." -ForegroundColor Gray
        Invoke-WebRequest -Uri "https://download.teamviewer.com/download/TeamViewerQS.exe" -OutFile $tvPath -ErrorAction Stop
        if (Test-Path $tvPath) {
            Write-Host "Launching TeamViewer QuickSupport..." -ForegroundColor Cyan
            Start-Process -FilePath $tvPath
        }
    } catch {
        Write-Host "[ERROR] TeamViewer operation failed: $_" -ForegroundColor Red
    }
}

function Show-AutopilotInfo {
    $configFile = "C:\Windows\ServiceState\wmansvc\AutopilotDDSZTDfile.json"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"
    if (Test-Path $configFile) {
        try {
            Write-Host "Opening configuration file..." -ForegroundColor Cyan
            Start-Process notepad.exe $configFile
        } catch {
            Write-Host "[ERROR] File access denied: $configFile" -ForegroundColor Red
        }
    } else {
        Write-Host "Configuration file not found" -ForegroundColor Yellow
    }
    if (Test-Path $regPath) {
        try {
            Write-Host "`nAutopilot Registry Configuration:" -ForegroundColor Cyan
            Get-ItemProperty -Path $regPath | Format-List *
        } catch {
            Write-Host "[ERROR] Registry access denied" -ForegroundColor Red
        }
    } else {
        Write-Host "Registry keys not found" -ForegroundColor Yellow
    }
}

function Clear-AutopilotProfile {
    $configFile = "C:\Windows\ServiceState\wmansvc\AutopilotDDSZTDfile.json"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "Registry entries cleared successfully" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to remove registry keys: $_" -ForegroundColor Red
        }
    }
    if (Test-Path $configFile) {
        try {
            Remove-Item -Path $configFile -Force
            Write-Host "Configuration file removed" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to delete configuration file: $_" -ForegroundColor Red
        }
    }
    $choice = Read-Host "`nReboot required. Proceed? (Y/N)"
    if ($choice -in ('Y','y')) {
        Restart-Computer -Force
    }
}

function Register-AutopilotDevice {
    try {
        $groupTag = Read-Host "`nEnter GroupTag for registration"
        $workingDir = "C:\HWID"
        if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        }
        New-Item -Path $workingDir -ItemType Directory -Force | Out-Null 
        Set-Location -Path $workingDir
        if (!(Get-Command Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
            Install-Script -Name Get-WindowsAutopilotInfo -Force
        }
        $outputFile = "AutopilotHWID-$($env:COMPUTERNAME).csv"
        & "$env:ProgramFiles\WindowsPowerShell\Scripts\Get-WindowsAutopilotInfo.ps1" -GroupTag $groupTag -Online -OutputFile $outputFile
        Write-Host "`nRegistration successful!" -ForegroundColor Green
        Write-Host "`nOutput file saved at: $workingDir\$outputFile" -ForegroundColor Cyan
    } catch {
        Write-Host "[ERROR] Registration failed: $_" -ForegroundColor Red
    }
}

function Invoke-AutopilotDiagnosticsCommunity {
    try {
        if (!(Get-Command Get-AutopilotDiagnosticsCommunity.ps1 -ErrorAction SilentlyContinue)) {
            Install-Script -Name Get-AutopilotDiagnosticsCommunity -Force
        }
        $scriptPath = "$env:ProgramFiles\WindowsPowerShell\Scripts\Get-AutopilotDiagnosticsCommunity.ps1"
        if (Test-Path $scriptPath) {
            & $scriptPath
        } else {
            Write-Host "[ERROR] Get-AutopilotDiagnosticsCommunity.ps1 not found after installation." -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Failed to install or run Get-AutopilotDiagnosticsCommunity: $_" -ForegroundColor Red
    }
    Read-Host "`nPress Enter to continue..."
}

function Invoke-TpmAttestationCheck {
    try {
        if (!(Get-Module -Name Autopilottestattestation -ListAvailable)) {
            Install-Module -Name Autopilottestattestation -Force
        }
        Set-ExecutionPolicy RemoteSigned -Scope Process -Force
        Import-Module -Name Autopilottestattestation -Force
        Write-Host "`n=== TPM Attestation Check ===" -ForegroundColor Yellow
        Test-AutopilotAttestation
    } catch {
        Write-Host "[ERROR] TPM Check failed: $_" -ForegroundColor Red
    }
    Read-Host "`nPress Enter to continue..."
}

function Invoke-ProcessExplorer {
    try {
        $procexpPath = "$env:TEMP\procexp.exe"
        Write-Host "[$(Get-Date)] Downloading Process Explorer (procexp.exe)..." -ForegroundColor Gray
        Invoke-WebRequest -Uri "https://live.sysinternals.com/procexp.exe" -OutFile $procexpPath -ErrorAction Stop
        if (Test-Path $procexpPath) {
            Write-Host "Launching Process Explorer..." -ForegroundColor Cyan
            Start-Process -FilePath $procexpPath
        } else {
            Write-Host "[ERROR] procexp.exe not found after download." -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Failed to download or launch Process Explorer: $_" -ForegroundColor Red
    }
    Read-Host "`nPress Enter to continue..."
}

# Main execution loop.
do {
    Show-Menu
    $selection = Read-Host "`nEnter selection"
    switch ($selection) {        
         '1' { Invoke-TeamViewerQuickSupport } 
         '2' { Show-AutopilotInfo } 
         '3' { Clear-AutopilotProfile } 
         '4' { Register-AutopilotDevice }  
         '5' { Invoke-AutopilotDiagnosticsCommunity }
         '6' { Invoke-TpmAttestationCheck }
         '7' { Invoke-ProcessExplorer }
         'Q' { break } 
         default {Write-host "`nInvalid selection!" -Foregroundcolor red}
     }
} while ($selection.ToUpper() -ne 'Q')

Write-host "`nScript terminated gracefully!" -ForegroundColor Green
