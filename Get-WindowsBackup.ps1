<#
.SYNOPSIS
    Automated Disk Cleanup and Centralized Windows Image Backup Tool.
.DESCRIPTION
    Runs local and remote disk optimization and invokes wbadmin for secure, 
    block-level hot backups on bare-metal systems. Supports explicit local-only 
    overrides, target drive selections, and an automated hybrid centralized 
    architecture that dynamically spins up SMB shares, configures Active 
    Directory machine account share access permissions, and isolates individual 
    host backups into secure, zero-trust NTFS-partitioned subfolders on creation.
.PARAMETER LocalOverride
    Switch to force local system execution only, bypassing target prompt routines.
.PARAMETER BackupDrives
    Array of drive letters (e.g., C, D) to target for the image backup block.
.NOTES
    File Name      : Get-WindowsBackup.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges, WinRM enabled for remote targets
    Version        : 2.2
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

function Initialize-BackupShare {
    <#
    .SYNOPSIS
        Provisions the central backup repository parent directory and SMB network share on the local system.
    .DESCRIPTION
        Validates local storage availability, automatically builds baseline storage paths,
        applies read-only NTFS access limits for domain machine boundaries, and registers the SMB share securely.
    .PARAMETER ShareName
        The name of the SMB share container asset to provision.
    .PARAMETER DomainName
        The NetBIOS corporate domain identity string.
    .OUTPUTS
        [PSCustomObject] Structured provisioning telemetry results.
    .EXAMPLE
        Initialize-BackupShare -ShareName "backups" -DomainName "CONTOSO"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShareName,

        [Parameter(Mandatory = $true)]
        [string]$DomainName
    )
    begin {}
    process {
        Set-StrictMode -Version Latest
        try {
            if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
                Write-Host "Share '$ShareName' does not exist. Creating storage container directory..." -ForegroundColor Cyan
                [string]$LocalPath = if (Test-Path -Path "D:") { "D:\" } else { "C:\" }
                if (-not (Test-Path -Path $LocalPath)) {
                    [void](New-Item -ItemType Directory -Path $LocalPath -Force -ErrorAction Stop)
                }

                # Enforce core root directory security topologies
                $Acl = Get-Acl -Path $LocalPath
                $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
                $PropagationFlags = [System.Security.AccessControl.PropagationFlags]"None"
                $AccessType = [System.Security.AccessControl.AccessControlType]"Allow"
                
                $CompReadRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule(
                    "$DomainName\Domain Computers", "ReadAndExecute,Synchronize", $InheritanceFlags, $PropagationFlags, $AccessType
                )
                $CtrlReadRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule(
                    "$DomainName\Domain Controllers", "ReadAndExecute,Synchronize", $InheritanceFlags, $PropagationFlags, $AccessType
                )
                
                $Acl.AddAccessRule($CompReadRule)
                $Acl.AddAccessRule($CtrlReadRule)
                Set-Acl -Path $LocalPath -AclObject $Acl -ErrorAction Stop

                # Initialize and deploy the underlying network access mapping matrix
                Write-Host "Provisioning Active SMB share architecture..." -ForegroundColor Cyan
                [void](New-SmbShare -Name $ShareName -Path $LocalPath -Description "Centralized Hot-Backup Image Repository" -FullAccess "$DomainName\Domain Admins", "Administrators" -ErrorAction Stop)
                [void](Grant-SmbShareAccess -Name $ShareName -AccountName "$DomainName\Domain Computers" -AccessRight Change -Force -ErrorAction Stop)
                [void](Grant-SmbShareAccess -Name $ShareName -AccountName "$DomainName\Domain Controllers" -AccessRight Change -Force -ErrorAction Stop)
                
                return [PSCustomObject]@{
                    Success = $true
                    Message = "Centralized SMB share orchestration complete."
                }
            }
            
            return [PSCustomObject]@{
                Success = $true
                Message = "Share '$ShareName' already exists. Configuration skipped."
            }
        } catch {
            return [PSCustomObject]@{
                Success = $false
                Message = "Failed to orchestrate central SMB share parameters: $_"
            }
        }
    }
    end {}
}

