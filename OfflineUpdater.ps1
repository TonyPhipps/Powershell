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

.PARAMETER ModulesFolder
    Path to the directory containing the kbupdate module and dependencies. Defaults to kbudate\modules.

.PARAMETER CatalogFolder
    Path where the wsusscn2.cab (Offline Scan File) is stored or will be downloaded. Defaults to kbudate\catalog.

.PARAMETER ScanFolder
    Directory used to store endpoint lists (endpoints.txt). Defaults to kbudate\scan.

.PARAMETER RepoFolder
    The local repository where .msu/.cab update files are downloaded and stored. Defaults to kbudate\repository.

.PARAMETER ResultsFolder
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
    [string]$WorkingFolder = (Join-Path -Path $PSScriptRoot -ChildPath "kbupdate"),

    [Parameter(Mandatory = $false)]
    [string]$ModulesFolder,

    [Parameter(Mandatory = $false)]
    [string]$CatalogFolder,

    [Parameter(Mandatory = $false)]
    [string]$ScanFolder,

    [Parameter(Mandatory = $false)]
    [string]$RepoFolder,

    [Parameter(Mandatory = $false)]
    [string]$ResultsFolder,

    [Parameter(Mandatory = $false)]
    [string]$EndpointsPath,

    [Parameter(Mandatory = $false)]
    [string]$CabPath,

    [Parameter(Mandatory = $false)]
    [switch]$PreparePackage,

    [Parameter(Mandatory = $false)]
    [switch]$Install,

    [Parameter(Mandatory = $false)]
    [switch]$Scan,

    [Parameter(Mandatory = $false)]
    [switch]$DownloadUpdates,

    [Parameter(Mandatory = $false)]
    [switch]$DeployUpdates,

    [Parameter(Mandatory = $false)]
    [switch]$SkipReport
)

if (-not $ModulesFolder)  { $ModulesFolder = Join-Path -Path $WorkingFolder -ChildPath "modules" }
if (-not $CatalogFolder)  { $CatalogFolder = Join-Path -Path $WorkingFolder -ChildPath "catalog" }
if (-not $ScanFolder)     { $ScanFolder = Join-Path -Path $WorkingFolder -ChildPath "scan" }
if (-not $RepoFolder)     { $RepoFolder = Join-Path -Path $WorkingFolder -ChildPath "repository" }
if (-not $ResultsFolder)  { $ResultsFolder = Join-Path -Path $WorkingFolder -ChildPath "ScanResults" }
if (-not $EndpointsPath)  { $EndpointsPath = Join-Path -Path $ScanFolder -ChildPath "endpoints.txt" }
if (-not $MissingKBsPath) { $MissingKBsPath = Join-Path -Path $ResultsFolder -ChildPath "MissingKBs.txt" }
if (-not $CabPath)        { $CabPath = Join-Path -Path $CatalogFolder -ChildPath "wsusscn2.cab" }

