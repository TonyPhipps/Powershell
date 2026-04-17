<#
.SYNOPSIS
    A management wrapper for Defender updates and the kbupdate module to facilitate offline Windows patching.

.DESCRIPTION
    This script automates the end-to-end process of offline updating. It bundles the 
    necessary PowerShell modules and the Microsoft servicing stack (wsusscn2.cab), scans Active Directory 
    endpoints for missing KBs, download required updates from the Microsoft Catalog 
    on an internet-connected host, and deploys them to target endpoints in an air-gapped
    environment. Below is the general approach and commands without optional file/folder redirects.

    Step 1: Prepare the package on an Internet-attached network. Copy the OfflineUpdate folder and script to the offline network.
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
    The root directory for script operations. Defaults to a 'OfflineUpdate' folder in the script directory.

.PARAMETER Modules
    Path to the directory containing the OfflineUpdate module and dependencies. Defaults to kbudate\modules.

.PARAMETER Catalog
    Path where the wsusscn2.cab (Offline Scan File) is stored or will be downloaded. Defaults to kbudate\catalog.

.PARAMETER Computers
    Path to file used to store list of hosts to scan. Defaults to kbudate\scan\hosts.txt. A list is also accepted directly.

.PARAMETER Repository
    The local repository where .msu/.cab update files are downloaded and stored. Defaults to kbudate\repository.

.PARAMETER Results
    Directory where compliance reports and missing KB lists are exported. Defaults to kbudate\scanresults.

.PARAMETER PreparePackage
    Switch to download the needed modules and the latest wsusscn2.cab.

.PARAMETER Install
    Switch to install the OfflineUpdate module from the local WorkingFolder to the system module path.

.PARAMETER Scan
    Switch to query Active Directory for computers and perform a remote compliance scan.

.PARAMETER DownloadUpdates
    Switch to read the 'MissingKBs.txt' list and download the actual update files from Microsoft.

.PARAMETER DeployUpdates
    Switch to push and install the downloaded updates from the RepoFolder to the target endpoints.

.PARAMETER SkipReport
    If set, the script will not automatically open the CSV scan results in Out-GridView.

.EXAMPLE
    .\OfflineUpdater.ps1 -PreparePackage
    Downloads all necessary tools and the ~1GB scan catalog to prepare for an offline site visit.

.EXAMPLE
    .\OfflineUpdater.ps1 -Scan -WorkingFolder "D:\OfflineUpdate"
    Scans AD computers and generates a report of what is missing using the specified working directory.

.EXAMPLE
    To install from a remote host that had issues, log into that machine interactively, then:
    Create a local copy at c:\offlineupdater.ps1 and the OfflineUpdate\catalog\wsusscn2.cab file, then run
    C:\OfflineUpdater.ps1 -Install -WorkingFolder \\otherpc\c$\OfflineUpdate
    C:\OfflineUpdater.ps1 -Scan -SkipAD -Computers yourlocalname
    C:\OfflineUpdater.ps1 -Deploy -Repository \\otherpc\c$\OfflineUpdate\repository

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
    [alias("Deploy", "DeployUpdate", "Push")]
    [switch]$DeployUpdates,

    [Parameter(Mandatory = $false)]
    [alias("NoReport")]
    [switch]$SkipReport,

    [Parameter(Mandatory = $false)]
    [alias("NoAD")]
    [switch]$SkipAD
)

if (-not $WorkingFolder) {
        if ($psISE -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
            $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
        } else {
            $ScriptRoot = $PSScriptRoot
    } 
    $WorkingFolder = (Join-Path -Path $ScriptRoot -ChildPath "OfflineUpdate")
}
if (-not $Modules)    { $Modules = Join-Path -Path $WorkingFolder -ChildPath "modules" }
if (-not $Repository) { $Repository = Join-Path -Path $WorkingFolder -ChildPath "repository" }
if (-not $Results)    { $Results = Join-Path -Path $WorkingFolder -ChildPath "ScanResults" }
if (-not $Catalog)    { $Catalog = Join-Path -Path $WorkingFolder -ChildPath "catalog\wsusscn2.cab" }
if (-not $Computers)  { $Computers = Join-Path -Path $WorkingFolder -ChildPath "scan\hosts.txt" }
if ($Computers.Count -eq 1 -and (Test-Path -Path $Computers[0] -PathType Leaf)) { $TargetEndpoints = Get-Content -Path $Computers[0] } 
else { $TargetEndpoints = $Computers }

