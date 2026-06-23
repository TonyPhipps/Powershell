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
        .\OfflineUpdater.ps1 -Scan -ScanAD
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
    An explicit array of computer names, or a path to a file used to store list of hosts to scan. 
    Defaults to checking \scan\hosts.txt within WorkingFolder if not provided.

.PARAMETER Repository
    The local repository where .msu/.cab update files are downloaded and stored. Defaults to \repository\ subirectory of WorkingFolder.

.PARAMETER Results
    Directory where compliance reports and missing KB lists are exported. Defaults to \scanresults\ subirectory of WorkingFolder.

.PARAMETER PreparePackage
    Switch to download the needed modules and the latest wsusscn2.cab.

.PARAMETER Install
    Switch to install the kbupdate module from the local WorkingFolder to the system module path.

.PARAMETER Scan
    Switch to perform a scan on one or more Windows systems for missing patches.

.PARAMETER DownloadUpdates
    Switch to read the 'MissingKBs.txt' list and download the actual update files from Microsoft.

.PARAMETER DeployUpdates
    Switch to push and install the downloaded updates from the RepoFolder to the target endpoints.

.PARAMETER DeployUpdatesLocal
    Switch to push and install the downloaded updates from the LOCAL endpoint.

.PARAMETER SkipReport
    If set, the script will not automatically open the CSV scan results in Out-GridView.

.PARAMETER DefenderOnly
    Only download/deploy Defender signature and engine updates, skipping all KB deployments. 
    To be used in conjunction with -DownloadUpdates and/or -DeployUpdates.

.PARAMETER SkipDefender
    If set, the script will not automatically download or deploy Defender.

.PARAMETER ScanAD
    Switch to discover target hosts via Active Directory rather than relying on a local hosts.txt file.

.PARAMETER DeltaReport
    Switch to compare files inside the repository with the latest compliance report, generating a truncated report of missing files.

.EXAMPLE
    .\OfflineUpdater.ps1 -PreparePackage
    Downloads all necessary tools and the ~1GB scan catalog to prepare for an offline site visit.

.EXAMPLE
    .\OfflineUpdater.ps1 -Scan -ScanAD -WorkingFolder "D:\OfflineUpdater"
    Scans local file inventory computers and generates a report of what is missing using the specified working directory.

.EXAMPLE
    To install locally (for hosts that had remote issues), log into that machine interactively, then:
    Create a local copy at c:\offlineupdater.ps1 and the OfflineUpdater\catalog\wsusscn2.cab file, then run
    & '\\otherhost\d$\OfflineUpdater\OfflineUpdater.ps1' -Install -WorkingFolder "\\otherhost\d$\OfflineUpdater"
    New-Item -ItemType Directory -Path d:\OfflineUpdater -Force
    Copy-Item -Path "\\otherhost\d$\OfflineUpdater\OfflineUpdater.ps1" -Destination "d:\OfflineUpdater\" -Force
    Copy-Item -Path "\\otherhost\d$\OfflineUpdater\catalog" -Destination "d:\OfflineUpdater\" -Recurse -Force
    D:\OfflineUpdater\OfflineUpdater.ps1 -Scan -Host $Env:COMPUTERNAME -WorkingFolder "d:\OfflineUpdater"
    D:\OfflineUpdater\OfflineUpdater.ps1 -DeployLocal -Repository \\otherpc\d$\OfflineUpdater\repository

.NOTES
    File Name      : OfflineUpdater.ps1
    Author         : Tony Phipps
    Prerequisites  : PowerShell 5.1+, Administrator privileges, RSAT (for -ScanAD)
    Version        : 1.4
    Date           : June 10, 2026
    Copyright      : (c) 2026 Tony Phipps under the MIT License

    Manual Fallbacks are provided below for when kbupdate fails repeatedly on the last few remaining patches.
    wusa.exe "C:\Path\To\Your\Patch\Windows11.0-KB50XXXXX-x64.msu" /norestart
    Dism /Online /Add-Package /PackagePath:"C:\Path\To\Your\windows10.0-kb5066139-x64-ndp48...cab"
    
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
    [string[]]$Computers = ($Env:COMPUTERNAME),

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
    [alias("DeployLocal", "DeployUpdateLocal", "UpdateLocal", "Local", "LocalBypass", "Bypass")]
    [switch]$DeployUpdatesLocal,

    [Parameter(Mandatory = $false)]
    [alias("NoReport")]
    [switch]$SkipReport,

    [Parameter(Mandatory = $false)]
    [alias("NoDefender")]
    [switch]$SkipDefender,

    [Parameter(Mandatory = $false)]
    [alias("AD")]
    [switch]$ScanAD,

    [Parameter(Mandatory = $false)]
    [alias("Delta","Report")]
    [switch]$DeltaReport
)

