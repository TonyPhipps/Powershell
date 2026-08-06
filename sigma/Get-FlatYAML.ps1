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

.PARAMETER Fields
    One or more dotted field paths specifying EXACTLY which columns appear in the output CSV,
    and in what order. Case-insensitive; the header text/casing in the CSV matches what you type here.
    When supplied, only these columns are exported (unless -AppendUnspecifiedFields is also used).
    A requested field that isn't present in the data produces an empty column, which keeps the
    column layout consistent across runs.
    Two special columns are available: "Original" (raw file contents) and "Filepath".
    Examples:
      -Fields title, logsource.product, level
      -Fields id, title, description, Filepath

.PARAMETER AppendUnspecifiedFields
    Only meaningful together with -Fields. After the columns you listed in -Fields, append any other
    discovered fields (that contain a value) in discovery order. Useful when you want a few known
    columns pinned to the front and everything else after them.

.EXAMPLE
    .\Get-FlatYAML.ps1 -InputDir "C:\yaml-files" -OutputFile "C:\Output\flattened-yaml.csv"

.EXAMPLE
    .\Get-FlatYAML.ps1 -IgnoreFields detection

.EXAMPLE
    # Output only these columns, in this exact order
    .\Get-FlatYAML.ps1 -Fields title, logsource.product, level, Filepath

.EXAMPLE
    # Pin a few columns to the front, then include everything else
    .\Get-FlatYAML.ps1 -Fields title, level -AppendUnspecifiedFields
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$InputDir,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = (Join-Path -Path $PSScriptRoot -ChildPath 'flattened-yaml.csv'),

    [Parameter(Mandatory=$false)]
    [string[]]$IgnoreFields = @(),

    [Parameter(Mandatory=$false)]
    [Alias('Columns')]
    [string[]]$Fields = @(),

    [Parameter(Mandatory=$false)]
    [switch]$AppendUnspecifiedFields
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

            # Build the ordered set of discovered fields that actually contain a value.
            # Used for the default (auto-discovery) and for -AppendUnspecifiedFields.
            $fieldsWithValues = [System.Collections.Generic.List[string]]::new()
            $seenWithValues   = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($row in $CSV) {
                foreach ($prop in $row.PSObject.Properties) {
                    $hasValue = $null -ne $prop.Value -and (
                        ($prop.Value -is [string] -and -not [string]::IsNullOrWhiteSpace($prop.Value)) -or
                        -not ($prop.Value -is [string])
                    )
                    if ($hasValue -and $seenWithValues.Add($prop.Name)) {
                        $fieldsWithValues.Add($prop.Name)
                    }
                }
            }

            # Decide the final column list and order
            if ($Fields.Count -gt 0) {
                # ----- User specified the exact columns and their order -----
                $orderedColumns = [System.Collections.Generic.List[string]]::new()
                $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

                foreach ($f in $Fields) {
                    if ([string]::IsNullOrWhiteSpace($f)) { continue }
                    $name = $f.Trim()
                    if ($seen.Add($name)) { $orderedColumns.Add($name) }
                }

                if ($AppendUnspecifiedFields) {
                    foreach ($name in $fieldsWithValues) {
                        if ($seen.Add($name)) { $orderedColumns.Add($name) }
                    }
                }
            }
            else {
                # ----- Auto-discover columns -----
                $orderedColumns = $fieldsWithValues
            }

            if ($orderedColumns.Count -eq 0) {
                Write-Warning "No columns to export (check your -Fields values)."
                return
            }

            # Build calculated properties so:
            #   - the header text/casing matches exactly what was requested
            #   - dotted names are treated as literal flat property names (not nested navigation)
            #   - a requested-but-missing field becomes an empty column
            $selectProps = foreach ($col in $orderedColumns) {
                $fieldName = $col
                @{
                    Name       = $fieldName
                    Expression = { $_.$fieldName }.GetNewClosure()
                }
            }

            $CSV |
                Select-Object -Property $selectProps |
                    Export-Csv -Path $OutputFile -NoTypeInformation -ErrorAction Stop

            Write-Verbose "Successfully exported $($CSV.Count) record(s) to '$OutputFile' with $($orderedColumns.Count) column(s)"
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