# --- 0. INTERACTIVE MENU (FOR NON-PS USERS) ---
# This block triggers only if no main action switches are selected
$NoActionSelected = -not ($PreparePackage -or $Install -or $Scan -or $DownloadUpdates -or $DeployUpdates)
if ($NoActionSelected) {
    do {
        Clear-Host
        Write-Host "===========================================================" -ForegroundColor Cyan
        Write-Host "            OFFLINE WINDOWS UPDATER - MAIN MENU            " -ForegroundColor Cyan
        Write-Host "===========================================================" -ForegroundColor Cyan
        Write-Host " 1) -Prepare Package  (Run on INTERNET-CONNECTED computer) "
        Write-Host " 2) -Install Modules  (Run on AIR-GAPPED computer)"
        Write-Host " 3) -Scan Endpoints   (Run on AIR-GAPPED computer)"
        Write-Host " 4) -Download Updates (Run on INTERNET-CONNECTED computer) "
        Write-Host " 5) -Deploy Updates   (Run on AIR-GAPPED computer)"
        Write-Host " Q) Quit"
        Write-Host "===========================================================" -ForegroundColor Cyan
        $Choice = Read-Host "Select an option [1-5 or Q]"
        switch ($Choice) {
            "1" { $PreparePackage = $true;  $Continue = $false }
            "2" { $Install = $true;         $Continue = $false }
            "3" { $Scan = $true;            $Continue = $false }
            "4" { $DownloadUpdates = $true; $Continue = $false }
            "5" { $DeployUpdates = $true;   $Continue = $false }
            "Q" { exit }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1; $Continue = $true }
        }
    } while ($Continue)
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
        $ShouldDownload = $true
        if (Test-Path $Catalog) {
            if ((Get-Item $Catalog).LastWriteTime -ge (Get-Date).AddDays(-1)) {
                Write-Host "The existing wsusscn2.cab is current." -ForegroundColor Gray
                $ShouldDownload = $false
            }
        }
        if ($ShouldDownload) {
            Write-Host "Downloading wsusscn2.cab (~1GB)..." -ForegroundColor Gray
            $Url = "https://go.microsoft.com/fwlink/?linkid=74689"
            Invoke-WebRequest -Uri $Url -OutFile $Catalog -UseBasicParsing
        }
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
    if (-not (Test-Path $Results)) { New-Item -ItemType Directory -Path $Results -Force | Out-Null }
    if (-not $SkipAD -and ($Computers.Count -eq 1 -and (Test-Path $Computers[0]))) {
        $isInstalled = (Get-WindowsFeature -Name RSAT-ADDS-Tools).Installed
        if ($isInstalled) {
            Write-Host "RSAT: Active Directory Users and Computers is installed." -ForegroundColor Gray
        } else {
            Write-Host "RSAT: Active Directory Users and Computers is NOT installed." -ForegroundColor Red
            return
        }
        Write-Host "Gathering AD Computers..." -ForegroundColor Gray
        Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows*'} |
            Select-Object -ExpandProperty Name |
                Out-File -FilePath $Computers[0]
        $TargetEndpoints = Get-Content $Computers[0]
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
    Write-Host "--- Operation: Download Updates ---" -ForegroundColor Gray
    Write-Host "Starting Defender definition downloads..." -ForegroundColor Gray
    $DefenderUpdates = Join-Path -Path $WorkingFolder -ChildPath "DefenderUpdates"
    if (-not (Test-Path $DefenderUpdates)) { New-Item -Path $DefenderUpdates -ItemType Directory }
    $ArchFolders = @{
        "x64" = "https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64"
        "x86" = "https://go.microsoft.com/fwlink/?LinkID=121721&arch=x86"
    }
    foreach ($Arch in $ArchFolders.Keys) {
        $TargetFolder = Join-Path $DefenderUpdates $Arch
        if (-not (Test-Path $TargetFolder)) { 
            New-Item -Path $TargetFolder -ItemType Directory | Out-Null 
        }
        $FileName = "mpam-fe.exe"
        $Destination = Join-Path $TargetFolder $FileName
        $Url = $ArchFolders[$Arch]
        if (Test-Path $Destination) {
            $LastUpdate = (Get-Item $Destination).LastWriteTime
            $TimeDiff = (Get-Date) - $LastUpdate
            if ($TimeDiff.TotalHours -lt 24) {
                Write-Host "SKIPPING: $Arch\$FileName is current (Last updated: $($LastUpdate.ToString('MM/dd HH:mm')))" -ForegroundColor Yellow
                continue
            }
        }
        try {
            Write-Host "Downloading $Arch version to $Destination... " -NoNewline
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        }
        catch {
            Write-Warning "Failed to download $Arch version. Error: $($_.Exception.Message)"
        }
    }
    Write-Host "Getting latest Defender Platform Update from https://www.catalog.update.microsoft.com/Search.aspx?q=Update+for+Microsoft+Defender+antivirus+platform" -ForegroundColor Gray
    $CurrentFiles = Get-Item -Path "$DefenderUpdates\updateplatform*.exe" -ErrorAction SilentlyContinue
    if ($CurrentFiles -and ($CurrentFiles | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime -ge (Get-Date).AddDays(-1)) {
        Write-Host "The existing Defender Platform Update files are current." -ForegroundColor Green
        $ShouldDownload = $false
    } else {
        Write-Host "The existing Defender Platform Update files are outdated or missing. Downloading new packages..." -ForegroundColor Yellow
        Remove-Item -Path "$DefenderUpdates\updateplatform*.exe" -Force -ErrorAction SilentlyContinue -Verbose
        $DefenderPlatformUpdate = Get-KbUpdate -KB 4052623 | 
            Sort-Object -Property LastModified -Descending | 
                Select-Object -First 1
        foreach ($link in $DefenderPlatformUpdate.Link) {
            $Update | Save-KbUpdate -Link $link -Path $DefenderUpdates -Verbose
        }
    }
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
            $FileName = Split-Path $Url -Leaf
            try {
                Save-KbUpdate -Link $Url -Path $Repository -Verbose
            } catch {
                Write-Warning "Failed to download $FileName. Error: $($_.Exception.Message)"
            }
        }
        Write-Host "Download complete. Total files in repository: $((Get-ChildItem $Repository).Count)" -ForegroundColor Green
    }
}