function Initialize-BackupSubfolder {
    <#
    .SYNOPSIS
        Provisions a zero-trust, access-isolated NTFS file structure silo for specific server nodes.
    .DESCRIPTION
        Verifies directory existence, drops broad security inheritable objects from parent trees,
        and isolates folder modification capabilities solely to the assigned target machine account.
    .PARAMETER BasePath
        The central folder repository root path or remote network UNC endpoint.
    .PARAMETER TargetHost
        The targeted node hostname designation to structure and assign permissions against.
    .PARAMETER DomainName
        The corporate Active Directory environment NetBIOS domain identity.
    .OUTPUTS
        [PSCustomObject] Subfolder instantiation results.
    .EXAMPLE
        Initialize-BackupSubfolder -BasePath "\\backupserver\backups" -TargetHost "DC-PROD01" -DomainName "CONTOSO"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetHost,

        [Parameter(Mandatory = $true)]
        [string]$DomainName
    )
    begin {}
    process {
        try {
            [string]$HostFolderUNC = ""
            if ($BasePath -match '^[A-Za-z]:\\') {
                $HostFolderUNC = Join-Path -Path $BasePath -ChildPath $TargetHost
            } else {
                $HostFolderUNC = "$BasePath\$TargetHost"
            }

            if (-not (Test-Path -Path $HostFolderUNC)) {
                Write-Host "Target folder does not exist. Creating isolated subfolder container at '$HostFolderUNC'..." -ForegroundColor Yellow
                [void](New-Item -ItemType Directory -Path $HostFolderUNC -Force -ErrorAction Stop)
                [string]$MachineAccount = "$DomainName\$TargetHost$"
                $Acl = Get-Acl -Path $HostFolderUNC
                
                # Protect ACL from root inheritance structures, preserving explicit structural assignments (SYSTEM/Admins)
                $Acl.SetAccessRuleProtection($true, $true)
                
                # Purge generalized domain grouping read assignments inherited down from share root provisions
                [System.Security.AccessControl.FileSystemAccessRule[]]$TargetRules = $Acl.Access | Where-Object {
                    $_.IdentityReference.Value -eq "$DomainName\Domain Computers" -or 
                    $_.IdentityReference.Value -eq "$DomainName\Domain Controllers"
                }
                foreach ($Rule in $TargetRules) {
                    [void]$Acl.RemoveAccessRule($Rule)
                }

                # Bind target machine token permissions tightly down to the isolated container boundary path
                $Inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
                $Propagation = [System.Security.AccessControl.PropagationFlags]"None"
                $Type = [System.Security.AccessControl.AccessControlType]"Allow"
                $ModifyRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule($MachineAccount, "Modify,Synchronize", $Inheritance, $Propagation, $Type)
                $Acl.AddAccessRule($ModifyRule)
                Set-Acl -Path $HostFolderUNC -AclObject $Acl -ErrorAction Stop
                return [PSCustomObject]@{ Success = $true; Message = "Successfully built and restricted isolated environment." }
            }
            return [PSCustomObject]@{ Success = $true; Message = "Utilizing existing verified environment containers." }
        } catch {
            return [PSCustomObject]@{ Success = $false; Message = "Failed inside subfolder security deployment pipeline: $_" }
        }
    }
    end {}
}