#region: Functions
function Get-TargetComputers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Computers,

        [Parameter(Mandatory = $false)]
        [switch]$ScanAD,

        [Parameter(Mandatory = $true)]
        [string]$WorkingFolder
    )

    if ($ScanAD) {
        try {
            $isInstalled = (Get-WindowsFeature -Name RSAT-ADDS-Tools -ErrorAction SilentlyContinue).Installed
        } catch {
            $isInstalled = $false
        }
        if ($isInstalled) {
            Write-Host "RSAT: Active Directory Users and Computers is installed. Gathering enabled Windows hosts..." -ForegroundColor Gray
            $ADHosts = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows*'} | Select-Object -ExpandProperty Name
            if ($ADHosts) {
                $DefaultHostsPath = [string](Join-Path -Path $WorkingFolder -ChildPath "scan\hosts.txt")
                $TargetDir = Split-Path -Path $DefaultHostsPath -Parent
                if (-not (Test-Path -Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
                $ADHosts | Out-File -FilePath $DefaultHostsPath -Force
                return $ADHosts
            }
            throw [System.Management.Automation.CmdletInvocationException]::new("RSAT: Active Directory query returned no enabled Windows hosts.")
        } else {
            throw [System.Management.Automation.CmdletInvocationException]::new("RSAT: Active Directory Tools are NOT installed. Cannot perform -ScanAD.")
        }
    }

    if ($null -ne $Computers -and $Computers.Count -gt 0) {
        $LooksLikeFile = $Computers.Count -eq 1 -and 
                         ($Computers[0] -match '[\\/]' -or $Computers[0] -match '\.(txt|csv|lst)$')
        if ($LooksLikeFile -and (Test-Path -Path $Computers[0] -PathType Leaf -ErrorAction SilentlyContinue)) {
            Write-Host "Loading endpoints from explicit file path: $($Computers[0])"
            return (Get-Content -Path $Computers[0]) | Where-Object { $_ -match '^[a-zA-Z0-9][a-zA-Z0-9\.-]{0,253}$' }
        }
        return $Computers | Where-Object { $_ -match '^[a-zA-Z0-9][a-zA-Z0-9\.-]{0,253}$' }
    }

    # Fall back to checking the default host inventory file layout
    $DefaultHostFilePath = [string](Join-Path -Path $WorkingFolder -ChildPath "scan\hosts.txt")
    if (Test-Path -Path $DefaultHostFilePath -PathType Leaf) {
        Write-Host "Using default path to hosts.txt as target list: $DefaultHostFilePath"
        return (Get-Content -Path $DefaultHostFilePath) | Where-Object { $_ -match '^[a-zA-Z0-9][a-zA-Z0-9\.-]{0,253}$' }
    }
    throw [System.IO.FileNotFoundException]::new("Target hosts location configuration missing. Please explicitly provide target machine endpoints to -Computers, provide an enter-delimited path to a target text file, rerun the script utilizing the -ScanAD switch to dynamically scan Active Directory domain architectures, or create an enter-delimited host configuration text file locally at: '$DefaultHostFilePath'")
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
            Write-Host "[Skip] ($FileName is current: $($LastModified.ToString('MM/dd HH:mm')))." -ForegroundColor Gray
            return
        }
    }
    if (-not $CheckExpiration -and (Test-Path $FullDestination)) {
        Write-Host "[SKIP] ($FileName already exists)" -ForegroundColor Gray
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
        Write-Host "[Failure] (Error: $($_.Exception.Message))" -ForegroundColor Red
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
            Write-Host "Platform updates are outdated. Cleaning up old files..." -ForegroundColor Cyan
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

    Write-Host "--- Deploying Defender Platform & Signatures ---" -ForegroundColor Gray
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

    # Only provision SMB share architecture if non-local network routes exist in targets
    $HasRemoteTargets = $TargetEndpoints | Where-Object { $_ -ne $env:COMPUTERNAME -and $_ -ne "localhost" -and $_ -ne "127.0.0.1" }
    if ($HasRemoteTargets -and -not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $ShareName -Path $DefenderUpdatesPath -ReadAccess "Domain Computers", "Authenticated Users" -FullAccess "Administrators" | Out-Null
    }
    $UncPath = "\\$($env:COMPUTERNAME)\$ShareName"
    foreach ($Computer in $TargetEndpoints) {
        Write-Host "Checking Defender Status for $($Computer)... " -ForegroundColor Gray
        $Session = $null
        $IsLocal = ($Computer -eq $env:COMPUTERNAME -or $Computer -eq "localhost" -or $Computer -eq "127.0.0.1")
        try {
            if (-not $IsLocal) {
                $Session = New-PSSession -ComputerName $Computer -ErrorAction Stop
            }
            
            $StatusBlock = {
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

            $RemoteStatus = if ($IsLocal) { & $StatusBlock } else { Invoke-Command -Session $Session -ScriptBlock $StatusBlock }

            if ($RemoteStatus.Skip) {
                Write-Host "`t[SKIP] ($($RemoteStatus.Reason))" -ForegroundColor Yellow
                continue
            }
            $Match = $RepoManifest[$RemoteStatus.ArchKey]
            $PlatformWasUpdated = $false
            if ($Match -and ($RemoteStatus.PlatformVer -lt $Match.Version)) {
                Write-Host "`tUpdating Platform: $($RemoteStatus.PlatformVer) -> $($Match.Version)" -ForegroundColor Cyan
                $StagingPath = "C:\Windows\Temp\$($Match.FileName)"
                
                $PlatformBlock = {
                    param($InstallerPath)
                    Start-Process -FilePath $InstallerPath -ArgumentList "/quiet", "/norestart" -Wait
                    Remove-Item -Path $InstallerPath -Force
                }

                if ($IsLocal) {
                    Copy-Item -Path $Match.LocalPath -Destination $StagingPath -Force
                    & $PlatformBlock -InstallerPath $StagingPath
                } else {
                    Copy-Item -Path $Match.LocalPath -Destination $StagingPath -ToSession $Session -Force
                    Invoke-Command -Session $Session -ArgumentList $StagingPath -ScriptBlock $PlatformBlock
                }
                $PlatformWasUpdated = $true
            }

            $ServiceBlock = {
                $Svc = Get-Service WinDefend -ErrorAction SilentlyContinue
                if ($Svc -and $Svc.Status -ne 'Running') {
                    Set-Service -Name WinDefend -StartupType Automatic
                    Start-Service -Name WinDefend -ErrorAction SilentlyContinue
                }
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            }

            if ($IsLocal) {
                & $ServiceBlock
            } else {
                Invoke-Command -Session $Session -ScriptBlock $ServiceBlock
            }

            $SignatureBlock = {
                param($Path)
                try {
                    Set-MpPreference -SignatureDefinitionUpdateFileSharesSources $Path
                    Update-MpSignature -UpdateSource FileShares -ErrorAction Stop
                } catch { }
            }

            $UpdatePath = if ($IsLocal) { $DefenderUpdatesPath } else { $UncPath }
            if ($IsLocal) {
                & $SignatureBlock -Path $UpdatePath
            } else {
                Invoke-Command -Session $Session -ArgumentList $UpdatePath -ScriptBlock $SignatureBlock
            }

            $ReportBlock = {
                $Retry = 0
                while ($Retry -lt 5) {
                    $Stat = Get-MpComputerStatus -ErrorAction SilentlyContinue
                    if ($Stat) { return $Stat | Select-Object AMEngineVersion, AntivirusSignatureVersion }
                    Start-Sleep -Seconds 2
                    $Retry++
                }
            }

            $FinalReport = if ($IsLocal) { & $ReportBlock } else { Invoke-Command -Session $Session -ScriptBlock $ReportBlock }

            if ($FinalReport) {
                $EngineOut = if ($RemoteStatus.EngineVer -ne $FinalReport.AMEngineVersion) { "$($RemoteStatus.EngineVer) -> $($FinalReport.AMEngineVersion)" } else { "$($FinalReport.AMEngineVersion) (Current)" }
                $SigOut    = if ($RemoteStatus.SignatureVer -ne $FinalReport.AntivirusSignatureVersion) { "$($RemoteStatus.SignatureVer) -> $($FinalReport.AntivirusSignatureVersion)" } else { "$($FinalReport.AntivirusSignatureVersion) (Current)" }
                Write-Host "`t[Report] (Engine: $EngineOut`t`tSignatures: $SigOut)" -ForegroundColor Green
                if ($PlatformWasUpdated) {
                    Write-Host "`t[Success] (Platform updated to $($Match.Version). REBOOT REQUIRED to complete.)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "`t[Success] (Defender updated, but WMI is unresponsive. Reboot recommended.)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "`t[Failure] ($($_.Exception.Message))" -ForegroundColor Red
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

    Write-Host "--- Validating Reboot Status ---" -ForegroundColor Gray
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
    foreach ($Computer in $ComputerNames) {
        Write-Host "Validating reboot status for $($Computer)... " -ForegroundColor Gray -NoNewline
        try {
            $Result = if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq "localhost") {
                & $RebootCheckBlock
            }
            else {
                Invoke-Command -ComputerName $Computer -ScriptBlock $RebootCheckBlock -ErrorAction Stop
            }
            if ($Result.NeedsReboot) {
                Write-Host "[Reboot Required] ($($Result.Trigger))" -ForegroundColor Yellow
            }
            else {
                Write-Host "[Success] (No Reboot Needed)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "[Failure] (Connection Failed)" -ForegroundColor Red
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

    Write-Host "--- Initiating Patch Cleanup ---" -ForegroundColor Cyan
    $CleanupBlock = {
        param($TargetPath)
        if (Test-Path $TargetPath) {
            $PatchFiles = Get-ChildItem -Path $TargetPath -Include *.msu, *.cab, *.exe -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { 
                    $_.Name -match "KB\d{6,}" -or 
                    $_.Name -match "aspnetcore|dotnet|vcredist|windowsdesktop-runtime" 
                }
            foreach ($File in $PatchFiles) {
                try {
                    Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                    Write-Host "[Success] (Removed $($File.Name))" -ForegroundColor Green
                } catch {
                    Write-Host "[Failure] (Could not remove $($File.Name): $($_.Exception.Message))" -ForegroundColor Red
                }
            }
        }
    }
    foreach ($Computer in $ComputerNames) {
        Write-Host "Cleaning patch files from $($Computer)... " -ForegroundColor Gray -NoNewline
        try {
            if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq "localhost") {
                & $CleanupBlock -TargetPath $CustomStagingPath
            }
            else {
                $Result = Invoke-Command -ComputerName $Computer -ScriptBlock $CleanupBlock -ArgumentList $CustomStagingPath -ErrorAction Stop
                if ($Result -match "[Success]%") {
                    Write-Host "$Result" -ForegroundColor Green
                } else {
                    Write-Host "$Result" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "[Failure] (Connection failure)" -ForegroundColor Red
        }
    }
}

function Get-RootCerts {
    [CmdletBinding()]
    param([string]$CertPath)
    Write-Host "Checking for new Root Certificates... " -ForegroundColor Gray -NoNewline
    $CertDir = Split-Path -Path $CertPath -Parent
    if (-not (Test-Path $CertDir)) { New-Item -ItemType Directory -Path $CertDir -Force | Out-Null }
    try {
        $OldHash = $null
        $HashPath = "$CertPath.hash"
        if (Test-Path $CertPath) {
            if (Test-Path $HashPath) {
                $OldHash = Get-Content -Path $HashPath -Raw
            } else {
                $OldHash = (Get-FileHash -Path $CertPath -Algorithm SHA256).Hash
            }
        }
        $certs = certutil.exe -generateSSTFromWU "$CertPath" *>$null
        if (Test-Path $CertPath) {
            $NewHash = (Get-FileHash -Path $CertPath -Algorithm SHA256).Hash
            Set-Content -Path $HashPath -Value $NewHash -Force
            if ($null -ne $OldHash -and $OldHash -ne $NewHash) {
                Write-Host "[Success] new certs were updated" -ForegroundColor Green
            } else {
                Write-Host "[Success] no cert changes." -ForegroundColor Gray
            }
        } else {
            Write-Error "[Failure] (SST file was not created)"
        }
    } catch {
        Write-Error "[Failure] (Could not generate certificate store: $($_.Exception.Message))"
    }
}

function Install-RootCerts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string[]]$ComputerNames,
        [Parameter(Mandatory = $true)] [string]$CertPath
    )
    $CertBlock = {
        param($SstContent)
        try {
            $TempFile = Join-Path $env:TEMP "roots.sst"
            [io.file]::WriteAllBytes($TempFile, $SstContent)
            $sst = Get-ChildItem $TempFile
            $sst | Import-Certificate -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop
            Remove-Item $TempFile -Force
            return "[Success]"
        } catch {
            return "[Failure] ($($_.Exception.Message))"
        }
    }

    $SstBytes = [System.IO.File]::ReadAllBytes($CertPath)
    foreach ($Computer in $ComputerNames) {
        Write-Host "Deploying updated root certificates to $Computer... " -NoNewline -ForegroundColor Cyan
        try {
            $Result = Invoke-Command -ComputerName $Computer -ScriptBlock $CertBlock -ArgumentList (,$SstBytes) -ErrorAction Stop
            if ($Result -eq "[Success]") {
                Write-Host "[Success] Host will need to be re-scanned." -ForegroundColor Yellow
            } else {
                Write-Host "$Result" -ForegroundColor Red
            }
        } catch {
            Write-Host "[Failure] (Could not connect)" -ForegroundColor Red
        }
    }
}


#region: Main
Set-StrictMode -Version Latest
Clear-Host
#region: Params
if (-not $WorkingFolder) {
    if ((Test-Path -Path "Variable:psISE") -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
        $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
    } else {
        $ScriptRoot = $PSScriptRoot
    }
    $SubFolderPath = Join-Path -Path $ScriptRoot -ChildPath "OfflineUpdater"
    $SiblingPath   = Join-Path -Path (Split-Path -Path $ScriptRoot -Parent) -ChildPath "OfflineUpdater"
    if (Test-Path -Path (Join-Path $ScriptRoot "modules")) { # Check if we are ALREADY inside the folder (it contains the necessary 'modules' or 'catalog')
        $WorkingFolder = $ScriptRoot
    }
    elseif (Test-Path -Path $SubFolderPath) { # Check if the folder is a sub-directory
        $WorkingFolder = $SubFolderPath
    }
    elseif (Test-Path -Path $SiblingPath) { # Check if the folder is "next to" us (Sibling)
        $WorkingFolder = $SiblingPath
    }
     else {   # Fallback to D: or C: 
        $DiskD = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = 'D:' and DriveType = 3"
        if ($DiskD) {
            $WorkingFolder = "D:\OfflineUpdater"
        } else {
            $WorkingFolder = "C:\OfflineUpdater"
        }
    }
}
if (-not $Modules)      { $Modules = Join-Path -Path $WorkingFolder -ChildPath "modules" }
if (-not $Repository)   { $Repository = Join-Path -Path $WorkingFolder -ChildPath "repository" }
if (-not $Results)      { $Results = Join-Path -Path $WorkingFolder -ChildPath "ScanResults" }
if (-not $Catalog)      { $Catalog = Join-Path -Path $WorkingFolder -ChildPath "catalog\wsusscn2.cab" }
$Certificates = Join-Path -Path $WorkingFolder -ChildPath "certs\roots.sst"

# Target evaluation wraps inside a try/catch block to correctly intercept the local file missing validation error.
try {
    $TargetEndpoints = Get-TargetComputers -Computers $Computers -ScanAD:$ScanAD -WorkingFolder $WorkingFolder
} catch {
    Write-Error $_.Exception.Message
    Exit
}

#region: Menu
$NoActionSelected = -not ($PreparePackage -or $Install -or $Scan -or $DownloadUpdates -or $DeployUpdates -or $DeployUpdatesLocal -or $DeltaReport)
if ($NoActionSelected) {
    do {
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "                     OFFLINE WINDOWS UPDATER                    " -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "  p) -Prepare Package   (Run on INTERNET-CONNECTED computer)"
        Write-Host "  i) -Install Modules   (Run on AIR-GAPPED computer)"
        Write-Host "  1) -Scan Endpoints    (Run on AIR-GAPPED computer)"
        Write-Host "  2) -Download Updates  (Run on INTERNET-CONNECTED computer)"
        Write-Host "  3) -Deploy Updates    (Run on AIR-GAPPED computer)"
        Write-Host "  d) -Delta Report      (Run with after scan to limit downloads)"
        Write-Host "  q)  Quit"
        Write-Host "  (to target Active Directory discovery, rerun with -ScanAD)"     -ForegroundColor Gray
        Write-Host "  (to target Defender updates only, rerun with -DefenderOnly)"    -ForegroundColor Gray
        Write-Host "  (to deploy updates locally, rerun with -DeployUpdatesLocal)"    -ForegroundColor Gray
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ("Target Hosts:`n`t$((($TargetEndpoints | Sort-Object | Get-Unique) -join ", "))")
        Write-Host ("")
        $Choice = Read-Host "Select an option"
        switch ($Choice.ToLower()) {
            "p" { $PreparePackage = $true;  $Continue = $false }
            "i" { $Install = $true;         $Continue = $false }
            "1" { $Scan = $true;            $Continue = $false }
            "2" { $DownloadUpdates = $true; $Continue = $false }
            "3" { $DeployUpdates = $true;   $Continue = $false }
            "d" { $DeltaReport = $true;     $Continue = $false }
            "q" { exit }
            default { Write-Host "Invalid selection, try again." -ForegroundColor Red; Start-Sleep -Seconds 1; $Continue = $true }
        }
    } while ($Continue)
}

#region: -Prepare
if ($PreparePackage) {
    Write-Host "--- Operation: Prepare Package ---" -ForegroundColor Gray
    try {
        Install-PackageProvider -Name NuGet -Scope CurrentUser -ErrorAction SilentlyContinue
        if (-not (Test-Path $WorkingFolder)) { New-Item -ItemType Directory -Path $WorkingFolder -Force | Out-Null }
        if (-not (Test-Path $Modules)) { New-Item -ItemType Directory -Path $Modules -Force | Out-Null }
        $CatalogDir = Split-Path -Path $Catalog -Parent
        if (-not (Test-Path -Path $CatalogDir)) { New-Item -ItemType Directory -Path $CatalogDir -Force | Out-Null }
        Write-Host "Saving module to $Modules..." -ForegroundColor Gray
        Save-Module -Name kbupdate -Path $Modules -ErrorAction Stop #-Verbose
        Save-Module -Name xWindowsUpdate -Path $Modules -ErrorAction Stop #-Verbose
        Get-ChildItem -Path $WorkingFolder -Recurse | Unblock-File
        Invoke-UpdateDownload -Url "https://go.microsoft.com/fwlink/?linkid=74689" -DestinationPath $Catalog -CheckExpiration
        Get-RootCerts -CertPath $Certificates
        Write-Host "Success! Package ready at: $WorkingFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "[Failure] ($($_.Exception.Message))"
    }
}

#region: -Install
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
    Write-Host "Verifying installation..." -ForegroundColor Gray
    if (Get-Command -Module kbupdate) {
        Write-Host "SUCCESS: kbupdate is ready for use." -ForegroundColor Green
    } else {
        Write-Error "Module could not be loaded. Check Execution Policy."
    }
}

#region: Requirements
$InstallRequired = $Scan, $DownloadUpdates, $DeployUpdates
if ($InstallRequired -contains $true) {
    if (-not (Get-Module -ListAvailable -Name kbupdate)) {
        Install-Module kbupdate -Force -Scope CurrentUser
        Install-Module xWindowsUpdate -Force -Scope CurrentUser
    }
}

#region: -Scan
if ($Scan) {
    Write-Host "--- Operation: Scan ---" -ForegroundColor Gray
    if (-not (Test-Path $Results)) {
        New-Item -ItemType Directory -Path $Results -Force | Out-Null
    }
    $ScanResults = foreach ($Endpoint in $TargetEndpoints) {
        Write-Host "Initiating scan on $Endpoint... " -ForegroundColor Gray -NoNewline
        try{
            $HostResult = Get-KbNeededUpdate -ComputerName $Endpoint -ScanFilePath $Catalog -Force #-Verbose
            $MissingCount = ($HostResult.KBUpdate | Where-Object { $_ } | Sort-Object -Unique).Count
            Write-Host "[Success] ($MissingCount missing)" -ForegroundColor Green
            $HostResult # emit to $ScanResults
        } catch {
            if (Test-Path $Certificates) {
                Write-Host "[Possible Certificate Issue] (Updating Microsoft Root Certificates)" -ForegroundColor Cyan
                Install-RootCerts -ComputerNames $Endpoint -CertPath $Certificates
            }
        }
    }
    if ($ScanResults) {
        $ReportPath = Join-Path $Results -ChildPath "Full_Compliance_Report_$((Get-Date).ToString('yyyyMMdd_HHmm')).csv"
        $MissingKBsPath = Join-Path -Path $Results -ChildPath "MissingKBs_$((Get-Date).ToString('yyyyMMdd_HHmm')).txt"
        $ScanResults | Export-Csv -Path $ReportPath -NoTypeInformation
        $NewKBs = $ScanResults.KBUpdate | Where-Object { $_ } | Sort-Object -Unique
        $NewKBs | Out-File -FilePath $MissingKBsPath
        Write-Host "[Success] (Scan complete. Detailed report saved to $ReportPath)" -ForegroundColor Green
        Write-Host "Copy the ScanResults folder to your online host for downloading." -ForegroundColor Cyan
        if (-not $SkipReport) {
            Import-Csv -Path $ReportPath | Select-Object ComputerName, KBUpdate, Title, Description | Out-GridView
        }
    } else {
        Write-Host "No missing updates found on target host(s)." -ForegroundColor Gray
    }
}

#region: -Download
if ($DownloadUpdates) {
    if (-not $SkipDefender){
        $DefenderPath = Join-Path $WorkingFolder "DefenderUpdates"
        Get-DefenderUpdates -DefenderUpdatesPath $DefenderPath
    }
    Get-RootCerts -CertPath $Certificates
    if (-not $DefenderOnly){
        Write-Host "Checking for wsusscn2.cab updates..." -ForegroundColor Gray -NoNewline
        Invoke-UpdateDownload -Url "https://go.microsoft.com/fwlink/?linkid=74689" -DestinationPath $Catalog -CheckExpiration
        Write-Host "Starting Windows KB downloads..." -ForegroundColor Gray
        # Supports processing both delta compliance reports and full compliance reports
        $LatestReport = Get-ChildItem -Path $Results -Filter "*Compliance_Report_*.csv" | 
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
            foreach ($Url in $AllLinks) {
                Invoke-UpdateDownload -Url $Url -DestinationPath $Repository
            }
        }
        Write-Host "Download complete. Total files in repository: $((Get-ChildItem $Repository).Count)" -ForegroundColor Green
    }
}

#region: -Deploy
if ($DeployUpdates) {
    $DefenderPath = Join-Path $WorkingFolder "DefenderUpdates"
    if (-not $SkipDefender){
        Install-DefenderUpdates -TargetEndpoints $TargetEndpoints -DefenderUpdatesPath $DefenderPath
    }
    if (-not $DefenderOnly) {
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
                    Write-Host "[SKIP] $($Update.KBUpdate) ($FileName) - File not found in Repository." -ForegroundColor Red
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

#region: -DeployLocal
if ($DeployUpdatesLocal) {
    Write-Host "--- Operation: Deploy Updates to Local Host ---" -ForegroundColor Gray
    
    # Process Defender definition updates locally if switch parameter permits
    if (-not $SkipDefender) {
        $DefenderPath = Join-Path $WorkingFolder "DefenderUpdates"
        Install-DefenderUpdates -TargetEndpoints @($env:COMPUTERNAME) -DefenderUpdatesPath $DefenderPath
    }

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
        Write-Host "[Skip] No missing updates found for $LocalHost in this report." -ForegroundColor Gray
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
                    Write-Host "  -> Installing CAB via DISM..." -ForegroundColor Cyan
                    dism.exe /Online /Add-Package /PackagePath:"$LocalPath" /NoRestart
                }
                elseif ($FileName -match "\.exe$") {
                    Write-Host "  -> Running MSRT Tool..." -ForegroundColor Cyan
                    Start-Process -FilePath "$LocalPath" -ArgumentList "/quiet /norestart" -Wait
                }
                elseif ($FileName -match "\.msu$") {
                    Write-Host "  -> Installing via WUSA..." -ForegroundColor Cyan
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

#region: -Delta
if ($DeltaReport) {
    Write-Host "--- Operation: Generate Delta Report ---" -ForegroundColor Gray
    $LatestReport = Get-ChildItem -Path $Results -Filter "Full_Compliance_Report_*.csv" | 
        Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
    if (-not $LatestReport) {
        Write-Error "No Full Compliance Report found in $Results. Please execute a compliance scan first."
    } else {
        Write-Host "Parsing full compliance baseline report: $($LatestReport.FullName)" -ForegroundColor Gray
        $FullUpdates = Import-Csv -Path $LatestReport.FullName
        $DeltaUpdates = [System.Collections.Generic.List[PSCustomObject]]::new()
        $MissingFilesList = [System.Collections.Generic.List[string]]::new()
        foreach ($Row in $FullUpdates) {
            
            # Parse multiple HTTP URLs that may be listed within the single column
            $Links = $Row.Link -split " " | Where-Object { $_ -like "http*" }
            $RowNeedsDownload = $false
            foreach ($Link in $Links) {
                $FileName = Split-Path $Link -Leaf
                $LocalPath = Join-Path $Repository $FileName
                if (-not (Test-Path $LocalPath)) { # patch file is missing from the local Repository
                    $RowNeedsDownload = $true
                    if ($FileName -notin $MissingFilesList) {
                        $MissingFilesList.Add($FileName)
                    }
                }
            }
            if ($RowNeedsDownload) { # Keep row for the delta compliance manifest
                $DeltaUpdates.Add($Row)
            }
        }
        if ($DeltaUpdates.Count -gt 0) {
            $Timestamp = (Get-Date).ToString('yyyyMMdd_HHmm')
            $DeltaReportPath = Join-Path $Results -ChildPath "Delta_Compliance_Report_$Timestamp.csv"
            $DeltaKBsPath = Join-Path $Results -ChildPath "DeltaMissingKBs_$Timestamp.txt"
            $DeltaUpdates | Export-Csv -Path $DeltaReportPath -NoTypeInformation
            $DeltaKBs = $DeltaUpdates.KBUpdate | Where-Object { $_ } | Sort-Object -Unique
            $DeltaKBs | Out-File -FilePath $DeltaKBsPath
            Write-Host "[Success] Delta analysis evaluation completed." -ForegroundColor Green
            Write-Host "Compliance records matching missing downloads: $($DeltaUpdates.Count) entries." -ForegroundColor Gray
            Write-Host "Unique files needing network transfer: $($MissingFilesList.Count)" -ForegroundColor Gray
            Write-Host "Truncated delta compliance CSV saved to: $DeltaReportPath" -ForegroundColor Cyan
            Write-Host "Delta missing KBs list text file saved to: $DeltaKBsPath" -ForegroundColor Cyan
            Write-Host "Export only these delta files to your internet host to finish the updates." -ForegroundColor Cyan
            if (-not $SkipReport) {
                $DeltaUpdates | Select-Object ComputerName, KBUpdate, Title, Description | Out-GridView -Title "Delta Missing Updates"
            }
        } else {
            Write-Host "All needed security updates identified in the compliance report are already cached inside the repository directory." -ForegroundColor Green
        }
    }
}