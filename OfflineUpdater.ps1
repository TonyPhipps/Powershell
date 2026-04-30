<#
.SYNOPSIS
    A management wrapper for Defender updates and the kbupdate module to facilitate offline Windows patching.

.DESCRIPTION
    This script automates the end-to-end process of offline updating. It bundles the 
    necessary PowerShell modules and the Microsoft servicing stack (wsusscn2.cab), scans Active Directory 
    endpoints for missing KBs, download required updates from the Microsoft Catalog 
    on an internet-connected host, and deploys them to target endpoints in an air-gapped
    environment. Below is the general approach and commands without optional file/folder redirects.

    Step 1: Prepare the package on an Internet-attached network. Copy the OfflineUpdater folder and script to the offline network.
        .\OfflineUpdater.ps1 -PreparePackage
    Step 2: Install the modules on the offline network.
        .\OfflineUpdater.ps1 -Install
    Step 3: Scan the Windows hosts on the offline network. Copy the MissingKBs.txt scan results to the online network.
        .\OfflineUpdater.ps1 -Scan
    Step 4: Download missing updates on Internet-attached network. Copy the repository folder to the offline network.
        .\OfflineUpdater.ps1 -DownloadUpdates
    Step 5: Deploy the updates on the offline network.
        .\OfflineUpdater.ps1 -Deploy

.PARAMETER WorkingFolder
    The root directory for script operations. Defaults to a 'OfflineUpdater' folder in the script directory.

.PARAMETER Modules
    Path to the directory containing the kbupdate module and dependencies. Defaults to \modules\ subirectory of WorkingFolder.

.PARAMETER Catalog
    Path where the wsusscn2.cab (Offline Scan File) is stored or will be downloaded. Defaults to \catalog\ of WorkingFolder.

.PARAMETER Computers
    Path to file used to store list of hosts to scan. Defaults to \scan\hosts.txt within WorkingFolder. A list is also accepted directly.

.PARAMETER Repository
    The local repository where .msu/.cab update files are downloaded and stored. Defaults to \repository\ subirectory of WorkingFolder.

.PARAMETER Results
    Directory where compliance reports and missing KB lists are exported. Defaults to \scanresults\ subirectory of WorkingFolder.

.PARAMETER PreparePackage
    Switch to download the needed modules and the latest wsusscn2.cab.

.PARAMETER Install
    Switch to install the kbupdate module from the local WorkingFolder to the system module path.

.PARAMETER Scan
    Switch to query Active Directory for computers and perform a remote compliance scan.

.PARAMETER DownloadUpdates
    Switch to read the 'MissingKBs.txt' list and download the actual update files from Microsoft.

.PARAMETER DeployUpdates
    Switch to push and install the downloaded updates from the RepoFolder to the target endpoints.

.PARAMETER DeployUpdatesLocal
    Switch to push and install the downloaded updates from the RepoFolder to the LOCAL endpoint.

.PARAMETER SkipReport
    If set, the script will not automatically open the CSV scan results in Out-GridView.

.PARAMETER DefenderOnly
    Only download/deploy Defender signature and engine updates, skipping all KB deployments. 
    To be used in conjunction with -DownloadUpdates and/or -DeployUpdates.

.EXAMPLE
    .\OfflineUpdater.ps1 -PreparePackage
    Downloads all necessary tools and the ~1GB scan catalog to prepare for an offline site visit.

.EXAMPLE
    .\OfflineUpdater.ps1 -Scan -WorkingFolder "D:\OfflineUpdater"
    Scans AD computers and generates a report of what is missing using the specified working directory.

.EXAMPLE
    To install locally (for hosts that had remote issues), log into that machine interactively, then:
    Create a local copy at c:\offlineupdater.ps1 and the OfflineUpdater\catalog\wsusscn2.cab file, then run
    C:\OfflineUpdater.ps1 -Install -WorkingFolder \\otherpc\c$\OfflineUpdater
    C:\OfflineUpdater.ps1 -Scan -SkipAD
    C:\OfflineUpdater.ps1 -DeployLocal -Repository \\otherpc\c$\OfflineUpdater\repository

.NOTES
    Manual Fallbacks are provided below for when kbupdate fails repeatedly on the last few remaining patches.
        wusa.exe "C:\Path\To\Your\Patch\Windows11.0-KB50XXXXX-x64.msu" /norestart
        Dism /Online /Add-Package /PackagePath:"C:\Path\To\Your\windows10.0-kb5066139-x64-ndp48...cab"

