# Given a csv of selected ID's for sigma rules, copy those rules from a sigma-master repo download into another folder for further processing.
# .\Copy-SigmaRuleByID.ps1 -SelectedIDs "selected_ids.csv" -SigmaRules "D:\github\sigma\rules" -output ".\selected_rules"

param (
    [Parameter(Mandatory=$true)][string]$SelectedIDs,
    [Parameter(Mandatory=$true)][string]$SigmaRules,
    [Parameter(Mandatory=$true)][string]$Output
)

if ( ($psISE) -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
} else {
    $ScriptRoot = $PSScriptRoot
}

if (not $Output){
    $Output = "$SCriptRoot\selected_rules"
}

# Import strings from CSV
$stringsToFind = Import-Csv $SelectedIDs | Select-Object -ExpandProperty *

# Get all files recursively
$files = Get-ChildItem $SigmaRules -Recurse | Where-Object { !$_.PSIsContainer }

# Loop through each file
foreach ($file in $files) {
    # Read the content of the file
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Check if any of the strings exist in the file content
    foreach ($string in $stringsToFind) {
        if ($content -match $string) {
            # Build destination path, maintaining folder structure
            $relativePath = $file.FullName.Substring($SigmaRules.Length).TrimStart("\")
            $destinationPath = Join-Path $Output $relativePath
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