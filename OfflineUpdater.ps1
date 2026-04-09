[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$PrepFolder = "C:\kbupdate",

    [Parameter(Mandatory = $false)]
    [switch]$PreparePackage,

    [Parameter(Mandatory = $false)]
    [switch]$Install,

    [Parameter(Mandatory = $false)]
    [switch]$Scan,

    [Parameter(Mandatory = $false)]
    [switch]$DownloadUpdates,

    [Parameter(Mandatory = $false)]
    [switch]$DeployUpdates
)

# Common Path Definitions
$ModulesFolder = Join-Path -Path $PrepFolder -ChildPath "modules"
$CatalogFolder = Join-Path -Path $PrepFolder -ChildPath "catalog"
$ScanFolder    = Join-Path -Path $PrepFolder -ChildPath "scan"
$RepoFolder    = Join-Path -Path $PrepFolder -ChildPath "repository"
$ExportFolder  = Join-Path -Path $PrepFolder -ChildPath "ScanResults"
$EndpointsPath = Join-Path -Path $ScanFolder -ChildPath "endpoints.txt"
$KBListPath    = Join-Path -Path $ExportFolder -ChildPath "MissingKBs.txt"
$CabPath       = Join-Path -Path $CatalogFolder -ChildPath "wsusscn2.cab"

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
    Import-Module kbupdate -Force
    if (Get-Command -Module kbupdate) {
        Write-Host "SUCCESS: kbupdate is ready for use." -ForegroundColor Green
    } else {
        Write-Error "Module could not be loaded. Check Execution Policy."
    }
}

# --- 2. PREPARE PACKAGE (OFFLINE ASSETS) ---
if ($PreparePackage) {
    Write-Host "--- Operation: Prepare Package ---" -ForegroundColor Gray
    try {
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction SilentlyContinue
        $Url = "https://go.microsoft.com/fwlink/?linkid=74689"
        if (-not (Test-Path $PrepFolder)) { New-Item -ItemType Directory -Path $PrepFolder -Force | Out-Null }
        if (-not (Test-Path $CatalogFolder)) { New-Item -ItemType Directory -Path $CatalogFolder -Force | Out-Null }
        Write-Host "Saving module to $PrepFolder..." -ForegroundColor Gray
        Save-Module -Name kbupdate -Path $PrepFolder -ErrorAction Stop
        Get-ChildItem -Path $PrepFolder -Recurse | Unblock-File
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
        $FolderName = Split-Path -Path $PrepFolder -Leaf
        $ParentFolder = Split-Path -Path $PrepFolder -Parent
        $DestinationZip = Join-Path -Path $ParentFolder -ChildPath "$FolderName.zip"
        Write-Host "Compressing folder to $DestinationZip..." -ForegroundColor Cyan
        Compress-Archive -Path "$PrepFolder\*" -DestinationPath $DestinationZip -Force
        Write-Host "Success! Package ready at: $DestinationZip" -ForegroundColor Green
    }
    catch {
        Write-Error "Preparation failed: $($_.Exception.Message)"
    }
}

# --- Module Validation Check ---
$InstallRequired = $Scan, $DownloadUpdates, $DeployUpdates
if ($InstallRequired -contains $true) {
    if (-not (Get-Module -ListAvailable -Name kbupdate)) {
        Write-Error "CRITICAL: The 'kbupdate' module is not installed. Please run this script with the -Install flag first."
        return # Stops execution of the script
    }
}

# --- 3. SCAN ENDPOINTS ---
if ($Scan) {
    $isInstalled = (Get-WindowsFeature -Name RSAT-ADDS-Tools).Installed
    if ($isInstalled) {
        Write-Host "RSAT: Active Directory Users and Computers is installed." -ForegroundColor Green
    } else {
        Write-Host "RSAT: Active Directory Users and Computers is NOT installed." -ForegroundColor Red
        return
    }
    Write-Host "--- Operation: Scan ---" -ForegroundColor Gray
    if (-not (Test-Path $ScanFolder)) { New-Item -ItemType Directory -Path $ScanFolder -Force | Out-Null }
    if (-not (Test-Path $ExportFolder)) { New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null }
    Write-Host "Gathering AD Computers..." -ForegroundColor Gray
    Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows*'} | Select-Object -ExpandProperty Name | Out-File -FilePath $EndpointsPath
    $TargetEndpoints = Get-Content $EndpointsPath
    $RemoteCabPath = "\\$env:COMPUTERNAME\$($CabPath -replace ':', '$')"
    $ScanResults = foreach ($endpoint in $TargetEndpoints) {
        $scanAttempt = Get-KbNeededUpdate -ComputerName $endpoint -ScanFilePath $RemoteCabPath -WarningVariable warn -ErrorVariable err -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($warn -or $err -or (-not $scanAttempt)) {
            Get-KbNeededUpdate -ComputerName $endpoint -ScanFilePath $RemoteCabPath -Force
        } else {
            $scanAttempt
        }
    }
    if ($ScanResults) {
        $ReportPath = Join-Path $ExportFolder "Full_Compliance_Report_$((Get-Date).ToString('yyyyMMdd')).csv"
        $ScanResults | Select-Object ComputerName, KBUpdate, Title, IsMandatory, RebootRequired | Export-Csv -Path $ReportPath -NoTypeInformation
        $ExistingKBs = if (Test-Path $KBListPath) { Get-Content $KBListPath } else { @() }
        $NewKBs = $ScanResults.KBUpdate
        $UniqueKBs = ($ExistingKBs + $NewKBs) | Where-Object { $_ } | Sort-Object -Unique
        $UniqueKBs | Out-File -FilePath $KBListPath
        Write-Host "Scan complete. Updated missing KBs saved to $KBListPath" -ForegroundColor Green
        Write-Host "Copy that folder (or the whole package) back to a host with access to Microsoft.com and run again with the -DownloadUpdates flag." -ForegroundColor Green
    } else {
        Write-Host "No missing updates found." -ForegroundColor Gray
    }
}

# --- 4. DOWNLOAD UPDATES ---
if ($DownloadUpdates) {
    Write-Host "--- Operation: Download Updates ---" -ForegroundColor Gray
    if (-not (Test-Path $KBListPath)) {
        Write-Error "Could not find the MissingKBs.txt list at $KBListPath. Run -Scan first."
    } else {
        New-Item -ItemType Directory -Path $RepoFolder -Force | Out-Null
        $KBsToDownload = Get-Content $KBListPath
        Write-Host "Found $($KBsToDownload.Count) required updates." -ForegroundColor Cyan
        foreach ($KB in $KBsToDownload) {
            Write-Host "Querying Catalog for $KB..." -ForegroundColor Yellow
            $Update = Get-KbUpdate -Name $KB -Architecture x64 -Simple
            if ($Update) {
                foreach ($U in $Update) {
                    Write-Host "  -> Downloading: $($U.Title)" -ForegroundColor Green
                    $U | Save-KbUpdate -Path $RepoFolder
                }
            } else {
                Write-Warning "  -> $KB not found in online catalog."
            }
        }
    }
}

# --- 5. DEPLOY UPDATES ---
if ($DeployUpdates) {
    Write-Host "--- Operation: Deploy Updates ---" -ForegroundColor Gray
    if (Test-Path $EndpointsPath) {
        $TargetEndpoints = Get-Content $EndpointsPath
        Install-KbUpdate -ComputerName $TargetEndpoints -FilePath $RepoFolder
        Write-Host "Deployment tasks submitted." -ForegroundColor Green
    } else {
        Write-Error "Endpoint list missing. Run -Scan first."
    }
}