.NOTES
    File Name      : OfflineUpdater.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges, RSAT (for -Scan)
    Version        : 1.0
    Date           : April 17, 2026
    Copyright      : (c) 2026 Tony Phipps under the MIT License

.LINK
    https://github.com/potatoqualitee/kbupdate
    https://github.com/TonyPhipps/Powershell
    https://opensource.org/licenses/MIT
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [alias("w", "Working")]
    [string]$WorkingFolder,

    [Parameter(Mandatory = $false)]
    [alias("M", "Mod")]
    [string]$Modules,

    [Parameter(Mandatory = $false)]
    [alias("C", "cab")]
    [string]$Catalog,

    [Parameter(Mandatory = $false)]
    [alias("R", "Repo")]
    [string]$Repository,

    [Parameter(Mandatory = $false)]
    [alias("O", "Output")]
    [string]$Results,

    [Parameter(Mandatory = $false)]
    [alias("H", "Hosts", "Host", "Computer")]
    [string[]]$Computers,

    [Parameter(Mandatory = $false)]
    [alias("P", "Prepare", "Package", "Update", "UpdatePackage")]
    [switch]$PreparePackage,

    [Parameter(Mandatory = $false)]
    [alias("I")]
    [switch]$Install,

    [Parameter(Mandatory = $false)]
    [alias("S")]
    [switch]$Scan,

    [Parameter(Mandatory = $false)]
    [alias("D", "Download", "DownloadUpdate")]
    [switch]$DownloadUpdates,

    [Parameter(Mandatory = $false)] 
    [alias("Defender")]
    [switch]$DefenderOnly,

    [Parameter(Mandatory = $false)]
    [alias("Deploy", "DeployUpdate", "Push")]
    [switch]$DeployUpdates,

    [Parameter(Mandatory = $false)]
    [alias("DeployLocal", "DeployUpdateLocal", "UpdateLocal")]
    [switch]$DeployUpdatesLocal,

    [Parameter(Mandatory = $false)]
    [alias("NoReport")]
    [switch]$SkipReport,

    [Parameter(Mandatory = $false)]
    [alias("NoAD")]
    [switch]$SkipAD
)

if (-not $WorkingFolder) {
    $CurrentScriptPath = $MyInvocation.MyCommand.Path
    if (-not $CurrentScriptPath) {
        $CurrentScriptPath = if ($psISE) { $psISE.CurrentFile.FullPath } else { $PSCommandPath }
    }
    $ScriptRoot = Split-Path -Path $CurrentScriptPath -Parent
    $LocalUpdaterPath = Join-Path -Path $ScriptRoot -ChildPath "OfflineUpdater"
    if (Test-Path -Path $LocalUpdaterPath) {
        $WorkingFolder = $LocalUpdaterPath
    } 
    else {
        $DiskD = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = 'D:' and DriveType = 3"
        if ($DiskD) {
            $WorkingFolder = "D:\OfflineUpdater"
        } 
        else {
            $WorkingFolder = "C:\OfflineUpdater"
        }
    }
}
if (-not $Modules)    { $Modules = Join-Path -Path $WorkingFolder -ChildPath "modules" }
if (-not $Repository) { $Repository = Join-Path -Path $WorkingFolder -ChildPath "repository" }
if (-not $Results)    { $Results = Join-Path -Path $WorkingFolder -ChildPath "ScanResults" }
if (-not $Catalog)    { $Catalog = Join-Path -Path $WorkingFolder -ChildPath "catalog\wsusscn2.cab" }
if (-not $Computers -and -not $SkipAD) { $Computers = Join-Path -Path $WorkingFolder -ChildPath "scan\hosts.txt" }
if ($Computers.Count -eq 1 -and (Test-Path -Path $Computers[0] -PathType Leaf)) 
    { $TargetEndpoints = Get-Content -Path $Computers[0] 
} else { $TargetEndpoints = $Computers }

