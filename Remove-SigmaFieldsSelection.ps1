<#
.SYNOPSIS
    Removes the 'fields' section from YAML files in the specified directory and its subdirectories.

.DESCRIPTION
    This script recursively searches for .yml files in the specified parent directory and removes
    the 'fields' section, including any nested content under it, while preserving the rest of the file.

.PARAMETER ParentDir
    The root directory to search for .yml files. This parameter is mandatory.

.EXAMPLE
    .\Remove-FieldsSelection.ps1 -ParentDir "D:\github\sigma\rules"
    Processes all .yml files in the specified directory and removes their 'fields' sections.

.NOTES
    Author: Tony Phipps
    Version: 1.0
    Date: 2025-07-30
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The root directory containing .yml files to process.")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$ParentDir
)

# Function to process a single YAML file
function Remove-FieldsSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Read the file content
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Check if file contains 'fields:'
        if ($content -match 'fields:') {
            # Split content into lines
            $lines = $content -split '\r?\n'
            $newLines = @()
            $skip = $false
            $indentLevel = 0

            foreach ($line in $lines) {
                # Check if line starts with 'fields:'
                if ($line -match '^\s*fields:') {
                    $skip = $true
                    # Get indentation level of fields
                    $indentLevel = ($line | Select-String '^(\s*)').Matches.Groups[1].Value.Length
                    continue
                }
                
                # Skip indented lines after fields
                if ($skip -and ($line -match '^\s*-\s') -and ($line | Select-String '^(\s*)').Matches.Groups[1].Value.Length -gt $indentLevel) {
                    continue
                }
                
                # Stop skipping when we reach a line with same or less indentation as fields
                if ($skip -and -not ($line -match '^\s*-\s') -and ($line.Trim() -ne '')) {
                    $skip = $false
                }
                
                if (-not $skip) {
                    $newLines += $line
                }
            }
            
            # Write modified content back to file
            $newContent = $newLines -join "`n"
            Set-Content -Path $FilePath -Value $newContent -Force -ErrorAction Stop
            Write-Host "Processed out `"Fields`": $FilePath"
        } else {
            Write-Verbose "No `"Fields`" section found in: $FilePath"
        }
    }
    catch {
        Write-Error "Error processing '$FilePath': $($_.Exception.Message)"
    }
}

# Validate that the parent directory exists
if (-not (Test-Path -Path $ParentDir -PathType Container)) {
    Write-Error "The specified directory '$ParentDir' does not exist or is not a directory."
    exit 1
}

# Find all .yml files in parent directory and subdirectories
try {
    $yamlFiles = Get-ChildItem -Path $ParentDir -Recurse -Include *.yml -ErrorAction Stop
}
catch {
    Write-Error "Error retrieving .yml files from '$ParentDir': $($_.Exception.Message)"
    exit 1
}

# Process each YAML file
$processedCount = 0
foreach ($file in $yamlFiles) {
    Remove-FieldsSection -FilePath $file.FullName -Verbose
    $processedCount++
}

Write-Host "Processing complete. Processed $processedCount YAML file(s)."