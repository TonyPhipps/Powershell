<#
.SYNOPSIS
    A management wrapper for the kbupdate module to facilitate offline Windows patching.

.DESCRIPTION
    This script automates the end-to-end process of offline updating. It bundles the 
    necessary PowerShell modules and the Microsoft servicing stack (wsusscn2.cab), scans Active Directory 
    endpoints for missing KBs, download required updates from the Microsoft Catalog 
    on an internet-connected host, and deploys them to target endpoints in an air-gapped
    environment. Below is the general approach and commands without optional file/folder redirects.

    Step 1: Prepare the package on an Internet-attached network. Copy the kbupdate folder and script to the offline network.
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
    The root directory for script operations. Defaults to a 'kbupdate' folder in the script directory.

.PARAMETER Modules
    Path to the directory containing the kbupdate module and dependencies. Defaults to kbudate\modules.

.PARAMETER Catalog
    Path where the wsusscn2.cab (Offline Scan File) is stored or will be downloaded. Defaults to kbudate\catalog.

.PARAMETER Computers
    Path to file used to store list of hosts to scan. Defaults to kbudate\scan\hosts.txt.

.PARAMETER Repository
    The local repository where .msu/.cab update files are downloaded and stored. Defaults to kbudate\repository.

.PARAMETER Results
    Directory where compliance reports and missing KB lists are exported. Defaults to kbudate\scanresults.

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

.PARAMETER SkipReport
    If set, the script will not automatically open the CSV scan results in Out-GridView.

.EXAMPLE
    .\OfflineUpdater.ps1 -PreparePackage
    Downloads all necessary tools and the ~1GB scan catalog to prepare for an offline site visit.

.EXAMPLE
    .\OfflineUpdater.ps1 -Scan -WorkingFolder "D:\KBUpdate"
    Scans AD computers and generates a report of what is missing using the specified working directory.

.NOTES
    File Name      : OfflineUpdater.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges, RSAT (for -Scan)
    Version        : 1.0
    Date           : April 13, 2026
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
    [alias("H", "Hosts")]
    [string]$Computers,

    [Parameter(Mandatory = $false)]
    [alias("P", "Prepare", "Package")]
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
    $WorkingFolder = (Join-Path -Path $ScriptRoot -ChildPath "kbupdate")
}
if (-not $Modules)    { $Modules = Join-Path -Path $WorkingFolder -ChildPath "modules" }
if (-not $Repository) { $Repository = Join-Path -Path $WorkingFolder -ChildPath "repository" }
if (-not $Results)    { $Results = Join-Path -Path $WorkingFolder -ChildPath "ScanResults" }
if (-not $Computers)  { $Computers = Join-Path -Path $WorkingFolder -ChildPath "scan\hosts.txt" }
if (-not $Catalog)    { $Catalog = Join-Path -Path $WorkingFolder -ChildPath "catalog\wsusscn2.cab" }

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
                Write-Host "The existing wsusscn2.cab is current." -ForegroundColor Green
                $ShouldDownload = $false
            }
        }
        if ($ShouldDownload) {
            Write-Host "Downloading wsusscn2.cab (~1GB)..." -ForegroundColor Cyan
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
    Write-Host "Installing kbupdate and dependencies to $PowerShellModules..." -ForegroundColor Cyan
    $ModuleFolders = Get-ChildItem -Path $Modules -Directory
    foreach ($Folder in $ModuleFolders) {
        $Dest = Join-Path $PowerShellModules $Folder.Name
        Copy-Item -Path $Folder.FullName -Destination $Dest -Recurse -Force
    }
    Write-Host "Verifying installation..." -ForegroundColor Cyan
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
    $isInstalled = (Get-WindowsFeature -Name RSAT-ADDS-Tools).Installed
    if ($isInstalled) {
        Write-Host "RSAT: Active Directory Users and Computers is installed." -ForegroundColor Green
    } else {
        Write-Host "RSAT: Active Directory Users and Computers is NOT installed." -ForegroundColor Red
        return
    }
    if (-not (Test-Path $Results)) { New-Item -ItemType Directory -Path $Results -Force | Out-Null }
    if (-not $SkipAD) {
        Write-Host "Gathering AD Computers..." -ForegroundColor Gray
        Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows*'} |
            Select-Object -ExpandProperty Name |
                Out-File -FilePath $Computers
    }
    $TargetEndpoints = Get-Content $Computers
    $ScanResults = foreach ($Endpoint in $TargetEndpoints) {
        Get-KbNeededUpdate -ComputerName $Endpoint -ScanFilePath $Catalog -Force -Verbose
    }
    if ($ScanResults) {
        $ReportPath = Join-Path $Results -ChildPath "Full_Compliance_Report_$((Get-Date).ToString('yyyyMMdd_HHmmSS')).csv"
        $MissingKBsPath = Join-Path -Path $Results -ChildPath "MissingKBs_$((Get-Date).ToString('yyyyMMdd_HHmmSS')).txt"
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
    $LatestReport = Get-ChildItem -Path $Results -Filter "Full_Compliance_Report_*.csv" | 
        Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
    if (-not $LatestReport) {
        Write-Error "No Compliance Report found in $Results."
    } else {
        if (-not (Test-Path $Repository)) { New-Item -ItemType Directory -Path $Repository -Force | Out-Null }
        $NeededUpdates = Import-Csv -Path $LatestReport.FullName
        $AllLinks = $NeededUpdates.Link | ForEach-Object { $_ -split " " } | 
            Where-Object { $_ -like "http*" } | Select-Object -Unique
        Write-Host "Found $($AllLinks.Count) unique files to download based on scan results." -ForegroundColor Cyan
        foreach ($Url in $AllLinks) {
            $FileName = Split-Path $Url -Leaf
            Write-Host "Downloading: $FileName" -ForegroundColor Yellow
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
    $LatestReport = Get-ChildItem -Path $Results -Filter "Full_Compliance_Report_*.csv" | 
        Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
    if (-not $LatestReport) {
        Write-Error "Could not find a Compliance Report CSV in $Results. Run -Scan first."
    } elseif (-not (Test-Path $Repository)) {
        Write-Error "Repository folder not found at $Repository. Ensure updates were downloaded and moved to this network."
    } else {
        Write-Host "Loading deployment manifest: $($LatestReport.Name)" -ForegroundColor Cyan
        $NeededUpdates = Import-Csv -Path $LatestReport.FullName
        if ($NeededUpdates.Count -eq 0) {
            Write-Host "Manifest is empty. No updates to deploy." -ForegroundColor Yellow
            return
        }
        Write-Host "Starting deployment to $( ($NeededUpdates.ComputerName | Select-Object -Unique).Count ) endpoints..." -ForegroundColor Yellow
        $NeededUpdates | Install-KbUpdate -RepositoryPath $Repository -NoMultithreading -Verbose
        Write-Host "Deployment tasks completed." -ForegroundColor Green
    }
}