# --- 0. INTERACTIVE MENU (FOR NON-PS USERS) ---
$NoActionSelected = -not ($PreparePackage -or $Install -or $Scan -or $DownloadUpdates -or $DeployUpdates -or $DeployUpdatesLocal)
if ($NoActionSelected) {
    do {
        Clear-Host
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "               OFFLINE WINDOWS UPDATER - MAIN MENU              " -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host " 1) -Prepare Package       (Run on INTERNET-CONNECTED computer) "
        Write-Host " 2) -Install Modules       (Run on AIR-GAPPED computer)"
        Write-Host " 3) -Scan Endpoints        (Run on AIR-GAPPED computer)"
        Write-Host " 4) -Download Updates      (Run on INTERNET-CONNECTED computer) "
        Write-Host " 5) -Deploy Updates        (Run on AIR-GAPPED computer)"
        Write-Host " 6) -DeployLocal Updates   (Run on AIR-GAPPED computer)"
        # TODO: Add 7 for DefenderOnly
        Write-Host " Q) Quit"
        Write-Host "================================================================" -ForegroundColor Cyan
        $Choice = Read-Host "Select an option (1-6 or Q)"
        switch ($Choice) {
            "1" { $PreparePackage = $true;       $Continue = $false }
            "2" { $Install = $true;              $Continue = $false }
            "3" { $Scan = $true;                 $Continue = $false }
            "4" { $DownloadUpdates = $true;      $Continue = $false }
            "5" { $DeployUpdates = $true;        $Continue = $false }
            "6" { $DeployUpdatesLocal = $true;   $Continue = $false }
            "Q" { exit }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1; $Continue = $true }
        }
    } while ($Continue)
}

# --- HELPER FUNCTIONS ---
function Get-TargetComputers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Computers,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipAD
    )

    if ($Computers.Count -eq 1 -and (Test-Path -Path $Computers[0] -PathType Leaf)) {
        $List = (Import-csv -Path $Computers -Header Host | Select-Object Host -ExpandProperty Host)
    } else {
        $List = $Computers
    }
    if (-not $SkipAD -and ($Computers.Count -eq 1)) {
        $isInstalled = (Get-WindowsFeature -Name RSAT-ADDS-Tools -ErrorAction SilentlyContinue).Installed
        if ($isInstalled) {
            Write-Host "RSAT: Active Directory Users and Computers is installed. Gathering enabled Windows hosts..." -ForegroundColor Gray
            $ADHosts = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows*'} | Select-Object -ExpandProperty Name
            if ($ADHosts) {
                New-Item -ItemType Directory -Path (Join-Path -Path $WorkingFolder -ChildPath "scan") -Force
                $ADHosts | Out-File -FilePath $Computers[0] -Force
                return $ADHosts
            }
        } else {
            Write-Warning "RSAT: Active Directory Tools are NOT installed. Falling back to local host list."
        }
    }
    return $List
}

function Invoke-UpdateDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$Url,
        [Parameter(Mandatory = $true)] [string]$DestinationPath,
        [Parameter(Mandatory = $false)] [switch]$CheckExpiration
    )
    $FileName = Split-Path $Url -Leaf
    $FullDestination = if (Test-Path $DestinationPath -PathType Container) { 
        Join-Path $DestinationPath $FileName 
    } else { 
        $DestinationPath 
    }
    if ($CheckExpiration -and (Test-Path $FullDestination)) {
        $LastModified = (Get-Item $FullDestination).LastWriteTime
        if ($LastModified -ge (Get-Date).AddDays(-1)) {
            Write-Host "[o] $FileName is current (Updated: $($LastModified.ToString('MM/dd HH:mm')))." -ForegroundColor Gray
            return
        }
    }
    if (-not $CheckExpiration -and (Test-Path $FullDestination)) {
        Write-Host "SKIPPING: $FileName (Already exists.)" -ForegroundColor Gray
        return
    }
    $ParentDir = Split-Path $FullDestination -Parent
    if (-not (Test-Path $ParentDir)) {
        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }
    try {
        $StatusMsg = if ($CheckExpiration) { "Refreshing $FileName..." } else { "Downloading $FileName..." }
        Write-Host "$StatusMsg " -ForegroundColor Cyan -NoNewline
        Invoke-WebRequest -Uri $Url -OutFile $FullDestination -UseBasicParsing
        Write-Host "[Success]" -ForegroundColor Green
    }
    catch {
        Write-Host "[FAILED]" -ForegroundColor Red
        Write-Warning "Error: $($_.Exception.Message)"
    }
}

