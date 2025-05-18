# PowerShell script to back up all Blender configurations on Windows

# Parameters
$BackupDestination = "F:\GoogleDrive\Tony\Backups"  # Change this to your desired backup location
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupRootFolder = Join-Path -Path $BackupDestination -ChildPath "BlenderBackup_$Timestamp"

# Paths
$UserProfile = $env:USERPROFILE
$BlenderRootPath = "$UserProfile\AppData\Roaming\Blender Foundation\Blender"

# Function to check if a path exists
function Test-PathExists {
    param ($Path)
    if (-not (Test-Path $Path)) {
        Write-Host "Path $Path does not exist!" -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Check if Blender root path exists
if (-not (Test-PathExists -Path $BlenderRootPath)) {
    Write-Host "Error: No Blender configurations found at $BlenderRootPath" -ForegroundColor Red
    exit 1
}

# Create backup root folder
try {
    New-Item -ItemType Directory -Path $BackupRootFolder -Force | Out-Null
    Write-Host "Created backup root folder: $BackupRootFolder" -ForegroundColor Green
} catch {
    Write-Host "Error creating backup folder: $_" -ForegroundColor Red
    exit 1
}

# Get all Blender version folders
$VersionFolders = Get-ChildItem -Path $BlenderRootPath -Directory | Where-Object { $_ -match "^\d+\.\d+" }

if ($VersionFolders.Count -eq 0) {
    Write-Host "Error: No Blender version folders found in $BlenderRootPath" -ForegroundColor Red
    exit 1
}

# Iterate through each version folder and back up config and add-ons
foreach ($Version in $VersionFolders) {
    $VersionName = $Version.Name
    $BlenderConfigPath = Join-Path -Path $BlenderRootPath -ChildPath "$VersionName\config"
    $BlenderAddonsPath = Join-Path -Path $BlenderRootPath -ChildPath "$VersionName\scripts\addons"
    $VersionBackupFolder = Join-Path -Path $BackupRootFolder -ChildPath $VersionName

    # Create version-specific backup folder
    try {
        New-Item -ItemType Directory -Path $VersionBackupFolder -Force | Out-Null
        Write-Host "Created backup folder for version $VersionName at $VersionBackupFolder" -ForegroundColor Green
    } catch {
        Write-Host "Error creating backup folder for version $($VersionName): $_" -ForegroundColor Red
        continue
    }

    # Back up configuration folder and its files (userpref.blend, startup.blend, keymap.py, etc.)
    if (Test-PathExists -Path $BlenderConfigPath) {
        try {
            # Create config directory in backup
            $ConfigBackupPath = Join-Path -Path $VersionBackupFolder -ChildPath "config"
            New-Item -ItemType Directory -Path $ConfigBackupPath -Force | Out-Null
            # Copy all files and subdirectories from config folder
            Copy-Item -Path "$BlenderConfigPath\*" -Destination $ConfigBackupPath -Recurse -Force
            Write-Host "Backed up configuration files (userpref.blend, startup.blend, keymap.py) for version $VersionName to $ConfigBackupPath" -ForegroundColor Green
        } catch {
            Write-Host "Error backing up config files for version $($VersionName): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No config folder found for version $VersionName" -ForegroundColor Yellow
    }

    # Back up add-ons folder
    if (Test-PathExists -Path $BlenderAddonsPath) {
        try {
            Copy-Item -Path $BlenderAddonsPath -Destination "$VersionBackupFolder\addons" -Recurse -Force
            Write-Host "Backed up add-ons for version $VersionName" -ForegroundColor Green
        } catch {
            Write-Host "Error backing up add-ons for version $($VersionName): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No add-ons folder found for version $VersionName" -ForegroundColor Yellow
    }
}

Write-Host "Backup completed successfully at $BackupRootFolder" -ForegroundColor Green