<#
.SYNOPSIS
    Automated Disk Cleanup and Centralized Windows Image Backup Tool with Retention Management.
.DESCRIPTION
    Runs local and remote disk optimization, invokes wbadmin for secure, 
    block-level hot backups on bare-metal systems, and enforces historical retention. 
    Supports a centralized architecture that dynamically spins up SMB shares, configures 
    Active Directory machine account share access permissions, isolates individual host 
    backups into date-stamped secure subfolders, and prunes expired baselines safely.
.PARAMETER BackupDrives
    Array of drive letters (e.g., C, D) to target for the image backup block.
.PARAMETER RetentionDays
    The maximum age in days to retain historical backups before purging. Defaults to 30 days.
.NOTES
    File Name      : Invoke-SystemBackup.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges, WinRM enabled for remote targets
    Version        : 2.5.0
    Date           : May 28, 2026
    Copyright      : (c) 2026 Tony Phipps under the MIT License
.LINK
    https://github.com/TonyPhipps/Powershell
    https://opensource.org/licenses/MIT
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [alias("H", "Host", "Computer", "Computers")]
    [string[]]$Hosts,

    [Parameter(Mandatory = $false)]
    [string]$IncludeDrives,

    [Parameter(Mandatory = $false)]
    [string]$BackupTarget,

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 30
)

Set-StrictMode -Version Latest

function Test-WindowsBackupInstalled {
    <#
    .SYNOPSIS
        Checks if the Windows Server Backup feature is installed on a specified target host.
    .PARAMETER ComputerName
        The hostname or IP address of the target system to check.
    .OUTPUTS
        [bool] True if installed or successfully installed, False if missing/canceled.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    try {
        $IsLocal = ($ComputerName -eq "localhost" -or $ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq ".")
        
        # Define isolated block for querying feature status via local or remote serialization boundaries
        $CheckBlock = {
            Set-StrictMode -Version Latest
            if (-not (Get-Module -ListAvailable -Name ServerManager)) {
                return @{ Installed = $false; ServerManagerAvailable = $false }
            }
            $feature = Get-WindowsFeature -Name Windows-Server-Backup -ErrorAction Stop
            return @{ Installed = $feature.Installed; ServerManagerAvailable = $true }
        }

        Write-Host "Verifying Windows Server Backup status on '$ComputerName'..." -ForegroundColor Cyan
        $Result = if ($IsLocal) {
            Invoke-Command -ScriptBlock $CheckBlock
        } else {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $CheckBlock -ErrorAction Stop
        }

        if (-not $Result.ServerManagerAvailable) {
            Write-Warning "The ServerManager module is not available on '$ComputerName'. Ensure it is running Windows Server."
            return $false
        }

        if ($Result.Installed) {
            Write-Host "Windows Server Backup is already installed on '$ComputerName'." -ForegroundColor Green
            return $true
        } else {
            Write-Host "Windows Server Backup is NOT installed on '$ComputerName'." -ForegroundColor Yellow
            $confirmation = Read-Host "Would you like to install Windows Server Backup on '$ComputerName' now? (Y/N)"
            if ($confirmation -match '^[Yy](es)?$') {
                Write-Host "Starting installation on '$ComputerName'..." -ForegroundColor Cyan
                $InstallBlock = {
                    Set-StrictMode -Version Latest
                    Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools -ErrorAction Stop
                }
                
                if ($IsLocal) {
                    Invoke-Command -ScriptBlock $InstallBlock -ErrorAction Stop
                } else {
                    Invoke-Command -ComputerName $ComputerName -ScriptBlock $InstallBlock -ErrorAction Stop
                }
                Write-Host "Windows Server Backup has been successfully installed on '$ComputerName'!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "Installation canceled by user for '$ComputerName'." -ForegroundColor Gray
                return $false
            }
        }
    }
    catch {
        Write-Error "An error occurred while checking the feature status on '$ComputerName': $_"
        return $false
    }
}

