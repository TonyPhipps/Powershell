<#
.SYNOPSIS
    Automated Disk Cleanup and Native Windows Image Backup Tool.
.DESCRIPTION
    Runs local and remote disk optimization and invokes wbadmin for secure, 
    block-level hot backups on bare-metal systems. Supports explicit local-only 
    overrides, custom target paths, dynamic timestamped naming conventions, 
    and multi-target scanning via files or console inputs.
.NOTES
    File Name      : Get-WindowsBackup.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges, WinRM enabled for remote targets
    Version        : 1.3
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

# Enforce strict variable execution boundaries
Set-StrictMode -Version Latest

Clear-Host
[string]$DefaultBackupPath = "D:\backups"
$Global:TargetBackupDir = ""

function Set-BackupTarget {
    <#
    .SYNOPSIS
        Prompts for and validates the base backup directory path.
    #>
    [CmdletBinding()]
    param()
    begin {}
    process {
        if ([string]::IsNullOrWhiteSpace($Global:TargetBackupDir)) {
            try {
                Write-Host "Enter backup destination directory path (or press Enter for default 'D:\backups'):" -ForegroundColor Cyan
                [string]$PathInput = (Read-Host).Trim()
                
                if ([string]::IsNullOrWhiteSpace($PathInput)) {
                    $Global:TargetBackupDir = $DefaultBackupPath
                } else {
                    $Global:TargetBackupDir = $PathInput
                }
            } catch {
                Write-Error -Message "Failed to initialize backup target directory: $_" -ErrorAction Stop
            }
        }
    }
    end {}
}

# Verify administrative runtime context
[bool]$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning -Message "This script requires administrative privileges to run Disk Cleanup and wbadmin."
    Write-Warning -Message "Please relaunch PowerShell as an Administrator."
    Exit
}

function Get-TargetHost {
    <#
    .SYNOPSIS
        Resolves target hosts via manual input parsing or text-file discovery.
    #>
    [CmdletBinding()]
    param()
    begin {}
    process {
        [string[]]$Targets = @()
        if ($LocalOverride) {
            Write-Host "LOCAL OVERRIDE ACTIVE: Processing local system execution only." -ForegroundColor Magenta
            $Targets = @("localhost")
        } else {
            Write-Host "Enter targets (comma-separated list, file path, or press Enter for local machine):" -ForegroundColor Cyan
            [string]$RawInput = (Read-Host).Trim()

            try {
                if ([string]::IsNullOrWhiteSpace($RawInput)) {
                    $Targets = @("localhost")
                } elseif (Test-Path -Path $RawInput -PathType Leaf -ErrorAction SilentlyContinue) {
                    [string]$FileContent = Get-Content -Path $RawInput -Raw -ErrorAction Stop
                    $Targets = $FileContent -split "[\r\n,]+" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
                } else {
                    $Targets = $RawInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
                }
            } catch {
                Write-Warning -Message "Failed to parse target input properly. Falling back to local machine. Details: $_"
                $Targets = @("localhost")
            }
        }
        if ($Targets.Count -eq 0) { $Targets = @("localhost") }
        return $Targets
    }
    end {}
}

function Invoke-DiskCleanup {
    <#
    .SYNOPSIS
        Executes volume cache optimization and component store cleanup routines.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$ComputerName
    )
    begin {}
    process {
        if (-not $PSBoundParameters.ContainsKey('ComputerName') -or $ComputerName.Count -eq 0) {
            $ComputerName = Get-TargetHost
        }
        foreach ($Computer in $ComputerName) {
            try {
                if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
                    Write-Host "Starting Windows Disk Cleanup on local machine..." -ForegroundColor Cyan
                    [string]$RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
                    Get-ChildItem -Path $RegPath -ErrorAction Stop | ForEach-Object {
                        New-ItemProperty -Path $_.PsPath -Name "StateFlags0001" -Value 2 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                    }
                    [System.Diagnostics.Process]$CleanMgr = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow -PassThru
                    Write-Host "Optimizing component store (DISM) locally..." -ForegroundColor Cyan
                    [System.Diagnostics.Process]$DismMgr = Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /startcomponentcleanup /quiet" -Wait -NoNewWindow -PassThru
                    Write-Host "Local Disk Cleanup and optimization complete." -ForegroundColor Gray
                } else {
                    Write-Host "Dispatching remote Disk Cleanup to $Computer..." -ForegroundColor Cyan
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        [string]$RemoteRegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
                        Get-ChildItem -Path $RemoteRegPath -ErrorAction Stop | ForEach-Object {
                            New-ItemProperty -Path $_.PsPath -Name "StateFlags0001" -Value 2 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        [System.Diagnostics.Process]$CleanMgr = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow -PassThru
                        [System.Diagnostics.Process]$DismMgr = Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /startcomponentcleanup /quiet" -Wait -NoNewWindow -PassThru
                    } -ErrorAction Stop
                    Write-Host "Remote Disk Cleanup complete on $Computer." -ForegroundColor Gray
                }
            } catch {
                Write-Error -Message "An error occurred during disk cleanup optimization on '$Computer': $_"
            }
        }
    }
    end {}
}