function Get-DefenderUpdates {
    [CmdletBinding()]
    param([string]$DefenderUpdatesPath)
    Write-Host "--- Operation: Download Defender Definitions ---" -ForegroundColor Gray
    if (-not (Test-Path $DefenderUpdatesPath)) { New-Item -Path $DefenderUpdatesPath -ItemType Directory | Out-Null }
    $ArchFolders = @{ 
        "x64" = "https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64"
        "x86" = "https://go.microsoft.com/fwlink/?LinkID=121721&arch=x86"
    }
    foreach ($Arch in $ArchFolders.Keys) {
        $TargetFolder = Join-Path $DefenderUpdatesPath $Arch
        if (-not (Test-Path $TargetFolder)) { New-Item -Path $TargetFolder -ItemType Directory | Out-Null }
        $Destination = Join-Path $TargetFolder "mpam-fe.exe"
        Invoke-UpdateDownload -Url $ArchFolders[$Arch] -Destination $Destination -CheckExpiration
    }
    Write-Host "Checking for latest Defender Platform Update..." -ForegroundColor Gray
    $CurrentFiles = Get-Item -Path "$DefenderUpdatesPath\updateplatform*" -ErrorAction SilentlyContinue 
    if ($CurrentFiles) {
        $OldestFile = $CurrentFiles | Sort-Object LastWriteTime | Select-Object -First 1
        if ($OldestFile.LastWriteTime -lt (Get-Date).AddDays(-1)) {
            Write-Host "[!] Platform updates are outdated. Cleaning up old files..." -ForegroundColor Yellow
            Remove-Item -Path "$DefenderUpdatesPath\updateplatform*" -Force -ErrorAction SilentlyContinue
        }
    }
    $PlatformUpdate = Get-KbUpdate -KB 4052623 | Sort-Object LastModified -Descending | Select-Object -First 1
    foreach ($link in $PlatformUpdate.Link) {
        $FileName = Split-Path $link -Leaf
        $Destination = Join-Path $DefenderUpdatesPath $FileName
        Invoke-UpdateDownload -Url $link -Destination $Destination -CheckExpiration
    }
}