function Initialize-HostList {
    param(
        [string[]]$TargetHosts
    )

    # If blank, prompt the user using the do-while approach
    if (-not $TargetHosts -or $TargetHosts.Count -eq 0 -or [string]::IsNullOrWhiteSpace($TargetHosts[0])) {
        do {
            $userInput = Read-Host "Enter hostname(s), a file path, or 'ad' for Active Directory servers"
            if ([string]::IsNullOrWhiteSpace($userInput)) {
                Write-Warning "Input cannot be empty. Please provide a valid value."
            }
        } while ([string]::IsNullOrWhiteSpace($userInput))
        $TargetHosts = $userInput -split ',' | ForEach-Object { $_.Trim() }
    }
    $resolvedHosts = @()
    foreach ($item in $TargetHosts) {
        $item = $item.Trim()
        if ($item -eq 'ad') {
            if (Get-Module -ListAvailable -Name ActiveDirectory) {
                Write-Verbose "Querying Active Directory for enabled Windows Servers..."
                $adHosts = Get-ADComputer -Filter "Enabled -eq '$true' and OperatingSystem -like '*Server*'" | Select-Object -ExpandProperty Name
                $resolvedHosts += $adHosts
            } else {
                Write-Error "The ActiveDirectory module is not available on this system."
            }
        }
        elseif (Test-Path -Path $item -PathType Leaf -ErrorAction SilentlyContinue) {
            Write-Verbose "Reading hostnames from file: $item"
            $fileHosts = Get-Content -Path $item | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim().Trim(',') }
            $resolvedHosts += $fileHosts
        }
        else {
            if (-not [string]::IsNullOrWhiteSpace($item)) {
                $resolvedHosts += $item
            }
        }
    }
    return ($resolvedHosts | Select-Object -Unique)
}

