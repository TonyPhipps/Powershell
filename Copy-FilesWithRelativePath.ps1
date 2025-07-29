<#
.SYNOPSIS
    Copies files from a source folder to a destination folder based on a list of relative paths or filenames.

.DESCRIPTION
    This script reads a list of relative file paths or filenames from a specified file and copies matching files
    from a source parent folder to a destination folder while maintaining the directory structure.
    Supports wildcard patterns in the path list. Use -FileNameOnly to match only filenames regardless of their path.

.PARAMETER SourceParentFolder
    The parent folder containing the source files to be copied.

.PARAMETER DestinationFolder
    The target folder where files will be copied to.

.PARAMETER PathListFile
    The file containing a list of relative paths or filenames to copy (one per line).

.PARAMETER FileNameOnly
    Switch to match only filenames from PathListFile, ignoring their paths, searching recursively in SourceParentFolder.

.EXAMPLE
    .\CopyFilesByPathList.ps1 -SourceParentFolder "C:\Source" -DestinationFolder "D:\Backup" -PathListFile "C:\paths.txt"
    Copies files listed in paths.txt from C:\Source to D:\Backup using relative paths.

.EXAMPLE
    .\CopyFilesByPathList.ps1 -SourceParentFolder "C:\Source" -DestinationFolder "D:\Backup" -PathListFile "C:\paths.txt" -FileNameOnly
    Copies files listed in paths.txt from C:\Source to D:\Backup matching only filenames regardless of their path.

.NOTES
    Author: Tony Phipps
    Date: 2025
    Version: 1.1
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Parent folder containing the source files")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$SourceParentFolder,

    [Parameter(Mandatory = $true, HelpMessage = "Target folder to copy files to")]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationFolder,

    [Parameter(Mandatory = $true, HelpMessage = "File containing list of relative paths or filenames")]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$PathListFile,

    [Parameter(HelpMessage = "Match only filenames, ignoring paths, searching recursively")]
    [switch]$FileNameOnly
)

# Ensure source path ends with a backslash for consistent path calculations
$SourceParentFolder = $SourceParentFolder.TrimEnd('\') + '\'

try {
    # Read the list of relative paths or filenames
    Write-Verbose "Reading path list from: $PathListFile"
    $relativePaths = Get-Content -Path $PathListFile -ErrorAction Stop

    if (-not $relativePaths) {
        Write-Warning "Path list file is empty"
        return
    }

    $copiedCount = 0
    $skippedCount = 0

    foreach ($entry in $relativePaths) {
        # Skip empty or whitespace-only lines
        if ([string]::IsNullOrWhiteSpace($entry)) {
            Write-Verbose "Skipping empty entry"
            continue
        }

        try {
            if ($FileNameOnly) {
                # Extract just the filename from the entry (handles cases where paths are provided)
                $fileName = Split-Path -Path $entry -Leaf
                # Search recursively for files matching the filename
                $sourceFiles = Get-ChildItem -Path $SourceParentFolder -Recurse -File -Include $fileName -ErrorAction Stop
            }
            else {
                # Construct full source path with wildcard support
                $sourcePath = Join-Path -Path $SourceParentFolder -ChildPath $entry.Trim()
                # Get all matching files for the path (supports wildcards)
                $sourceFiles = Get-ChildItem -Path $sourcePath -File -ErrorAction Stop
            }

            if ($sourceFiles) {
                foreach ($sourceFile in $sourceFiles) {
                    try {
                        # Calculate the relative path for this specific file
                        $fileRelativePath = $sourceFile.FullName.Substring($SourceParentFolder.Length)
                        $destPath = Join-Path -Path $DestinationFolder -ChildPath $fileRelativePath

                        # Create destination directory if it doesn't exist
                        $destDir = Split-Path -Path $destPath -Parent
                        if (-not (Test-Path -Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force -ErrorAction Stop | Out-Null
                            Write-Verbose "Created directory: $destDir"
                        }

                        # Copy the file
                        Copy-Item -Path $sourceFile.FullName -Destination $destPath -Force -ErrorAction Stop
                        Write-Verbose "Successfully copied: $fileRelativePath"
                        $copiedCount++
                    }
                    catch {
                        Write-Warning "Failed to copy '$fileRelativePath': $($_.Exception.Message)"
                        $skippedCount++
                    }
                }
            }
            else {
                Write-Warning "No files found matching: $entry"
                $skippedCount++
            }
        }
        catch {
            Write-Warning "Error processing entry '$entry': $($_.Exception.Message)"
            $skippedCount++
        }
    }

    # Summary
    Write-Verbose "Copy operation completed. Files copied: $copiedCount, Files skipped/failed: $skippedCount"
}
catch {
    Write-Error "Script terminated due to error: $($_.Exception.Message)"
    exit 1
}
finally {
    Write-Host "Script execution completed"
}