function Invoke-SystemBackup {
    <#
    .SYNOPSIS
        Executes block-level Windows Image Backup tasks targeting specific destination structures.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$ComputerName
    )
    begin {}
    process {
        Set-BackupTarget
        Write-Host "Target base destination directory initialized: $Global:TargetBackupDir" -ForegroundColor Yellow
        if (-not $PSBoundParameters.ContainsKey('ComputerName') -or $ComputerName.Count -eq 0) {
            $ComputerName = Get-TargetHost
        }
        foreach ($Computer in $ComputerName) {
            try {
                # Standardize names for local rendering versus remote addresses
                [string]$NormalizedHost = if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) { $env:COMPUTERNAME } else { $Computer }
                [string]$TimeStamp = (Get-Date -Format "yyyy-MM-dd_HH-mm")
                
                # Construct custom structurally isolated container destination path
                [string]$SpecificBackupDir = Join-Path -Path $Global:TargetBackupDir -ChildPath ("{0}_{1}" -f $NormalizedHost, $TimeStamp)

                if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
                    Write-Host "Initiating backup for local machine targeting '$SpecificBackupDir'..." -ForegroundColor Cyan
                    if (-not (Test-Path -Path $SpecificBackupDir)) { 
                        New-Item -ItemType Directory -Path $SpecificBackupDir -Force -ErrorAction Stop | Out-Null 
                    }
                    [string]$BackupCommand = "wbadmin start backup -backupTarget:$SpecificBackupDir -allCritical -vssFull -quiet"
                    Invoke-Expression -Command $BackupCommand
                } else {
                    Write-Host "Initiating remote backup of $Computer targeting '$SpecificBackupDir'..." -ForegroundColor Cyan
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        param([string]$TargetDir)
                        if (-not (Test-Path -Path $TargetDir)) { 
                            New-Item -ItemType Directory -Path $TargetDir -Force -ErrorAction Stop | Out-Null 
                        }
                        wbadmin start backup -backupTarget:$TargetDir -allCritical -vssFull -quiet
                    } -ArgumentList $SpecificBackupDir -ErrorAction Stop
                }
            } catch {
                Write-Error -Message "Failed to execute backup routine on host '$Computer': $_"
            }
        }
        Write-Host "Backup routine processing completed." -ForegroundColor Green
    }
    end {}
}

# MENU INTERFACE
[string]$Selection = ""
do {
    # Reset target context path variables across independent execution iterations
    $Global:TargetBackupDir = ""
    
    Write-Host "===============================================" -ForegroundColor Gray
    Write-Host "     SYSTEM MAINTENANCE & BACKUP MENU          " -ForegroundColor White
    if ($LocalOverride) { Write-Host "          [ LOCAL-ONLY OVERRIDE ACTIVE ]          " -ForegroundColor Magenta }
    Write-Host "===============================================" -ForegroundColor Gray
    Write-Host "1. Run Disk Cleanup"
    Write-Host "2. Backup Target Systems"
    Write-Host "3. Run Disk Cleanup, then Backup Target Systems"
    Write-Host "Q. Exit"
    Write-Host "-----------------------------------------------" -ForegroundColor Gray
    $Selection = (Read-Host "Select an option [1-3, Q]").ToString().ToLower().Trim()
    
    switch ($Selection) {
        "1" { Invoke-DiskCleanup }
        "2" { Invoke-SystemBackup }
        "3" { 
            [string[]]$SharedTargets = Get-TargetHost
            Set-BackupTarget
            Invoke-DiskCleanup -ComputerName $SharedTargets
            Invoke-SystemBackup -ComputerName $SharedTargets
        }
        "q" { Write-Host "`nExiting utility..." -ForegroundColor Yellow; Break }
        default { Write-Host "`nInvalid selection. Please choose an option." -ForegroundColor Red }
    }
    Write-Host ""
} while ($Selection -ne "q")