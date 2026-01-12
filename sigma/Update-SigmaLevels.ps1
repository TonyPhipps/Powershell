<#
.SYNOPSIS
    Updates Sigma rule severity levels based on a CSV mapping.

.DESCRIPTION
    1. Reads a directory of Sigma rules (.yml) and maps their IDs to file paths.
    2. Reads a CSV file containing GUIDs and a 'newlevel' column.
    3. If a GUID matches, updates the 'level' field in the YAML file.

.PARAMETER CsvPath
    Path to the CSV file. Must contain headers "id" and "newlevel" (or 4th column).
    
.PARAMETER RulesDirectory
    Path to the folder containing .yml Sigma rules.

.EXAMPLE
    .\Update-SigmaLevels.ps1 -CsvPath "C:\Temp\updates.csv" -RulesDirectory "C:\Sigma\Rules"
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true)]
    [string]$CSV,

    [Parameter(Mandatory=$true)]
    [string]$RulesDirectory
)

$ValidLevels = @("informational", "low", "medium", "high", "critical")

# Build a Lookup Table of existing Rules (ID -> FilePath)
Write-Host "Scanning rules directory: $RulesDirectory" -ForegroundColor Cyan
$RuleMap = @{}
$YamlFiles = Get-ChildItem -Path $RulesDirectory -Filter "*.yml" -Recurse

foreach ($file in $YamlFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    # Look for "id:" followed by whitespace and a generic UUID pattern
    if ($content -match '(?m)^id:\s*["'']?([a-fA-F0-9-]{36})["'']?') {
        $id = $matches[1]
        if (-not $RuleMap.ContainsKey($id)) {
            $RuleMap[$id] = $file.FullName
        } else {
            Write-Warning "Duplicate ID found: $id in $($file.Name). Skipping duplicate."
        }
    }
}
Write-Host "Found $($RuleMap.Count) rules with valid IDs." -ForegroundColor Green

# Process the CSV
Write-Host "Reading CSV..." -ForegroundColor Cyan
$CsvData = Import-Csv -Path $CSV
foreach ($row in $CsvData) {
    $TargetID = $row.id
    $NewLevel = $row.newlevel
    if ([string]::IsNullOrWhiteSpace($TargetID) -or [string]::IsNullOrWhiteSpace($NewLevel)) { continue } # Skip if guid is missing
    if ($RuleMap.ContainsKey($TargetID)) {
        $FilePath = $RuleMap[$TargetID]
        if ($NewLevel -notin $ValidLevels) { # Validate Level
            Write-Warning "Invalid level '$NewLevel' for ID $TargetID. Skipping."
            continue
        }
        # Perform the update
        if ($PSCmdlet.ShouldProcess($FilePath, "Update Level to '$NewLevel'")) {
            $FileContent = Get-Content -Path $FilePath
            $NewContent = @()
            $Updated = $false
            foreach ($line in $FileContent) { 
                if ($line -match '^\s*level:\s*.*$') { # Regex to match the 'level:' line (anchored to start, handles whitespace)
                    $NewContent += "level: $NewLevel"
                    $Updated = $true
                }
                else {
                    $NewContent += $line
                }
            }
            if ($Updated) {
                Set-Content -Path $FilePath -Value $NewContent -Encoding UTF8
                Write-Host "Updated: $($FilePath | Split-Path -Leaf) -> $NewLevel" -ForegroundColor Gray
            } else {
                Write-Warning "File found for $TargetID but could not find 'level:' key to replace."
            }
        }
    }
    else {
        Write-Verbose "ID $TargetID not found in rules directory."
    }
}
Write-Host "Done." -ForegroundColor Cyan