function Invoke-DiskCleanup {
    <#
    .SYNOPSIS
        Executes volume cache optimization and component store cleanup routines.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$Hosts
    )
    begin {}
    process {
        foreach ($Computer in $Hosts) {
            try {
                if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
                    Write-Host "Starting Windows Disk Cleanup on local machine..." -ForegroundColor Cyan
                    [string]$RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
                    Get-ChildItem -Path $RegPath -ErrorAction Stop | ForEach-Object {
                        $null = New-ItemProperty -Path $_.PsPath -Name "StateFlags0001" -Value 2 -PropertyType DWord -Force -ErrorAction SilentlyContinue
                    }
                    $null = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow -PassThru
                    Write-Host "Optimizing component store (DISM) locally..." -ForegroundColor Cyan
                    $null = Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /startcomponentcleanup /quiet" -Wait -NoNewWindow -PassThru
                    Write-Host "Local Disk Cleanup and optimization complete." -ForegroundColor Gray
                } else {
                    Write-Host "Dispatching remote Disk Cleanup to $Computer..." -ForegroundColor Cyan
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        [string]$RemoteRegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
                        Get-ChildItem -Path $RemoteRegPath -ErrorAction Stop | ForEach-Object {
                            $null = New-ItemProperty -Path $_.PsPath -Name "StateFlags0001" -Value 2 -PropertyType DWord -Force -ErrorAction SilentlyContinue
                        }
                        $null = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow -PassThru
                        $null = Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /startcomponentcleanup /quiet" -Wait -NoNewWindow -PassThru
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

function Initialize-BackupShare {
    <#
    .SYNOPSIS
        Provisions the central backup repository parent directory and SMB network share.
    .DESCRIPTION
        Validates target infrastructure availability, automatically builds baseline storage paths,
        applies read-only NTFS access limits for domain machine boundaries, and registers the SMB share securely.
    .PARAMETER ComputerName
        The target server hostname where the SMB network share instance should be evaluated and built.
    .PARAMETER ShareName
        The name of the SMB share container asset to provision.
    .OUTPUTS
        [PSCustomObject] Structured provisioning telemetry results.
    .EXAMPLE
        Initialize-BackupShare -ComputerName "backupserver" -ShareName "backups"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$ShareName
    )
    begin {
        [string]$DomainName = $env:USERDOMAIN
    }
    process {
        # Execution script block designated for localized single-hop engine calls
        [scriptblock]$ProvisionBlock = {
            param([string]$Share, [string]$Domain)
            Set-StrictMode -Version Latest
            try {
                if (-not (Get-SmbShare -Name $Share -ErrorAction SilentlyContinue)) {
                    Write-Host "Share '$Share' does not exist. Creating storage container directory..." -ForegroundColor Cyan
                    [string]$LocalPath = if (Test-Path -Path "D:") { "D:\backups" } else { "C:\backups" }
                    if (-not (Test-Path -Path $LocalPath)) {
                        $null = New-Item -ItemType Directory -Path $LocalPath -Force -ErrorAction Stop
                    }

                    # Enforce core root directory security topologies
                    $Acl = Get-Acl -Path $LocalPath
                    $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
                    $PropagationFlags = [System.Security.AccessControl.PropagationFlags]"None"
                    $AccessType = [System.Security.AccessControl.AccessControlType]"Allow"
                    $CompReadRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule(
                        "$Domain\Domain Computers", "ReadAndExecute,Synchronize", $InheritanceFlags, $PropagationFlags, $AccessType
                    )
                    $CtrlReadRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule(
                        "$Domain\Domain Controllers", "ReadAndExecute,Synchronize", $InheritanceFlags, $PropagationFlags, $AccessType
                    )
                    $Acl.AddAccessRule($CompReadRule)
                    $Acl.AddAccessRule($CtrlReadRule)
                    Set-Acl -Path $LocalPath -AclObject $Acl -ErrorAction Stop

                    # Initialize and deploy the underlying network access mapping matrix
                    Write-Host "Provisioning Active SMB share architecture..." -ForegroundColor Cyan
                    $null = New-SmbShare -Name $Share -Path $LocalPath -Description "Centralized Hot-Backup Image Repository" -FullAccess "$Domain\Domain Admins", "Administrators" -ErrorAction Stop
                    $null = Grant-SmbShareAccess -Name $Share -AccountName "$Domain\Domain Computers" -AccessRight Change -Force -ErrorAction Stop
                    $null = Grant-SmbShareAccess -Name $Share -AccountName "$Domain\Domain Controllers" -AccessRight Change -Force -ErrorAction Stop
                    return [PSCustomObject]@{
                        Success = $true
                        Message = "Centralized SMB share orchestration complete."
                    }
                }
                return [PSCustomObject]@{
                    Success = $true
                    Message = "Share '$Share' already exists. Configuration skipped."
                }
            } catch {
                return [PSCustomObject]@{
                    Success = $false
                    Message = "Failed to orchestrate central SMB share parameters: $_"
                }
            }
        }
        try {
            [PSCustomObject]$Result = $null
            if ($ComputerName -eq "localhost" -or $ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq ".") {
                $Result = Invoke-Command -ScriptBlock $ProvisionBlock -ArgumentList $ShareName, $DomainName -ErrorAction Stop
            } else {
                $Result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $ProvisionBlock -ArgumentList $ShareName, $DomainName -ErrorAction Stop
            }
            return $Result
        } catch {
            Write-Error -Message "Pipeline bridge connection error during parent share provisioning: $_"
            return [PSCustomObject]@{ Success = $false; Message = $_.Exception.Message }
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
        if ([string]::IsNullOrWhiteSpace($Global:BackupTarget)) {
            try {
                [string]$PathInput = $null
                [bool]$IsValid = $false
                do {
                    Write-Host "Enter central backup destination path (Local Root Drive like 'd:\' or UNC like '\\backupserver\backups')`n Default is d:\:" -ForegroundColor Cyan
                    $PathInput = (Read-Host).Trim()
                    if ([string]::IsNullOrWhiteSpace($PathInput)) {
                        $PathInput = "D:\"
                    }
                    if (($PathInput -match '^[a-zA-Z]:\\$') -or ($PathInput -match '^\\\\[^\\]+\\[^\\]+')) {
                        $IsValid = $true
                    } else {
                        Write-Host "[-] Invalid Entry: Path must match a root drive format (e.g., E:\) or a UNC path (e.g., \\server\share)." -ForegroundColor Red
                        Write-Host "Please try again.`n" -ForegroundColor Yellow
                    }
                } while (-not $IsValid)
                $Global:BackupTarget = $PathInput

                # Dynamically provision and secure the target resource if a UNC share path is specified
                if ($Global:BackupTarget -match '^\\\\([^\\]+)\\([^\\]+)') {
                    [string]$ServerName = $Matches[1]
                    [string]$ShareName = $Matches[2]
                    Write-Host "Verifying infrastructure readiness for central SMB share '$ShareName' on server '$ServerName'..." -ForegroundColor Yellow
                    [PSCustomObject]$ProvisionStatus = Initialize-BackupShare -ComputerName $ServerName -ShareName $ShareName
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
    .OUTPUTS
        [PSCustomObject] Subfolder instantiation results.
    .EXAMPLE
        Initialize-BackupSubfolder -BasePath "\\backupserver\backups" -TargetHost "DC-PROD01"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetHost
    )
    begin {
        [string]$DomainName = $env:USERDOMAIN
    }
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
                $null = New-Item -ItemType Directory -Path $HostFolderUNC -Force -ErrorAction Stop
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
                    $null = $Acl.RemoveAccessRule($Rule)
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

function Remove-OldBackups {
    <#
    .SYNOPSIS
        Evaluates existing backup targets for target hosts and purges blocks exceeding specified age thresholds.
    .DESCRIPTION
        Ensures strict data preservation by utilizing chronologically sorted tracking arrays. 
        Enforces a safety boundary that always leaves at least one valid operational image on-disk.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Hosts,

        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $false)]
        [int]$AgeThresholdDays = 30
    )
    process {
        if (-not (Test-Path -Path $BasePath)) {
            Write-Warning "Backup repository path '$BasePath' is inaccessible. Retention cleanup aborted."
            return
        }

        foreach ($Computer in $Hosts) {
            [string]$NormalizedHost = if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) { $env:COMPUTERNAME } else { $Computer }
            Write-Host "Evaluating chronological backup retention for '$NormalizedHost'..." -ForegroundColor Cyan
            
            # Identify all localized storage instances matching system structures
            $HostPath = Join-Path $BasePath -ChildPath $NormalizedHost
            $BackupFolders = @(Get-ChildItem -Path $HostPath -Directory -Filter * | Sort-Object Name -Descending)

            if ($BackupFolders.Count -eq 0) {
                Write-Host "No active backup volumes discovered for '$NormalizedHost'." -ForegroundColor Gray
                continue
            }

            Write-Host "Discovered $($BackupFolders.Count) historical backup package(s) for '$NormalizedHost'." -ForegroundColor Gray
            $ExpirationCutoff = (Get-Date).AddDays(-$AgeThresholdDays)

            # Safety Threshold Constraint: Loop starts at Index 1 ($BackupFolders[0] is the absolute newest and always preserved)
            for ($i = 1; $i -lt $BackupFolders.Count; $i++) {
                $Folder = $BackupFolders[$i]
                [bool]$IsExpired = $false
                
                # Attempt string-parsing extraction of the embedded backup timestamp for evaluation accuracy
                if ($Folder.Name -match '(\d{4}-\d{2}-\d{2})$') {
                    try {
                        $ParsedDate = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
                        if ($ParsedDate -lt $ExpirationCutoff) { $IsExpired = $true }
                    } catch {
                        if ($Folder.LastWriteTime -lt $ExpirationCutoff) { $IsExpired = $true }
                    }
                } else {
                    if ($Folder.LastWriteTime -lt $ExpirationCutoff) { $IsExpired = $true }
                }

                if ($IsExpired) {
                    Write-Host "Pruning expired system image volume: $($Folder.FullName) [Exceeds $AgeThresholdDays Days]" -ForegroundColor Yellow
                    try {
                        Remove-Item -Path $Folder.FullName -Recurse -Force -ErrorAction Stop
                        Write-Host "Successfully removed expired archive collection '$($Folder.Name)'." -ForegroundColor Green
                    } catch {
                        Write-Error "Administrative execution fault while removing expired container $($Folder.FullName): $_"
                    }
                }
            }
            Write-Host "Retention analysis complete for '$NormalizedHost'. Master recovery point verification preserved: $($BackupFolders[0].Name)" -ForegroundColor Gray
        }
    }
}

function Invoke-SystemBackup {
    <#
    .SYNOPSIS
        Executes block-level Windows Image Backup tasks targeting partitioned destination directories.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$Hosts,

        [Parameter(Mandatory = $false)]
        [string]$IncludeDrives
    )
    begin {}
    process {
        Set-BackupTarget
        Write-Host "Centralized storage root initialized: $Global:BackupTarget" -ForegroundColor Yellow
        if ([string]::IsNullOrWhiteSpace($IncludeDrives)) {
            Write-Host "Enter drive letters to back up (comma-separated, e.g., C,D), or press Enter for ALL fixed drives:" -ForegroundColor Cyan
            [string]$DriveInput = (Read-Host).Trim()
            if (-not [string]::IsNullOrWhiteSpace($DriveInput)) {
                $IncludeDrives = $DriveInput -split "," | ForEach-Object { $_.Trim().ToUpper().Replace(":", "") } | Where-Object { $_ -ne "" }
            }
        } else {
            $IncludeDrives = $IncludeDrives | ForEach-Object { $_.Trim().ToUpper().Replace(":", "") } | Where-Object { $_ -ne "" }
        }
        foreach ($Computer in $Hosts) {
            try {
                [string]$NormalizedHost = if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) { $env:COMPUTERNAME } else { $Computer }

                # Verify Windows Server Backup is installed on the specific target host prior to execution
                if (-not (Test-WindowsBackupInstalled -ComputerName $NormalizedHost)) {
                    Write-Error -Message "Windows Server Backup is missing or installation was skipped on '$NormalizedHost'. Skipping backup cycle."
                    continue
                }

                # Zero-trust folder separation
                [PSCustomObject]$FolderStatus = Initialize-BackupSubfolder -BasePath $Global:BackupTarget -TargetHost $NormalizedHost
                    [string]$CurrentTimestamp = (Get-Date -Format "yyyy-MM-dd")
                    [string]$HostFolderUNC = ""
                    $HostFolderUNC = Join-Path -Path $Global:BackupTarget -ChildPath $NormalizedHost
                    $null = New-Item -ItemType Directory -Path $HostFolderUNC -Force -ErrorAction Stop
                    $HostFolderUNC = Join-Path -Path $HostFolderUNC -ChildPath $CurrentTimestamp
                    $null = New-Item -ItemType Directory -Path $HostFolderUNC -Force -ErrorAction Stop
                if (-not $FolderStatus.Success) {
                    Write-Error -Message "Subfolder architecture error. Aborting backup cycle iteration for '$NormalizedHost'."
                    Continue
                }
                if ($Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
                    [string]$DriveString = ""
                    if (@($IncludeDrives).Length -eq 0) {
                        [string[]]$LocalFixedDrives = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop).DeviceID
                        $DriveString = $LocalFixedDrives -join ","
                    } else {
                        $DriveString = ($IncludeDrives | ForEach-Object { "$($_):" }) -join ","
                    }
                    Write-Host "Initiating local backup targeting storage path '$HostFolderUNC' [Drives: $DriveString]..." -ForegroundColor Cyan
                    [string]$BackupCommand = "wbadmin start backup -backupTarget:$HostFolderUNC -include:$DriveString -allCritical -vssFull -quiet"
                    Invoke-Expression -Command $BackupCommand
                } else {
                    Write-Host "Dispatching network hot-backup on $Computer targeting remote repository folder '$HostFolderUNC'..." -ForegroundColor Cyan
                    
                    # Execute script block wrapping wbadmin in an ephemeral scheduled task to bypass Double-Hop WinRM restrictions
                    $RemoteResult = Invoke-Command -ComputerName $Computer -ScriptBlock {
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
                        $Guid = [Guid]::NewGuid().Guid
                        $TaskName = "TempBackupTask_$Guid"
                        $LogPath = "C:\Windows\Temp\WindowsImageBackup_$Guid.log"
                        $WbadminCmd = "wbadmin start backup -backupTarget:`"$TargetFolder`" -include:$RemoteDriveString -allCritical -vssFull -quiet > `"$LogPath`" 2>&1"
                        
                        # Provision Scheduled Task as NT AUTHORITY\SYSTEM
                        $Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $WbadminCmd"
                        $Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
                        $null = Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -ErrorAction Stop
                        $null = Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
                        do {
                            Start-Sleep -Seconds 5
                            $CurrentState = Get-ScheduledTask -TaskName $TaskName
                        } while ($CurrentState.State -eq 'Running' -or $CurrentState.State -eq 'Queued')
                        
                        # Cleanup
                        $null = Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
                        $BackupSuccess = $false
                        $LogContent = "Log file execution mapping not generated."
                        if (Test-Path -Path $LogPath) {
                            $LogContent = Get-Content -Path $LogPath -Raw
                            if (Select-String -Path $LogPath -Pattern "The backup operation successfully completed" -Quiet) {
                                $BackupSuccess = $true
                            }
                        }
                        [PSCustomObject]@{
                            Success    = $BackupSuccess
                            LogContent = $LogContent
                            LogPath    = $LogPath
                        }
                    } -ArgumentList $HostFolderUNC, $IncludeDrives -ErrorAction Stop

                    # Evaluate structured output metrics dispatched from the remote runtime engine
                    if ($RemoteResult.Success) {
                        Write-Host "Remote backup operation completed successfully on $Computer." -ForegroundColor Green
                    } else {
                        Write-Error -Message "Backup failed on remote target $Computer. Log details: `n$($RemoteResult.LogContent)"
                    }
                }
            } catch {
                Write-Error -Message "Failed to execute centralized backup routine on host '$Computer': $_"
            }
        }
    }
    end {}
}

