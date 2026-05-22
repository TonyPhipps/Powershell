<#
.SYNOPSIS
    Automated Disk Cleanup and Windows Image Backup Tool.
.DESCRIPTION
    Runs local and remote disk optimization and invokes wbadmin for secure, 
    block-level hot backups on bare-metal systems. Supports explicit local-only 
    overrides, custom target paths, target drive selections, dynamic timestamped 
    naming conventions on backup folders, and multi-target scanning via files or
    console inputs.
.PARAMETER LocalOverride
    Switch to force local system execution only, bypassing target prompt routines.
.PARAMETER BackupDrives
    Array of drive letters (e.g., C, D) to target for the image backup block.
.NOTES
    File Name      : Get-WindowsBackup.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges, WinRM enabled for remote targets
    Version        : 1.4
    Date           : May 22, 2026
    Copyright      : (c) 2026 Tony Phipps under the MIT License
.LINK
    https://github.com/TonyPhipps/Powershell
    https://opensource.org/licenses/MIT
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [Switch]$LocalOverride,

    [Parameter(Mandatory = $false)]
    [string[]]$BackupDrives
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
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string[]]$ExplicitDrives
    )
    begin {}
    process {
        Set-BackupTarget
        Write-Host "Target base destination directory initialized: $Global:TargetBackupDir" -ForegroundColor Yellow
        
        if (-not $PSBoundParameters.ContainsKey('ComputerName') -or $ComputerName.Count -eq 0) {
            $ComputerName = Get-TargetHost
        }

        # Handle fallback selection criteria if drive target parameters were omitted during parameter execution bindings
        [string[]]$SelectedDrives = @()
        if (-not $PSBoundParameters.ContainsKey('ExplicitDrives') -or $ExplicitDrives.Count -eq 0) {
            Write-Host "Enter drive letters to back up (comma-separated, e.g., C,D), or press Enter for ALL fixed drives:" -ForegroundColor Cyan
            [string]$DriveInput = (Read-Host).Trim()
            
            if (-not [string]::IsNullOrWhiteSpace($DriveInput)) {
                $SelectedDrives = $DriveInput -split "," | ForEach-Object { $_.Trim().ToUpper().Replace(":", "") } | Where-Object { $_ -ne "" }
            }
        } else {
            $SelectedDrives = $ExplicitDrives | ForEach-Object { $_.Trim().ToUpper().Replace(":", "") } | Where-Object { $_ -ne "" }
        }

        foreach ($Computer in $ComputerName) {
            try {
                [string]$NormalizedHost = if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) { $env:COMPUTERNAME } else { $Computer }
                [string]$TimeStamp = (Get-Date -Format "yyyy-MM-dd_HH-mm")
                [string]$SpecificBackupDir = Join-Path -Path $Global:TargetBackupDir -ChildPath ("{0}_{1}" -f $NormalizedHost, $TimeStamp)
                if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
                    # Evaluate dynamic drive parameters locally
                    [string]$DriveString = ""
                    if ($SelectedDrives.Count -eq 0) {
                        [string[]]$LocalFixedDrives = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop).DeviceID
                        $DriveString = $LocalFixedDrives -join ","
                    } else {
                        $DriveString = ($SelectedDrives | ForEach-Object { "$($_):" }) -join ","
                    }
                    Write-Host "Initiating backup for local machine targeting '$SpecificBackupDir' [Drives: $DriveString]..." -ForegroundColor Cyan
                    if (-not (Test-Path -Path $SpecificBackupDir)) { 
                        New-Item -ItemType Directory -Path $SpecificBackupDir -Force -ErrorAction Stop | Out-Null 
                    }
                    [string]$BackupCommand = "wbadmin start backup -backupTarget:$SpecificBackupDir -include:$DriveString -allCritical -vssFull -quiet"
                    Invoke-Expression -Command $BackupCommand
                } else {
                    Write-Host "Initiating remote backup of $Computer targeting '$SpecificBackupDir'..." -ForegroundColor Cyan
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        param([string]$TargetDir, [string[]]$DrivesToBackup)
                        if (-not (Test-Path -Path $TargetDir)) { 
                            New-Item -ItemType Directory -Path $TargetDir -Force -ErrorAction Stop | Out-Null 
                        }

                        # Dynamic discovery of target drives natively within the remote systems domain scope
                        [string]$RemoteDriveString = ""
                        if ($DrivesToBackup.Count -eq 0) {
                            [string[]]$RemoteFixedDrives = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3").DeviceID
                            $RemoteDriveString = $RemoteFixedDrives -join ","
                        } else {
                            $RemoteDriveString = ($DrivesToBackup | ForEach-Object { "$($_):" }) -join ","
                        }
                        wbadmin start backup -backupTarget:$TargetDir -include:$RemoteDriveString -allCritical -vssFull -quiet
                    } -ArgumentList $SpecificBackupDir, $SelectedDrives -ErrorAction Stop
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
    $Global:TargetBackupDir = ""
    
    Write-Host "===============================================" -ForegroundColor Gray
    Write-Host "     SYSTEM MAINTENANCE & BACKUP MENU          " -ForegroundColor White
    if ($LocalOverride) { Write-Host "          [ LOCAL-ONLY OVERRIDE ACTIVE ]          " -ForegroundColor Magenta }
    Write-Host "===============================================" -ForegroundColor Gray
    Write-Host "1. Run Disk Cleanup on Target Systems"
    Write-Host "2. Backup Target Systems"
    Write-Host "3. Run Disk Cleanup, then Backup Target Systems"
    Write-Host "Q. Exit"
    Write-Host "-----------------------------------------------" -ForegroundColor Gray
    $Selection = (Read-Host "Select an option [1-3, Q]").ToString().ToLower().Trim()
    
    switch ($Selection) {
        "1" { Invoke-DiskCleanup }
        "2" { Invoke-SystemBackup -ExplicitDrives $BackupDrives }
        "3" { 
            [string[]]$SharedTargets = Get-TargetHost
            Set-BackupTarget
            Invoke-DiskCleanup -ComputerName $SharedTargets
            Invoke-SystemBackup -ComputerName $SharedTargets -ExplicitDrives $BackupDrives
        }
        "q" { Write-Host "`nExiting utility..." -ForegroundColor Yellow; Break }
        default { Write-Host "`nInvalid selection. Please choose an option." -ForegroundColor Red }
    }
    Write-Host ""
} while ($Selection -ne "q")