function Install-DefenderUpdates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string[]]$TargetEndpoints,
        [Parameter(Mandatory = $true)] [string]$DefenderUpdatesPath,
        [string]$ShareName = "DefenderUpdates"
    )
    Write-Host "--- Operation: Deploying Defender Platform & Signatures ---" -ForegroundColor Gray
    $RepoManifest = @{}
    $PlatformFiles = Get-ChildItem -Path $DefenderUpdatesPath -Filter "updateplatform*.exe"
    foreach ($File in $PlatformFiles) {
        $Arch = if ($File.Name -match "amd64") { "x64" } elseif ($File.Name -match "x86") { "x86" } else { "arm64" }
        $RepoManifest[$Arch] = @{
            LocalPath = $File.FullName
            FileName  = $File.Name
            Version   = [version]$File.VersionInfo.FileVersion
        }
    }
    if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $ShareName -Path $DefenderUpdatesPath -ReadAccess "Domain Computers", "Authenticated Users" -FullAccess "Administrators" | Out-Null
    }
    $UncPath = "\\$($env:COMPUTERNAME)\$ShareName"
    foreach ($Computer in $TargetEndpoints) {
        Write-Host "Defender Update Target: $($Computer)" -ForegroundColor Cyan
        $Session = $null
        try {
            $Session = New-PSSession -ComputerName $Computer -ErrorAction Stop
            $RemoteStatus = Invoke-Command -Session $Session -ScriptBlock {
                $OSArch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
                $ArchKey = if ($OSArch -match "64-bit") { "x64" } elseif ($OSArch -match "arm") { "arm64" } else { "x86" }
                $ActiveAV = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue | 
                            Where-Object { $_.productState -in 262144, 266240, 393216, 397312 }
                if ($ActiveAV -and $ActiveAV.displayName -notmatch "Windows Defender") {
                    return @{ Skip = $true; Reason = "Third-party AV ($($ActiveAV.displayName)) active."; ArchKey = $ArchKey }
                }
                try {
                    $Status = Get-MpComputerStatus -ErrorAction Stop
                    return @{
                        Skip         = $false
                        PlatformVer  = [version]$Status.AMProductVersion
                        EngineVer    = $Status.AMEngineVersion
                        SignatureVer = $Status.AntivirusSignatureVersion
                        ArchKey      = $ArchKey
                    }
                } catch {
                    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
                    $RegPlat = Get-ItemProperty -Path $RegPath -Name "ProductAppDataPath" -ErrorAction SilentlyContinue
                    $CurrentPlat = if ($RegPlat.ProductAppDataPath -match 'Platform\\([\d\.]+)') { [version]$Matches[1] } else { [version]"0.0.0.0" }
                    $SigVer = (Get-ItemProperty -Path "$RegPath\Signature Updates" -Name "ASSignatureVersion" -ErrorAction SilentlyContinue).ASSignatureVersion
                    return @{ 
                        Skip = $false; PlatformVer = $CurrentPlat; 
                        EngineVer = "Stopped"; SignatureVer = if ($SigVer) { $SigVer } else { "None" }; ArchKey = $ArchKey 
                    }
                }
            }
            if ($RemoteStatus.Skip) {
                Write-Host "SKIPPING: $($Computer) - $($RemoteStatus.Reason)" -ForegroundColor Yellow
                continue
            }
            $Match = $RepoManifest[$RemoteStatus.ArchKey]
            $PlatformWasUpdated = $false
            if ($Match -and ($RemoteStatus.PlatformVer -lt $Match.Version)) {
                Write-Host "Updating Platform: $($RemoteStatus.PlatformVer) -> $($Match.Version)" -ForegroundColor Cyan
                $StagingPath = "C:\Windows\Temp\$($Match.FileName)"
                Copy-Item -Path $Match.LocalPath -Destination $StagingPath -ToSession $Session -Force
                Invoke-Command -Session $Session -ArgumentList $StagingPath -ScriptBlock {
                    param($InstallerPath)
                    Start-Process -FilePath $InstallerPath -ArgumentList "/quiet", "/norestart" -Wait
                    Remove-Item -Path $InstallerPath -Force
                }
                $PlatformWasUpdated = $true
            }
            Invoke-Command -Session $Session -ScriptBlock {
                $Svc = Get-Service WinDefend -ErrorAction SilentlyContinue
                if ($Svc -and $Svc.Status -ne 'Running') {
                    Set-Service -Name WinDefend -StartupType Automatic
                    Start-Service -Name WinDefend -ErrorAction SilentlyContinue
                }
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            }
            Invoke-Command -Session $Session -ArgumentList $UncPath -ScriptBlock {
                param($Path)
                try {
                    Set-MpPreference -SignatureDefinitionUpdateFileSharesSources $Path
                    Update-MpSignature -UpdateSource FileShares -ErrorAction Stop
                } catch { }
            }
            $FinalReport = Invoke-Command -Session $Session -ScriptBlock {
                $Retry = 0
                while ($Retry -lt 5) {
                    $Stat = Get-MpComputerStatus -ErrorAction SilentlyContinue
                    if ($Stat) { return $Stat | Select-Object AMEngineVersion, AntivirusSignatureVersion }
                    Start-Sleep -Seconds 2
                    $Retry++
                }
            }
            if ($FinalReport) {
                $EngineOut = if ($RemoteStatus.EngineVer -ne $FinalReport.AMEngineVersion) { "$($RemoteStatus.EngineVer) -> $($FinalReport.AMEngineVersion)" } else { "$($FinalReport.AMEngineVersion) (Current)" }
                $SigOut    = if ($RemoteStatus.SignatureVer -ne $FinalReport.AntivirusSignatureVersion) { "$($RemoteStatus.SignatureVer) -> $($FinalReport.AntivirusSignatureVersion)" } else { "$($FinalReport.AntivirusSignatureVersion) (Current)" }
                Write-Host "Deployment Results:" -ForegroundColor Green
                Write-Host "- Engine: $EngineOut" -ForegroundColor Green
                Write-Host "- Signatures: $SigOut" -ForegroundColor Green
                if ($PlatformWasUpdated) {
                    Write-Host "Platform updated to $($Match.Version). REBOOT REQUIRED to complete." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Defender updated, but WMI is unresponsive. Reboot recommended." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            if ($Session) { Remove-PSSession $Session }
        }
    }
}

function Get-RebootStatus {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$ComputerNames = $env:COMPUTERNAME
    )
    $RebootCheckBlock = {
        $Status = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            NeedsReboot  = $false
            Trigger      = "None"
        }
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
            $Status.NeedsReboot = $true
            $Status.Trigger = "Component Based Servicing"
        }
        elseif (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
            $Status.NeedsReboot = $true
            $Status.Trigger = "Windows Update Agent"
        }
        else {
            $Rename = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
            if ($Rename.PendingFileRenameOperations) {
                $Status.NeedsReboot = $true
                $Status.Trigger = "Pending File Rename"
            }
        }
        return $Status
    }
    Write-Host "--- Validating Reboot Status ---" -ForegroundColor Gray
    foreach ($Computer in $ComputerNames) {
        try {
            $Result = if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq "localhost") {
                & $RebootCheckBlock
            }
            else {
                Invoke-Command -ComputerName $Computer -ScriptBlock $RebootCheckBlock -ErrorAction Stop
            }
            if ($Result.NeedsReboot) {
                Write-Host "[!] $($Result.ComputerName): REBOOT REQUIRED ($($Result.Trigger))" -ForegroundColor Yellow
            }
            else {
                Write-Host "[o] $($Result.ComputerName): No reboot pending." -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "[X] $($Computer): Connection Failed." -ForegroundColor Red
        }
    }
}