# Verify States
[bool]$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning -Message "This script requires administrative privileges to run Disk Cleanup and wbadmin."
    Write-Warning -Message "Please relaunch PowerShell as an Administrator."
    Exit
}
Test-WindowsBackupInstalled -ComputerName $env:COMPUTERNAME

# Check and set variables
$Hosts = Initialize-HostList -TargetHosts $Hosts
$Global:BackupTarget = $BackupTarget

# MENU INTERFACE
[string]$Selection = ""
do {
    Write-Host "==============================================================" -ForegroundColor Gray
    Write-Host "                        SYSTEM BACKUP MENU                    " -ForegroundColor White
    Write-Host "==============================================================" -ForegroundColor Gray
    Write-Host "1. ONLY Run Disk Cleanup"
    Write-Host "2. ONLY Backup Systems"
    Write-Host "3. ONLY Cleanup Old Backups"
    Write-Host "4. Backup Systems, then Cleanup Old Backups"
    Write-Host "5. Run Disk Cleanup, Backup Systems, then Cleanup Old Backups"
    Write-Host "Q. Exit"
    Write-Host "--------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "Target Hosts     : $((($Hosts | Sort-Object | Get-Unique) -join ", "))"
    Write-Host "Retention Policy : $RetentionDays Days (Will always protect at least 1 backup)"
    Write-Host ""
    $Selection = (Read-Host "Select an option").ToString().ToLower().Trim()
    
    switch ($Selection) {
        "1" { Invoke-DiskCleanup -Hosts $Hosts }
        "2" { Invoke-SystemBackup -Hosts $Hosts -IncludeDrives $IncludeDrives }
        "3" { Remove-OldBackups -Hosts $Hosts -BasePath $Global:BackupTarget -AgeThresholdDays $RetentionDays }
        "4" { 
                Invoke-SystemBackup -Hosts $Hosts -IncludeDrives $IncludeDrives
                Remove-OldBackups -Hosts $Hosts -BasePath $Global:BackupTarget -AgeThresholdDays $RetentionDays
            }
        "5" {
                Invoke-DiskCleanup -Hosts $Hosts
                Invoke-SystemBackup -Hosts $Hosts -IncludeDrives $IncludeDrives
                Remove-OldBackups -Hosts $Hosts -BasePath $Global:BackupTarget -AgeThresholdDays $RetentionDays
           }
        "q" { Write-Host "`nExiting utility..." -ForegroundColor Yellow; Break }
        default { Write-Host "`nInvalid selection. Please choose an option." -ForegroundColor Red }
    }
    Write-Host ""
} while ($Selection -ne "q")