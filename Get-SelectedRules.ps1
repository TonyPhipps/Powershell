﻿# Given a csv of selected ID's for sigma rules, copy those rules from a sigma-master repo download into another folder for further processing.

param (
    [string]$Rules,
    [string]$SelectedIDs
)

# Set variables
$csvPath = "C:\path\to\selected_ids.csv"
$sourceRoot = "C:\path\to\sigma-master\rules"
$destinationRoot = "C:\path-to\sigma-master\select_rules"

# Import strings from CSV
$stringsToFind = Import-Csv $csvPath | Select-Object -ExpandProperty *

# Get all files recursively
$files = Get-ChildItem $sourceRoot -Recurse | Where-Object { !$_.PSIsContainer }

# Loop through each file
foreach ($file in $files) {
    # Read the content of the file
    $content = Get-Content $file.FullName

    # Check if any of the strings exist in the file content
    foreach ($string in $stringsToFind) {
        if ($content -match $string) {
            # Build destination path, maintaining folder structure
            $relativePath = $file.FullName.Substring($sourceRoot.Length).TrimStart("\")
            $destinationPath = Join-Path $destinationRoot $relativePath
            $destinationDir = Split-Path $destinationPath

            # Create the destination directory if it doesn't exist
            if (!(Test-Path -Path $destinationDir)) {
                New-Item -ItemType Directory -Force -Path $destinationDir
            }

            # Copy the file
            Copy-Item $file.FullName -Destination $destinationPath

            # Break inner loop once a match is found and file is copied
            break
        }
    }
}