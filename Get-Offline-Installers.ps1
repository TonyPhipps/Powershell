<#
.SYNOPSIS
    Downloads English 64-bit offline installers for Firefox, Edge, Chrome, Notepad++, and VS Code.
.DESCRIPTION
    Designed with a modular architecture. Uses HEAD requests to inspect redirect filenames
    without downloading payloads, ensuring existing files are skipped instantly.
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
        # Use HEAD request so we only inspect headers/redirects without downloading file bytes
        $request = [System.Net.WebRequest]::Create($Url)
        $request.UserAgent = "PowerShellAppDownloader"
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        
        # 1. Try to extract filename from Content-Disposition header if present
        $fileName = $null
        $contentDisposition = $response.Headers["Content-Disposition"]
        if ($contentDisposition -match 'filename="?([^";]+)"?') {
            $fileName = $Matches[1]
        }
        
        # 2. Otherwise extract from the resolved redirect URL
        if ([string]::IsNullOrWhiteSpace($fileName)) {
            $rawFileName = [System.IO.Path]::GetFileName($response.ResponseUri.AbsolutePath)
            $fileName = [System.Uri]::UnescapeDataString($rawFileName)
        }
        
        $response.Close()

        # 3. Apply fallback if filename resolution failed
        if ([string]::IsNullOrWhiteSpace($fileName) -or -not ($fileName -match '\.')) {
            if ($FallbackFileName) { $fileName = $FallbackFileName }
            else { throw "Unable to resolve filename from server." }
        }

        $outputPath = Join-Path -Path $DestinationDir -ChildPath $fileName

        # Check if file already exists BEFORE downloading
        if (Test-Path -Path $outputPath) {
            Write-Host "File '$fileName' already exists. Skipping download.`n" -ForegroundColor Yellow
            return
        }

        Write-Host "Downloading $fileName..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Url -OutFile $outputPath -UseBasicParsing
        Write-Host "Successfully saved to: $outputPath`n" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to process download for $Url : $_"
    }
}

# ==========================================
# Individual App Installer Functions
# ==========================================

function Get-FirefoxInstaller {
    param([string]$DestinationDir)
    Write-Host "Checking Firefox (64-bit, en-US)..." -ForegroundColor Yellow
    $url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir -FallbackFileName "Firefox Setup.exe"
}

function Get-EdgeInstaller {
    param([string]$DestinationDir)
    Write-Host "Checking Microsoft Edge Enterprise (64-bit MSI)..." -ForegroundColor Yellow
    $url = "https://go.microsoft.com/fwlink/?LinkID=2093437"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir -FallbackFileName "MicrosoftEdgeEnterpriseX64.msi"
}

function Get-ChromeInstaller {
    param([string]$DestinationDir)
    Write-Host "Checking Google Chrome Standalone (64-bit)..." -ForegroundColor Yellow
    $url = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir -FallbackFileName "ChromeStandaloneSetup64.exe"
}

function Get-NotepadPlusPlusInstaller {
    param([string]$DestinationDir)
    Write-Host "Checking Notepad++ (64-bit)..." -ForegroundColor Yellow
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
    Write-Host "Checking VS Code System Installer (64-bit)..." -ForegroundColor Yellow
    $url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
    Invoke-AppDownload -Url $url -DestinationDir $DestinationDir -FallbackFileName "VSCodeSetup-x64.exe"
}

# ==========================================
# Orchestrator & Execution
# ==========================================

function Start-OfflineInstallerDownloads {
    param(
        [string]$DestinationDir = "$env:USERPROFILE\Downloads",
        [string[]]$AppsToDownload = @('Firefox', 'Edge', 'Chrome', 'Notepad++', 'VSCode')
    )

    $appRegistry = @{
        'Firefox'   = { param($dir) Get-FirefoxInstaller -DestinationDir $dir }
        'Edge'      = { param($dir) Get-EdgeInstaller -DestinationDir $dir }
        'Chrome'    = { param($dir) Get-ChromeInstaller -DestinationDir $dir }
        'Notepad++' = { param($dir) Get-NotepadPlusPlusInstaller -DestinationDir $dir }
        'VSCode'    = { param($dir) Get-VSCodeInstaller -DestinationDir $dir }
    }

    Write-Host "Starting offline installer process in: $DestinationDir`n" -ForegroundColor DarkCyan

    foreach ($appName in $AppsToDownload) {
        if ($appRegistry.ContainsKey($appName)) {
            & $appRegistry[$appName] $DestinationDir
        } else {
            Write-Warning "No installer registered for: '$appName'"
        }
    }
}

# Run script to download or skip existing installers
Start-OfflineInstallerDownloads