function Remove-TempFiles {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$ComputerNames = $env:COMPUTERNAME,

        [Parameter()]
        [string]$CustomStagingPath = (Join-Path $Home "Downloads")
    )
    $CleanupBlock = {
        param($TargetPath)
        $Results = [System.Collections.Generic.List[string]]::new()
        if (Test-Path $TargetPath) {
            $PatchFiles = Get-ChildItem -Path $TargetPath -Include *.msu, *.cab, *.exe -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { 
                    $_.Name -match "KB\d{6,}" -or 
                    $_.Name -match "aspnetcore|dotnet|vcredist|windowsdesktop-runtime" 
                }
            foreach ($File in $PatchFiles) {
                try {
                    Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                    $Results.Add("Successfully removed: $($File.Name)")
                } catch {
                    $Results.Add("FAILED to remove $($File.Name): $($_.Exception.Message)")
                }
            }
        }
        return [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Logs         = $Results
            FoundFiles   = ($PatchFiles.Count -gt 0)
        }
    }
    Write-Host "--- Initiating Patch Cleanup ---" -ForegroundColor Cyan
    foreach ($Computer in $ComputerNames) {
        Write-Host "Checking $Computer..." -ForegroundColor Gray
        try {
            $Output = if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq "localhost") {
                & $CleanupBlock -TargetPath $CustomStagingPath
            }
            else {
                Invoke-Command -ComputerName $Computer -ScriptBlock $CleanupBlock -ArgumentList $CustomStagingPath -ErrorAction Stop
            }
            if ($Output.FoundFiles) {
                foreach ($LogEntry in $Output.Logs) {
                    $Color = if ($LogEntry -match "FAILED") { "Red" } else { "Gray" }
                    Write-Host "[!] $LogEntry" -ForegroundColor $Color
                }
            } else {
                Write-Host "No temporary patch files found." -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Host "$($Computer): Connection Failed." -ForegroundColor Red
        }
    }
}

# --- 2. PREPARE PACKAGE (OFFLINE ASSETS) ---
if ($PreparePackage) {
    Write-Host "--- Operation: Prepare Package ---" -ForegroundColor Gray
    try {
        Install-PackageProvider -Name NuGet -Scope CurrentUser -ErrorAction SilentlyContinue
        if (-not (Test-Path $WorkingFolder)) { New-Item -ItemType Directory -Path $WorkingFolder -Force | Out-Null }
        if (-not (Test-Path $Modules)) { New-Item -ItemType Directory -Path $Modules -Force | Out-Null }
        $CatalogDir = Split-Path -Path $Catalog -Parent
        if (-not (Test-Path -Path $CatalogDir)) { New-Item -ItemType Directory -Path $CatalogDir -Force | Out-Null }
        Write-Host "Saving module to $Modules..." -ForegroundColor Gray
        Save-Module -Name kbupdate -Path $Modules -ErrorAction Stop -Verbose
        Save-Module -Name xWindowsUpdate -Path $Modules -ErrorAction Stop -Verbose
        Get-ChildItem -Path $WorkingFolder -Recurse | Unblock-File
        Invoke-UpdateDownload -Url "https://go.microsoft.com/fwlink/?linkid=74689" -DestinationPath $Catalog -CheckExpiration
        Write-Host "Success! Package ready at: $WorkingFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "Preparation failed: $($_.Exception.Message)"
    }
}

# --- 1. INSTALL MODULE ---
if ($Install) {
    Write-Host "--- Operation: Install ---" -ForegroundColor Gray
    $PowerShellModules = "C:\Program Files\WindowsPowerShell\Modules"
    if (-not (Test-Path $PowerShellModules)) {
        New-Item -ItemType Directory -Path $PowerShellModules -Force | Out-Null
    }
    Write-Host "Installing kbupdate and dependencies to $PowerShellModules..." -ForegroundColor Gray
    $ModuleFolders = Get-ChildItem -Path $Modules -Directory
    foreach ($Folder in $ModuleFolders) {
        $Dest = Join-Path $PowerShellModules $Folder.Name
        Copy-Item -Path $Folder.FullName -Destination $Dest -Recurse -Force
    }
    Write-Host "Verifying installation..." -ForegroundColor Gray
    if (Get-Command -Module kbupdate) {
        Write-Host "SUCCESS: kbupdate is ready for use." -ForegroundColor Green
    } else {
        Write-Error "Module could not be loaded. Check Execution Policy."
    }
}