function Set-BackupTarget {
    <#
    .SYNOPSIS
        Prompts for, validates, and dynamically configures the base backup repository or UNC share target.
    #>
    [CmdletBinding()]
    param()
    begin {}
    process {
        if ([string]::IsNullOrWhiteSpace($Global:TargetBackupDir)) {
            try {
                Write-Host "Enter central backup destination path (Local Path or UNC like '\\backupserver\backups'):" -ForegroundColor Cyan
                [string]$PathInput = (Read-Host).Trim()
                if ([string]::IsNullOrWhiteSpace($PathInput)) {
                    $Global:TargetBackupDir = $DefaultBackupPath
                } else {
                    $Global:TargetBackupDir = $PathInput
                }

                # Dynamically provision and secure the target resource if a UNC share path is specified
                if ($Global:TargetBackupDir -match '^\\\\([^\\]+)\\([^\\]+)') {
                    [string]$ServerName = $Matches[1]
                    [string]$ShareName = $Matches[2]
                    [string]$DomainName = $env:USERDOMAIN
                    Write-Host "Verifying infrastructure readiness for central SMB share '$ShareName' on server '$ServerName'..." -ForegroundColor Yellow
                    [PSCustomObject]$ProvisionStatus = Initialize-BackupParentShare -ComputerName $ServerName -ShareName $ShareName -DomainName $DomainName
                    if ($ProvisionStatus.Success) {
                        Write-Host "Parent Infrastructure Routing: $($ProvisionStatus.Message)" -ForegroundColor Green
                    } else {
                        Write-Warning -Message "Parent Infrastructure Failure: $($ProvisionStatus.Message)"
                    }
                }
            } catch {
                Write-Error -Message "Failed to initialize backup target directory structure: $_" -ErrorAction Stop
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
        # Enforce native .Length array checking rules under StrictMode parameters
        if (@($Targets).Length -eq 0) { $Targets = @("localhost") }
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
        # Secure variable property verification inside strict mode pipelines via native length check boundaries
        if (-not $PSBoundParameters.ContainsKey('ComputerName') -or @($ComputerName).Length -eq 0) {
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
        Executes block-level Windows Image Backup tasks targeting partitioned destination directories.
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
        Write-Host "Centralized storage root initialized: $Global:TargetBackupDir" -ForegroundColor Yellow
        
        # Enforce array expression length check boundaries for safety under Set-StrictMode definitions
        if (-not $PSBoundParameters.ContainsKey('ComputerName') -or @($ComputerName).Length -eq 0) {
            $ComputerName = Get-TargetHost
        }
        [string[]]$SelectedDrives = @()
        if (-not $PSBoundParameters.ContainsKey('ExplicitDrives') -or @($ExplicitDrives).Length -eq 0) {
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

                # Enforce host-isolated subfolder naming paths inside the repository
                [string]$HostFolderUNC = ""
                if ($Global:TargetBackupDir -match '^[A-Za-z]:\\') {
                    $HostFolderUNC = Join-Path -Path $Global:TargetBackupDir -ChildPath $NormalizedHost
                } else {
                    $HostFolderUNC = "$Global:TargetBackupDir\$NormalizedHost"
                }

                # Abstracted zero-trust folder separation engine logic routine call
                [PSCustomObject]$FolderStatus = Initialize-BackupSubfolder -BasePath $Global:TargetBackupDir -TargetHost $NormalizedHost -DomainName $env:USERDOMAIN
                Write-Host "Subfolder Allocation Mapping: $($FolderStatus.Message)" -ForegroundColor Gray
                if (-not $FolderStatus.Success) {
                    Write-Error -Message "Subfolder architecture error. Aborting backup cycle iteration for '$NormalizedHost'."
                    Continue
                }
                if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
                    [string]$DriveString = ""
                    if (@($SelectedDrives).Length -eq 0) {
                        [string[]]$LocalFixedDrives = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop).DeviceID
                        $DriveString = $LocalFixedDrives -join ","
                    } else {
                        $DriveString = ($SelectedDrives | ForEach-Object { "$($_):" }) -join ","
                    }
                    Write-Host "Initiating local backup targeting storage path '$HostFolderUNC' [Drives: $DriveString]..." -ForegroundColor Cyan
                    [string]$BackupCommand = "wbadmin start backup -backupTarget:$HostFolderUNC -include:$DriveString -allCritical -vssFull -quiet"
                    Invoke-Expression -Command $BackupCommand
                } else {
                    Write-Host "Dispatching network hot-backup on $Computer targeting remote repository folder '$HostFolderUNC'..." -ForegroundColor Cyan
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        param([string]$TargetFolder, [string[]]$DrivesToBackup)
                        Set-StrictMode -Version Latest
                        
                        # Dynamically resolve potential null or deserialized string arrays inside remote PSSession parameters using native .Length properties
                        [string]$RemoteDriveString = ""
                        if ($null -eq $DrivesToBackup -or @($DrivesToBackup).Length -eq 0) {
                            [string[]]$RemoteFixedDrives = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3").DeviceID
                            $RemoteDriveString = $RemoteFixedDrives -join ","
                        } else {
                            $RemoteDriveString = ($DrivesToBackup | ForEach-Object { "$($_):" }) -join ","
                        }

                        # Executes directly across single-hop mapping leveraging the machine account's dedicated token permission
                        wbadmin start backup -backupTarget:$TargetFolder -include:$RemoteDriveString -allCritical -vssFull -quiet
                    } -ArgumentList $HostFolderUNC, $SelectedDrives -ErrorAction Stop
                }
            } catch {
                Write-Error -Message "Failed to execute centralized backup routine on host '$Computer': $_"
            }
        }
    }
    end {}
}

# MENU INTERFACE
[string]$Selection = ""
do {
    $Global:TargetBackupDir = ""
    
    Write-Host "===============================================" -ForegroundColor Gray
    Write-Host "     SYSTEM MAINTENANCE & BACKUP MENU          " -ForegroundColor White
    if ($LocalOverride) { Write-Host "     [ LOCAL-ONLY OVERRIDE ACTIVE ]          " -ForegroundColor Magenta }
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