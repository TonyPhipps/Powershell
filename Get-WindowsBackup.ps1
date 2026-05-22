<#
.SYNOPSIS
    Automated Disk Cleanup and Native Windows Image Backup Tool.
.DESCRIPTION
    Runs local disk optimization and invokes wbadmin for secure, block-level 
    hot backups on bare-metal systems. Supports explicit local-only overrides.
.NOTES
    File Name      : Get-WindowsBackup.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges
    Version        : 1.0
    Date           : May 22, 2026
    Copyright      : (c) 2026 Tony Phipps under the MIT License
.LINK
    https://github.com/TonyPhipps/Powershell
    https://opensource.org/licenses/MIT
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [Switch]$LocalOverride
)

Clear-Host
$DefaultBackupPath = "D:\backups"
$FallbackBackupPath = "C:\backups"
$Global:TargetBackupDir = ""

function Set-BackupTarget {
    if (Test-Path "D:") {
        $Global:TargetBackupDir = $DefaultBackupPath
    } else {
        $Global:TargetBackupDir = $FallbackBackupPath
    }
    if (-not (Test-Path $Global:TargetBackupDir)) {
        New-Item -ItemType Directory -Path $Global:TargetBackupDir -Force | Out-Null
    }
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script requires administrative privileges to run Disk Cleanup and wbadmin."
    Write-Warning "Please relaunch PowerShell as an Administrator."
    Exit
}

# HELPER FUNCTIONS
function Invoke-DiskCleanup {
    Write-Host "`n[+] Starting Windows Disk Cleanup..." -ForegroundColor Cyan
    $RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    Get-ChildItem $RegPath | ForEach-Object {
        New-ItemProperty -Path $_.PsPath -Name "StateFlags0001" -Value 2 -PropertyType DWord -Force | Out-Null
    }
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
    Write-Host "[+] Optimizing component store (DISM)..." -ForegroundColor Cyan
    dism.exe /online /cleanup-image /startcomponentcleanup /quiet
    Write-Host "Disk Cleanup and optimization complete." -ForegroundColor Gray
}

function Invoke-SystemBackup {
    Set-BackupTarget
    Write-Host "Target storage destination initialized: $Global:TargetBackupDir" -ForegroundColor Yellow
    if ($LocalOverride) {
        Write-Host "LOCAL OVERRIDE ACTIVE: Processing local system execution only." -ForegroundColor Magenta
        $Targets = "localhost"
    } else {
        Write-Host "Enter target hostname(s) separated by commas (or press Enter for local machine):" -ForegroundColor Cyan
        $InputTargets = Read-Host
        if ([string]::IsNullOrWhiteSpace($InputTargets)) {
            $Targets = "localhost"
        } else {
            $Targets = $InputTargets.Split(',').ForEach({ $_.Trim() })
        }
    }
    foreach ($Computer in $Targets) {
        if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
            Write-Host "Initiating live bare-metal hot backup for local machine..." -ForegroundColor Cyan
            $BackupCommand = "wbadmin start backup -backupTarget:$Global:TargetBackupDir -allCritical -vssFull -quiet"
              # -allCritical: Captures boot loader, system state, and OS volume
              # -vssFull: Uses complete VSS context to handle active logs/databases cleanly
            Invoke-Expression $BackupCommand
        } else { # Remote Logic (Disabled automatically if $LocalOverride is flipped)
            Write-Host "Dispatching remote backup command to $Computer..." -ForegroundColor Cyan
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                param($TargetDir)
                if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
                wbadmin start backup -backupTarget:$TargetDir -allCritical -vssFull -quiet
            } -ArgumentList $Global:TargetBackupDir
        }
    }
    Write-Host "Backup routine processing completed." -ForegroundColor Green
}

# MENU INTERFACE
do {
    Write-Host "===============================================" -ForegroundColor Gray
    Write-Host "     SYSTEM MAINTENANCE & BACKUP MENU          " -ForegroundColor White
    if ($LocalOverride) { Write-Host "          [ LOCAL-ONLY OVERRIDE ACTIVE ]          " -ForegroundColor Magenta }
    Write-Host "===============================================" -ForegroundColor Gray
    Write-Host "1. Run Disk Cleanup"
    Write-Host "2. Backup Target Systems"
    Write-Host "3  Run Disk Cleanup, then Backup Target Systems"
    Write-Host "3. Exit"
    Write-Host "-----------------------------------------------" -ForegroundColor Gray
    $Selection = Read-Host "Select an option [1-3]"
    switch ($Selection) {
        "1" { Invoke-DiskCleanup }
        "2" { Invoke-SystemBackup }
        "3" { Invoke-DiskCleanup; Invoke-SystemBackup }
        "q" { Write-Host "`nExiting utility..." -ForegroundColor Yellow; Break }
        default { Write-Host "`nInvalid selection. Please choose an option." -ForegroundColor Red }
    }
    Write-Host ""
} while (-not $Selection)