# --- Module Validation Check ---
$InstallRequired = $Scan, $DownloadUpdates, $DeployUpdates
if ($InstallRequired -contains $true) {
    if (-not (Get-Module -ListAvailable -Name kbupdate)) {
        Install-Module kbupdate -Force -Scope CurrentUser
        Install-Module xWindowsUpdate -Force -Scope CurrentUser
    }
}

# --- 3. SCAN ENDPOINTS ---
if ($Scan) {
    Write-Host "--- Operation: Scan ---" -ForegroundColor Gray
    if (-not (Test-Path $Results)) {
        New-Item -ItemType Directory -Path $Results -Force | Out-Null
    }
    if ($SkipAD -and ($null -eq $Computers -or $Computers -eq "")) {
        $TargetEndpoints = $env:COMPUTERNAME
        Write-Host "SkipAD detected with no target list. Defaulting to local scan: $TargetEndpoints" -ForegroundColor Cyan
    } else {
        $TargetEndpoints = Get-TargetComputers -Computers $Computers -SkipAD:$SkipAD
    }
    if (-not $TargetEndpoints) {
        Write-Error "No target computers found to scan."
        return
    }
    $ScanResults = foreach ($Endpoint in $TargetEndpoints) {
        Get-KbNeededUpdate -ComputerName $Endpoint -ScanFilePath $Catalog -Force -Verbose
    }
    if ($ScanResults) {
        $ReportPath = Join-Path $Results -ChildPath "Full_Compliance_Report_$((Get-Date).ToString('yyyyMMdd_HHmm')).csv"
        $MissingKBsPath = Join-Path -Path $Results -ChildPath "MissingKBs_$((Get-Date).ToString('yyyyMMdd_HHmm')).txt"
        $ScanResults | Export-Csv -Path $ReportPath -NoTypeInformation
        $NewKBs = $ScanResults.KBUpdate | Where-Object { $_ } | Sort-Object -Unique
        $NewKBs | Out-File -FilePath $MissingKBsPath
        Write-Host "Scan complete. Detailed report saved to $ReportPath" -ForegroundColor Green
        Write-Host "Copy the ScanResults folder to your online host for downloading." -ForegroundColor Cyan
        if (-not $SkipReport) {
            Import-Csv -Path $ReportPath | Select-Object ComputerName, KBUpdate, Title, Description | Out-GridView
        }
    } else {
        Write-Host "No missing updates found." -ForegroundColor Gray
    }
}

# --- 4. DOWNLOAD UPDATES ---
if ($DownloadUpdates) {
    if ($DownloadUpdates -or $DefenderOnly) {
        $DefenderPath = Join-Path $WorkingFolder "DefenderUpdates"
        Get-DefenderUpdates -DefenderUpdatesPath $DefenderPath
    }
    if (-not $DefenderOnly){
        Write-Host "--- Checking wsusscn2.cab for age ---" -ForegroundColor Gray
        Invoke-UpdateDownload -Url "https://go.microsoft.com/fwlink/?linkid=74689" -DestinationPath $Catalog -CheckExpiration
        Write-Host "Starting Windows KB downloads..." -ForegroundColor Gray
        $LatestReport = Get-ChildItem -Path $Results -Filter "Full_Compliance_Report_*.csv" | 
            Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
        if (-not $LatestReport) {
            Write-Error "No Compliance Report found in $Results."
        } else {
            if (-not (Test-Path $Repository)) { New-Item -ItemType Directory -Path $Repository -Force | Out-Null }
            Write-Host "Loading results file: $($LatestReport.FullName)" -ForegroundColor Gray
            $NeededUpdates = Import-Csv -Path $LatestReport.FullName
            $AllLinks = $NeededUpdates.Link | ForEach-Object { $_ -split " " } | 
                Where-Object { $_ -like "http*" } | 
                    Select-Object -Unique
            Write-Host "Found $($AllLinks.Count) unique files to download based on scan results." -ForegroundColor Gray
            foreach ($Url in $AllLinks) {
                Invoke-UpdateDownload -Url $Url -DestinationPath $Repository
            }
        }
        Write-Host "Download complete. Total files in repository: $((Get-ChildItem $Repository).Count)" -ForegroundColor Green
    }
}

