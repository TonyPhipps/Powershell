<#
.SYNOPSIS
    Downloads English 64-bit offline installers for Firefox, Edge, Chrome, Notepad++, and VS Code.
.DESCRIPTION
    Designed with a modular architecture. New application installers can easily be 
    added by writing a function and registering it in the $appRegistry hashtable.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==========================================
# Core Helper Function
# ==========================================
function Invoke-AppDownload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string]$DestinationDir = "$env:USERPROFILE\Downloads",

        [Parameter(Mandatory = $false)]
        [string]$FallbackFileName = $null
    )

    if (-not (Test-Path -Path $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    }

    try {
        # Resolve official filename from redirect headers
        $request = [System.Net.WebRequest]::Create($Url)
        $request.UserAgent = "PowerShellAppDownloader"
        $response = $request.GetResponse()
        
        $rawFileName = [System.IO.Path]::GetFileName($response.ResponseUri.AbsolutePath)
        $fileName = [System.Uri]::UnescapeDataString($rawFileName)
        $response.Close()

        # Fallback if the redirect URL doesn't present a full filename
        if ([string]::IsNullOrWhiteSpace($fileName) -or -not ($fileName -match '\.')) {
            if ($FallbackFileName) { $fileName = $FallbackFileName }
            else { throw "Unable to resolve filename from header." }
        }

        $outputPath = Join-Path -Path $DestinationDir -ChildPath $fileName
        Write-Host "Downloading $fileName..." -ForegroundColor Cyan
        
        Invoke-WebRequest -Uri $Url -OutFile $outputPath -UseBasicParsing
        Write-Host "Successfully saved to: $outputPath`n" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download from $Url : $_"
    }
}

# ==========================================
# Individual App Installer Functions
# ==========================================

function Get-FirefoxInstaller {
    param([string]$DestinationDir)
    Write-Host "Fetching Firefox (64-bit, en-US)..." -ForegroundColor Yellow
    $url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir
}

function Get-EdgeInstaller {
    param([string]$DestinationDir)
    Write-Host "Fetching Microsoft Edge Enterprise (64-bit MSI)..." -ForegroundColor Yellow
    $url = "https://go.microsoft.com/fwlink/?LinkID=2093437"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir
}

function Get-ChromeInstaller {
    param([string]$DestinationDir)
    Write-Host "Fetching Google Chrome Standalone (64-bit)..." -ForegroundColor Yellow
    # Direct offline setup URL for Chrome 64-bit
    $url = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir -FallbackFileName "ChromeStandaloneSetup64.exe"
}

function Get-NotepadPlusPlusInstaller {
    param([string]$DestinationDir)
    Write-Host "Fetching Notepad++ (64-bit)..." -ForegroundColor Yellow
    try {
        $apiUri = "https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUri -UserAgent "PowerShellAppDownloader"
        $asset = $release.assets | Where-Object { $_.name -like "*Installer.x64.exe" } | Select-Object -First 1
        
        if ($asset) {
            Invoke-AppDownload -Url $asset.browser_download_url -DestinationDir $DestinationDir -FallbackFileName $asset.name
        } else {
            Write-Error "64-bit installer asset not found in latest Notepad++ release."
        }
    }
    catch {
        Write-Error "Failed to resolve Notepad++ download: $_"
    }
}

function Get-VSCodeInstaller {
    param([string]$DestinationDir)
    Write-Host "Fetching VS Code System Installer (64-bit)..." -ForegroundColor Yellow
    # Windows x64 System Offline Setup
    $url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir
}

# ==========================================
# Orchestrator & Execution
# ==========================================

function Start-OfflineInstallerDownloads {
    param(
        [string]$DestinationDir = "$env:USERPROFILE\Downloads",
        [string[]]$AppsToDownload = @('Firefox', 'Edge', 'Chrome', 'Notepad++', 'VSCode')
    )

    # Master registry mapping application keys to download functions
    $appRegistry = @{
        'Firefox'   = { param($dir) Get-FirefoxInstaller -DestinationDir $dir }
        'Edge'      = { param($dir) Get-EdgeInstaller -DestinationDir $dir }
        'Chrome'    = { param($dir) Get-ChromeInstaller -DestinationDir $dir }
        'Notepad++' = { param($dir) Get-NotepadPlusPlusInstaller -DestinationDir $dir }
        'VSCode'    = { param($dir) Get-VSCodeInstaller -DestinationDir $dir }
    }

    Write-Host "Starting offline installer downloads to: $DestinationDir`n" -ForegroundColor DarkCyan

    foreach ($appName in $AppsToDownload) {
        if ($appRegistry.ContainsKey($appName)) {
            & $appRegistry[$appName] $DestinationDir
        } else {
            Write-Warning "No installer registered for: '$appName'"
        }
    }
}

# Run script to download all listed installers
Start-OfflineInstallerDownloads