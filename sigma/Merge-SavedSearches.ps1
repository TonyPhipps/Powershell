<#
.SYNOPSIS
    Merges fragmented Splunk configuration files (e.g., pipeline outputs) into a single configuration file.

.DESCRIPTION
    Scans a directory for configuration files matching a specific filter (default: *_rules.conf').
    Parses stanzas, deduplicates them (warning on duplicates), and handles the [default] stanza 
    by ensuring it appears at the top of the file.
    
    The final output is written with UTF-8 encoding (No BOM).

.PARAMETER SourcePath
    The directory containing the configuration fragments.

.PARAMETER OutputFilename
    The name of the resulting merged file. Default is 'savedsearches.conf'.

.PARAMETER FileFilter
    The filter to apply when searching for source files. Default is '*_rules.conf'.

.EXAMPLE
    .\Merge-SavedSearches.ps1 -SourcePath "C:\Splunk\Output"
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$SourcePath,

    [Parameter(Position = 1)]
    [string]$OutputFilename = 'savedsearches.conf',

    [Parameter(Position = 2)]
    [string]$FileFilter = '*_rules.conf'
)

Process {
    Write-Host "Starting merge process in: $SourcePath"

    # Gather Files
    $confFiles = Get-ChildItem -Path $SourcePath -Filter $FileFilter -File
    
    if ($confFiles.Count -eq 0) {
        Write-Warning "No files found matching '$FileFilter' in '$SourcePath'. Exiting."
        return
    }

    Write-Host "Found $($confFiles.Count) files to merge."

    # Initialize Collections
    [System.Collections.ArrayList]$outputContent = @()
    [System.Collections.Hashtable]$stanzas = @{}

    # Process Files
    ForEach ($file in $confFiles) {
        $fileContent = Get-Content -Path $file.FullName -Encoding UTF8
        $currentStanza = ''
        $fileStanzaCount = 0 
        
        ForEach ($line in $fileContent) {
            # Check for Stanza Header
            if ($line -match '^\[') {
                $currentStanza = $line
                
                # If Stanza doesn't exist in our hash, add it
                if ($null -eq $stanzas[$currentStanza]) {
                    $stanzas[$currentStanza] = [System.Collections.ArrayList]@($line)
                    if ($currentStanza -notmatch "\[default\]") { $fileStanzaCount++ }
                } 
                else {
                    # Handle Duplicates
                    if ($currentStanza -match "\[default\]") {
                        # For [default], we verify standard Splunk behavior implies merging or last-wins. 
                        # This script resets [default] if encountered again (Last Wins approach).
                        $stanzas[$currentStanza] = [System.Collections.ArrayList]@($line)
                    } else {
                        Write-Warning "Duplicate Stanza Detected: $($currentStanza) | Overwriting with stanza from: $($file.Name)"
                        # Note: Logic here allows overwrite. If you want to skip, change below line.
                        $stanzas[$currentStanza] = [System.Collections.ArrayList]@($line) 
                    }
                }
            } 
            # Add content lines to the currently active stanza
            elseif (-not [string]::IsNullOrWhiteSpace($currentStanza)) {
                $stanzas[$currentStanza].Add($line) > $null        
            }
        }
        Write-Host "Processed $fileStanzaCount stanza(s) from file $($file.Name)"
    }

    # Construct Output Order ([default] first, then alphabetical)
    
    # Handle [default]
    if ($null -ne $stanzas['[default]']) {
        ForEach ($line in $stanzas['[default]']) {
            $outputContent.Add($line) > $null
        }
    } else {
        Write-Warning "No [default] stanza found - savedsearches will not run."
    }

    # Handle remaining stanzas sorted alphabetically
    $sortedStanzas = $stanzas.Keys | Where-Object { $_ -notmatch "\[default\]" } | Sort-Object

    ForEach ($stanza in $sortedStanzas) {
        ForEach ($line in $stanzas[$stanza]) {
            $outputContent.Add($line) > $null
        }
    }

    Write-Host "Merged $($sortedStanzas.Count) unique stanzas (excluding default)." -ForegroundColor Green

    # Write to File (UTF8 No BOM)
    $OutputFileFullPath = Join-Path -Path $SourcePath -ChildPath $OutputFilename
    
    # Resolve absolute path for .NET method
    # Ensure directory exists (it should, based on param validation, but good practice)
    if (-not (Test-Path $SourcePath)) { New-Item -Path $SourcePath -ItemType Directory | Out-Null }
    
    # Prepare Content
    [String]$outputContentRaw = ($outputContent -join "`n") + "`n"
    
    # Write using .NET to force NoBOM
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    try {
        [System.IO.File]::WriteAllText($OutputFileFullPath, $outputContentRaw, $Utf8NoBomEncoding)
        Write-Host "Successfully created: $OutputFileFullPath" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to write file: $_"
    }
}