# --- 5. DEPLOY UPDATES ---
if ($DeployUpdates -and $DefenderOnly) {
    $DefenderPath = Join-Path $WorkingFolder "DefenderUpdates"
    $TargetEndpoints = Get-TargetComputers -Computers $Computers -SkipAD:$SkipAD
    Install-DefenderUpdates -TargetEndpoints $TargetEndpoints -DefenderUpdatesPath $DefenderPath
    if ($DeployUpdates -and (-not $DefenderOnly)) {
        Write-Host "Starting Windows KB deployment..." -ForegroundColor Gray
        $LatestReport = Get-ChildItem -Path $Results -Filter "Full_Compliance_Report_*.csv" | 
            Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
        if (-not $LatestReport) {
            Write-Error "Could not find a Compliance Report CSV in $Results. Run -Scan first."
        } elseif (-not (Test-Path $Repository)) {
            Write-Error "Repository folder not found at $Repository."
        } else {
            Write-Host "Loading deployment manifest: $($LatestReport.Name)" -ForegroundColor Gray
            $NeededUpdates = Import-Csv -Path $LatestReport.FullName
            if ($NeededUpdates.Count -eq 0) {
                Write-Host "Manifest is empty. No updates to deploy." -ForegroundColor Red
                return
            }
            $VerifiedUpdates = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($Update in $NeededUpdates) {
                $FileName = Split-Path -Leaf $Update.Link
                $LocalPath = Join-Path $Repository $FileName
                if (Test-Path $LocalPath) {
                    $VerifiedUpdates.Add($Update)
                } else {
                    Write-Host "SKIPPING: $($Update.KBUpdate) ($FileName) - File not found in Repository." -ForegroundColor Red
                }
            }
            if ($VerifiedUpdates.Count -gt 0) {
                Write-Host "Starting deployment of $($VerifiedUpdates.Count) verified files..." -ForegroundColor Gray
                $VerifiedUpdates | Install-KbUpdate -RepositoryPath $Repository -NoMultithreading -Verbose
                Write-Host "Deployment tasks completed." -ForegroundColor Green
            } else {
                Write-Warning "No matching update files found in $Repository. Nothing to deploy."
            }
        }
        Remove-TempFiles($TargetEndpoints)
        Get-RebootStatus($TargetEndpoints)
    }
}

# --- 6. DEPLOY LOCAL ---
if ($DeployUpdatesLocal) {
    Write-Host "--- Operation: Deploy Updates to Local Host ---" -ForegroundColor Gray
    $LatestReport = Get-ChildItem -Path $Results -Filter "Full_Compliance_Report_*.csv" | 
                    Sort-Object Name -Descending | 
                    Select-Object -First 1
    if (-not $LatestReport) {
        Write-Error "No compliance reports found in $Results."
        return
    }
    Write-Host "Analyzing latest report: $($LatestReport.Name)" -ForegroundColor Gray
    $LocalHost = $env:COMPUTERNAME
    $MissingUpdates = Import-Csv -Path $LatestReport.FullName | Where-Object { $_.ComputerName -eq $LocalHost }
    if ($null -eq $MissingUpdates) {
        Write-Host "No missing updates found for $LocalHost in this report." -ForegroundColor Gray
        return
    }
    foreach ($Update in $MissingUpdates) {
        $FileName = Split-Path -Leaf $Update.Link
        $LocalPath = Join-Path $Repository $FileName
        $KB = $Update.KBUpdate
        Write-Host "Targeting $KB ($FileName)..." -NoNewline -ForegroundColor Gray
        if (Test-Path $LocalPath) {
            Write-Host " Found." -ForegroundColor Green
            try {
                Unblock-File -Path $LocalPath -ErrorAction SilentlyContinue
                $env:SEE_MASK_NOZONECHECKS = 1
                if ($FileName -match "\.cab$") {
                    Write-Host "  -> Installing CAB via DISM..." -ForegroundColor Yellow
                    dism.exe /Online /Add-Package /PackagePath:"$LocalPath" /NoRestart
                }
                elseif ($FileName -match "\.exe$") {
                    Write-Host "  -> Running MSRT Tool..." -ForegroundColor Yellow
                    Start-Process -FilePath "$LocalPath" -ArgumentList "/quiet /norestart" -Wait
                }
                elseif ($FileName -match "\.msu$") {
                    Write-Host "  -> Installing via WUSA..." -ForegroundColor Yellow
                    Start-Process -FilePath "wusa.exe" -ArgumentList "`"$LocalPath`" /quiet /norestart" -Wait
                }
            }
            catch {
                Write-Warning "  [!] Error installing $KB. Check permissions."
            }
        }
        else {
            Write-Host " NOT FOUND in $Repository" -ForegroundColor Red
        }
    }
    Write-Host "--- Local Deployment Cycle Finished ---" -ForegroundColor Green
    Get-RebootStatus
    Remove-TempFiles
}

