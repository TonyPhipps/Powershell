param (
    [string]$SourceParentFolder,  # Parent folder containing the source files
    [string]$DestinationFolder,   # Target folder to copy files to
    [string]$PathListFile         # File containing list of relative paths
)

# Read the list of relative paths
$relativePaths = Get-Content -Path $PathListFile

foreach ($relativePath in $relativePaths) {
    # Construct full source path with wildcard support
    $sourcePath = Join-Path -Path $SourceParentFolder -ChildPath $relativePath

    # Get all matching files for the wildcard pattern
    $sourceFiles = Get-ChildItem -Path $sourcePath -File -ErrorAction SilentlyContinue

    if ($sourceFiles) {
        foreach ($sourceFile in $sourceFiles) {
            # Calculate the relative path for this specific file
            $fileRelativePath = $sourceFile.FullName.Substring($SourceParentFolder.Length + 1)
            $destPath = Join-Path -Path $DestinationFolder -ChildPath $fileRelativePath

            # Create destination directory if it doesn't exist
            $destDir = Split-Path -Path $destPath -Parent
            if (-not (Test-Path -Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }

            # Copy the file
            Copy-Item -Path $sourceFile.FullName -Destination $destPath -Force
            Write-Host "Copied: $fileRelativePath"
        }
    } else {
        Write-Warning "No files found matching: $relativePath"
    }
}