# --- 5. DEPLOY UPDATES ---
if ($DeployUpdates) {
    Write-Host "--- Operation: Deploy Updates ---" -ForegroundColor Gray
    Write-Host "Starting Defender definition deployment..." -ForegroundColor Gray
    $ShareName = "DefenderUpdates"
    $DefenderUpdates = Join-Path -Path $WorkingFolder -ChildPath $ShareName
    if (-not (Test-Path $DefenderUpdates)) { New-Item -Path $DefenderUpdates -ItemType Directory }
    $Acl = Get-Acl $DefenderUpdates
    $ArAuth = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.SetAccessRule($ArAuth)
    $ArComp = New-Object System.Security.AccessControl.FileSystemAccessRule("Domain Computers", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.SetAccessRule($ArComp)
    Set-Acl $DefenderUpdates $Acl
    if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $ShareName -Path $DefenderUpdates -ReadAccess "Authenticated Users", "Domain Computers" -FullAccess "Administrators"
        Grant-SmbShareAccess -Name $ShareName -AccountName "Domain Computers" -AccessRight Read -Force
        Write-Host "Share '$ShareName' created successfully with Authenticated Users and Domain Computers read access." -ForegroundColor Green
    }
    $UncPath = "\\$($env:COMPUTERNAME)\$ShareName"
    Invoke-Command -ComputerName $TargetEndpoints -ScriptBlock {
        param($Path)
        try {
            $Svc = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
            if ($null -eq $Svc) {
                Write-Host "SKIPPING: Defender (WinDefend) is not installed on $($env:COMPUTERNAME)." -ForegroundColor Yellow
                return
            }
            if ($Svc.Status -ne 'Running') { # Check for other AV since Defender is stopped
                $OtherAV = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
                $AVName = if ($OtherAV) { $OtherAV.displayName -join ", " } else { "Unknown/External Provider" }
                Write-Host "SKIPPING: Defender service is $($Svc.Status) on $($env:COMPUTERNAME). Active AV: $AVName" -ForegroundColor Yellow
                return
            }
            $Status = Get-MpComputerStatus
            if ($Status.AMRunningMode -ne "Normal" -and $Status.AMRunningMode -ne 0) { # Service is running, now check the Running Mode
                $OtherAV = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
                $AVName = if ($OtherAV) { $OtherAV.displayName -join ", " } else { "Unknown/External Provider" }
                Write-Host "SKIPPING: Defender is in Passive Mode ($($Status.AMRunningMode)) on $($env:COMPUTERNAME). Active AV: $AVName" -ForegroundColor Yellow
                return
            }
            Set-MpPreference -SignatureDefinitionUpdateFileSharesSources $Path
            Update-MpSignature -UpdateSource FileShares
            Write-Host "SUCCESS: $($env:COMPUTERNAME) updated." -ForegroundColor Green
        }
        catch {
            Write-Host "CRITICAL ERROR on $($env:COMPUTERNAME): The Defender WMI provider is unresponsive (Service may be corrupted or disabled by policy)." -ForegroundColor Red
        }
    } -ArgumentList $UncPath -ThrottleLimit 3
    Write-Host "Starting Windows KB deployment..." -ForegroundColor Gray
    $LatestReport = Get-ChildItem -Path $Results -Filter "Full_Compliance_Report_*.csv" | 
        Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
    if (-not $LatestReport) {
        Write-Error "Could not find a Compliance Report CSV in $Results. Run -Scan first."
    } elseif (-not (Test-Path $Repository)) {
        Write-Error "Repository folder not found at $Repository. Ensure updates were downloaded and moved to this network."
    } else {
        Write-Host "Loading deployment manifest: $($LatestReport.Name)" -ForegroundColor Gray
        $NeededUpdates = Import-Csv -Path $LatestReport.FullName
        if ($NeededUpdates.Count -eq 0) {
            Write-Host "Manifest is empty. No updates to deploy." -ForegroundColor Yellow
            return
        }
        Write-Host "Starting deployment to $( ($NeededUpdates.ComputerName | Select-Object -Unique).Count ) endpoints..." -ForegroundColor Gray
        $NeededUpdates | Install-KbUpdate -RepositoryPath $Repository -NoMultithreading -Verbose
        Write-Host "Deployment tasks completed." -ForegroundColor Green
    }

    # --- REBOOT CHECK (Final Phase) ---
    Write-Host "Validating post-deployment reboot requirements..." -ForegroundColor Gray
    Invoke-Command -ComputerName $TargetEndpoints -ScriptBlock {
        $NeedsReboot = $false
        $Trigger = ""
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
            $NeedsReboot = $true
            $Trigger = "Component Based Servicing"
        }
        elseif (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
            $NeedsReboot = $true
            $Trigger = "Windows Update Agent"
        }
        else {
            $FileRename = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
            if ($FileRename.PendingFileRenameOperations) {
                $NeedsReboot = $true
                $Trigger = "Pending File Rename"
            }
        }
        if ($NeedsReboot) {
            Write-Host "[!] $($env:COMPUTERNAME) REQUIRES REBOOT (Trigger: $Trigger)" -ForegroundColor Yellow
        }
        else {
            Write-Host "$($env:COMPUTERNAME) does not appear to need a reboot." -ForegroundColor Gray
        }
    }
}

