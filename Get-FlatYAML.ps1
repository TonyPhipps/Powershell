<#
.SYNOPSIS
    Converts YAML files to CSV format from a specified directory.

.DESCRIPTION
    This script processes YAML files in the specified input directory, converts them to a flat structure,
    and exports the results to a CSV file. It requires the powershell-yaml module.

.PARAMETER InputDir
    The directory containing YAML files to process. Defaults to 'yaml-files' folder in the parent directory.

.PARAMETER OutputFile
    The path for the output CSV file. Defaults to 'flattened-yaml.csv' in the script's directory.

.PARAMETER IgnoreFields
    One or more dotted field paths to ignore (and all of their child fields). Case-insensitive.
    Examples:
      -IgnoreFields detection
      -IgnoreFields detection, logsource.product, metadata.internal.id

.EXAMPLE
    .\Get-FlatYAML.ps1 -InputDir "C:\yaml-files" -OutputFile "C:\Output\flattened-yaml.csv"

.EXAMPLE
    .\Get-FlatYAML.ps1 -IgnoreFields detection
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$InputDir,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = (Join-Path -Path $PSScriptRoot -ChildPath 'flattened-yaml.csv'),

    [Parameter(Mandatory=$false)]
    [string[]]$IgnoreFields = @()
)

begin {
    # Determine script root directory
    if ($psISE -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
        $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
    } else {
        $ScriptRoot = $PSScriptRoot
    }

    # Set default InputDir if not provided
    if (-not $InputDir) {
        $ScriptParent = Split-Path -Path $ScriptRoot -Parent
        $InputDir = Join-Path -Path $ScriptParent -ChildPath 'yaml-files'
    }

    # Normalize ignore list (lower-case, trim trailing .* for convenience)
    $IgnoreNorm = @()
    foreach ($p in $IgnoreFields) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $q = $p.Trim()
        if ($q.EndsWith('.*')) { $q = $q.Substring(0, $q.Length-2) }
        $IgnoreNorm += $q.ToLowerInvariant()
    }

    function Should-IgnorePath {
    param(
        [string]$Path  # allow null/empty safely
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $lp = $Path.ToLowerInvariant()
    foreach ($prefix in $IgnoreNorm) {
        if ($lp -eq $prefix -or $lp.StartsWith("$prefix.")) {
            return $true
        }
    }
    return $false
}

    function Get-FlatYAML {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $InputObject,

        [String]$InputFileName
    )

    $Output = [pscustomobject]@{}

    function Add-Flat {
        param(
            $Value,
            [string]$Path = $null   # <-- default to $null (not mandatory)
        )

        if (Should-IgnorePath -Path $Path) {
            return
        }

        if ($null -eq $Value) { return }

        if ($Value -is [Hashtable]) {
            foreach ($k in $Value.Keys) {
                $childPath = if ($Path) { "$Path.$k" } else { "$k" }
                Add-Flat -Value $Value[$k] -Path $childPath
            }
            return
        }

        if ($Value -is [psobject] -and $Value.PSObject.Properties.Name.Count -gt 0) {
            foreach ($prop in $Value.PSObject.Properties) {
                $childPath = if ($Path) { "$Path.$($prop.Name)" } else { "$($prop.Name)" }
                Add-Flat -Value $prop.Value -Path $childPath
            }
            return
        }

        if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
            $joined = ($Value | ForEach-Object {
                if ($_ -eq $null) { '' } else { [string]$_ }
            }) -join ', '
            if ($Path) {
                try { $Output | Add-Member -MemberType NoteProperty -Name $Path -Value $joined -ErrorAction Stop } catch {}
            }
            return
        }

        $typeName = $Value.GetType().Name
        if ($typeName -in @('String','Int32','Int64','Boolean','Double','Decimal','Single','Byte')) {
            if ($Path) {
                try { $Output | Add-Member -MemberType NoteProperty -Name $Path -Value $Value -ErrorAction Stop } catch {}
            }
            return
        }

        if ($Path) {
            try { $Output | Add-Member -MemberType NoteProperty -Name $Path -Value ([string]$Value) -ErrorAction Stop } catch {}
        }
    }

    # Start recursive flatten WITHOUT passing an empty Path
    Add-Flat -Value $InputObject

    if ($InputFileName){
        $Original = Get-Content ($InputFileName) -Raw
        try { $Output | Add-Member -MemberType NoteProperty -Name "Original" -Value $Original -ErrorAction Stop } catch {}
        try { $Output | Add-Member -MemberType NoteProperty -Name "Filepath" -Value $InputFileName -ErrorAction Stop } catch {}
    }

    return $Output
}

    # Initialize variables
    $CSV = [System.Collections.Generic.List[PSObject]]::new()

    # Install required module
    try {
        if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
            Write-Verbose "Installing powershell-yaml module..."
            Install-Module powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop
        }
        Import-Module powershell-yaml -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to install or import powershell-yaml module: $_"
        exit 1
    }
}

process {
    try {
        # Validate input directory
        if (-not (Test-Path $InputDir -PathType Container)) {
            Write-Error "Input directory '$InputDir' does not exist"
            exit 1
        }

        # Get YAML files with both .yml and .yaml extensions, including hidden files
        $Files = Get-ChildItem -Path $InputDir -Recurse -Include '*.yml', '*.yaml' -File -Force -ErrorAction Stop

        if ($Files.Count -eq 0) {
            Write-Warning "No YAML files (.yml or .yaml) found in '$InputDir' or its subdirectories"
            return
        }

        # Initialize List for CSV output
        $CSV = [System.Collections.Generic.List[PSObject]]::new()

        # Process each YAML file
        foreach ($File in $Files) {
            try {
                $FullName = $File.FullName
                Write-Verbose "Processing file: $FullName"
                $YAML = ConvertFrom-Yaml (Get-Content $FullName -Raw -ErrorAction Stop)
                $CSV.Add((Get-FlatYAML -InputObject $YAML -InputFileName $FullName))
            }
            catch {
                Write-Warning "Failed to process file '$FullName': $_"
                continue
            }
        }

        # Export to CSV
        if ($CSV.Count -gt 0) {
            $allProperties = @()
            $CSV | ForEach-Object {
                $_.PSObject.Properties | ForEach-Object {
                    # keep only properties with a value (string non-whitespace or non-string non-null)
                    if ($_.Value -ne $null -and (($_.Value -is [string] -and -not [string]::IsNullOrWhiteSpace($_.Value)) -or -not ($_.Value -is [string]))) {
                        $allProperties += $_.Name
                    }
                }
            }
            $uniqueProperties = $allProperties | Select-Object -Unique
            $CSV |
                Select-Object -Property $uniqueProperties -ErrorAction SilentlyContinue |
                Export-Csv -Path $OutputFile -NoTypeInformation -ErrorAction Stop
            Write-Verbose "Successfully exported $($CSV.Count) records to '$OutputFile'"
        }
        else {
            Write-Warning "No valid YAML data to export"
        }
    }
    catch {
        Write-Error "An error occurred during processing: $_"
        exit 1
    }
}