# --- 2. PREPARE PACKAGE (OFFLINE ASSETS) ---
if ($PreparePackage) {
    Write-Host "--- Operation: Prepare Package ---" -ForegroundColor Gray
    try {
        Install-PackageProvider -Name NuGet -Scope CurrentUser -ErrorAction SilentlyContinue
        $Url = "https://go.microsoft.com/fwlink/?linkid=74689"
        if (-not (Test-Path $WorkingFolder)) { New-Item -ItemType Directory -Path $WorkingFolder -Force | Out-Null }
        if (-not (Test-Path $ModulesFolder)) { New-Item -ItemType Directory -Path $ModulesFolder -Force | Out-Null }
        if (-not (Test-Path $CatalogFolder)) { New-Item -ItemType Directory -Path $CatalogFolder -Force | Out-Null }
        Write-Host "Saving module to $ModulesFolder..." -ForegroundColor Gray
        Save-Module -Name kbupdate -Path $ModulesFolder -ErrorAction Stop -Verbose
        Save-Module -Name xWindowsUpdate -Path $ModulesFolder -ErrorAction Stop -Verbose
        Get-ChildItem -Path $WorkingFolder -Recurse | Unblock-File
        $ShouldDownload = $true
        if (Test-Path $CabPath) {
            if ((Get-Item $CabPath).LastWriteTime -ge (Get-Date).AddDays(-1)) {
                Write-Host "The existing wsusscn2.cab is current." -ForegroundColor Green
                $ShouldDownload = $false
            }
        }
        if ($ShouldDownload) {
            Write-Host "Downloading wsusscn2.cab (~1GB)..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $Url -OutFile $CabPath -UseBasicParsing
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
    $TargetModulePath = "C:\Program Files\WindowsPowerShell\Modules"
    if (-not (Test-Path $TargetModulePath)) {
        New-Item -ItemType Directory -Path $TargetModulePath -Force | Out-Null
    }
    Write-Host "Installing kbupdate and dependencies to $TargetModulePath..." -ForegroundColor Cyan
    $ModuleFolders = Get-ChildItem -Path $ModulesFolder -Directory
    foreach ($Folder in $ModuleFolders) {
        $Dest = Join-Path $TargetModulePath $Folder.Name
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
    if (-not (Test-Path $ScanFolder)) { New-Item -ItemType Directory -Path $ScanFolder -Force | Out-Null }
    if (-not (Test-Path $ResultsFolder)) { New-Item -ItemType Directory -Path $ResultsFolder -Force | Out-Null }
    Write-Host "Gathering AD Computers..." -ForegroundColor Gray
    Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows*'} | Select-Object -ExpandProperty Name | Out-File -FilePath $EndpointsPath
    $TargetEndpoints = Get-Content $EndpointsPath
    $ScanResults = foreach ($Endpoint in $TargetEndpoints) {
        Get-KbNeededUpdate -ComputerName $Endpoint -ScanFilePath $CabPath -Force -Verbose
    }
    if ($ScanResults) {
        $ReportPath = Join-Path $ResultsFolder "Full_Compliance_Report_$((Get-Date).ToString('yyyyMMdd')).csv"
        $ScanResults | Export-Csv -Path $ReportPath -NoTypeInformation
        $NewKBs = $ScanResults.KBUpdate | Where-Object { $_ } | Sort-Object -Unique
        $NewKBs | Out-File -FilePath $MissingKBsPath
        Write-Host "Scan complete. Detailed report saved to $ReportPath" -ForegroundColor Green
        Write-Host "Copy the ScanResults folder to your online host for downloading." -ForegroundColor Cyan
        if (-not $SkipReport) {
            Import-Csv -Path $ReportPath | Out-GridView
        }
    } else {
        Write-Host "No missing updates found." -ForegroundColor Gray
    }
}

# --- 4. DOWNLOAD UPDATES ---
if ($DownloadUpdates) {
    Write-Host "--- Operation: Download Updates ---" -ForegroundColor Gray
    $LatestReport = Get-ChildItem -Path $ResultsFolder -Filter "Full_Compliance_Report_*.csv" | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 1
    if (-not $LatestReport) {
        Write-Error "Could not find a Compliance Report CSV in $ResultsFolder. Run -Scan first."
    } else {
        Write-Host "Processing updates based on report: $($LatestReport.Name)" -ForegroundColor Cyan
        if (-not (Test-Path $RepoFolder)) { New-Item -ItemType Directory -Path $RepoFolder -Force | Out-Null }
        $NeededUpdates = Import-Csv -Path $LatestReport.FullName
        $UniqueUpdates = $NeededUpdates | Group-Object KBUpdate
        foreach ($Group in $UniqueUpdates) {
            $KB = $Group.Name
            Write-Host "Querying Catalog for specific revision of $KB..." -ForegroundColor Yellow
            $SpecificUpdate = $Group.Group[0] # Grab metadata from the first instance
            Get-KbUpdate -Name $KB -Architecture x64 | 
                Where-Object { $_.Title -eq $SpecificUpdate.Title } | 
                Save-KbUpdate -Path $RepoFolder -Verbose
        }
        Write-Host "Download complete. Copy the Repository folder ($RepoFolder) to the offline network." -ForegroundColor Green
    }
}

# --- 5. DEPLOY UPDATES ---
if ($DeployUpdates) {
    Write-Host "--- Operation: Deploy Updates ---" -ForegroundColor Gray
    if (Test-Path $EndpointsPath) {
        $TargetEndpoints = Get-Content $EndpointsPath
        Get-KbNeededUpdate -ComputerName $TargetEndpoints -ScanFilePath $CabPath -Force -Verbose | 
            Install-KbUpdate -RepositoryPath $RepoFolder -NoMultithreading -Verbose
        Write-Host "Deployment tasks submitted." -ForegroundColor Green
    } else {
        Write-Error "Endpoint list missing. Run -Scan first."
    }
}