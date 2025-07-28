<#
.SYNOPSIS
    Converts YAML files to CSV format from a specified directory.

.DESCRIPTION
    This script processes YAML files in the specified input directory, converts them to a flat structure,
    and exports the results to a CSV file. It requires the powershell-yaml module.

.PARAMETER InputDir
    The directory containing YAML files to process. Defaults to 'rules' folder in the parent directory.

.PARAMETER OutputFile
    The path for the output CSV file. Defaults to 'flattenedyaml.csv' in the script's directory.

.EXAMPLE
    .\Convert-YamlToCsv.ps1 -InputDir "C:\Rules" -OutputFile "C:\Output\flattenedyaml.csv"
    Processes YAML files from C:\Rules and outputs to C:\Output\flattenedyaml.csv

.EXAMPLE
    .\Convert-YamlToCsv.ps1
    Uses default paths to process YAML files and create flattenedyaml.csv
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$InputDir,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = (Join-Path -Path $PSScriptRoot -ChildPath 'flattenedyaml.csv')
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
        $InputDir = Join-Path -Path $ScriptParent -ChildPath 'rules'
    }

    function Get-FlatYAML {
    param (
        [Parameter(Mandatory)]
        $InputObject,

        [String]$InputFileName
    )

    $Output = New-Object -TypeName PSObject

    if ($inputObject -is [Hashtable]){
        foreach ($Key in $InputObject.Keys) { # review each member
            $Member = $InputObject.$Key
            if ($Member -is [Hashtable]){
                #-----------------Level 2-----------------
                foreach ($Key2 in $Member.Keys) { # review each member
                    $Member2 = $Member.$Key2
                    if ($Member2 -is [Hashtable]){
                        #-----------------Level 3-----------------
                        foreach ($Key3 in $Member2.Keys) { # review each member
                            $Member3 = $Member2.$Key3
                            if ($Member3 -is [Hashtable]){
                                Write-Host "is hashtable: $Key.$Key2.$Key3. Add another level."
                            }
                            elseif ($Member3 -is [System.Collections.ICollection]) {
                                $ICollection3 = $Member2.$Key3 -join ", "
                                $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2 + "." + $Key3) -Value $ICollection3 -ErrorAction SilentlyContinue | Out-Null
                            }
                            elseif ($NULL -eq $Member3) {
                            }
                            elseif ($Member3.GetType().Name -in ("String","Int32","long","bool")) {
                                $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2 + "." + $Key3) -Value $Member3 -ErrorAction SilentlyContinue | Out-Null
                            }
                            else {
                                Write-Host "Level 3 - $Key.$Key2.$Key3 is a $($Member3.GetType())" 
                            }            
                        }
                        #-----------------Level 3 END-----------------
                    }
                    elseif ($Member.$Key2 -is [System.Collections.ICollection]) {
                        $ICollection2 = $Member2.$Key2 -join ", "
                        $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2) -Value $ICollection2 -ErrorAction SilentlyContinue | Out-Null
                    }
                    elseif ($Member2.GetType().Name -in ("String","Int32","long","bool")) {
                        $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2) -Value $Member2 -ErrorAction SilentlyContinue | Out-Null
                    }
                    else {
                        Write-Host "Level 2 - $Key.$Key2 is a $($Member2.GetType())" 
                    }               
                #-----------------Level 2 END-----------------
                }
            }
            elseif ($InputObject.$Key -is [System.Collections.ICollection]) {
                $ICollection = $InputObject.$key -join ", "
                $Output | Add-Member -MemberType NoteProperty -Name $Key -Value $ICollection -ErrorAction SilentlyContinue | Out-Null
            }
            elseif ($Member.GetType().Name -in ("String","Int32","long","bool")) {
                $Output | Add-Member -MemberType NoteProperty -Name $Key -Value $Member -ErrorAction SilentlyContinue | Out-Null
            }            
            else {
                $Member3.GetType()
                Write-Host "Level 1 - $Key is a $($Member.GetType())" 
            }               
        }
    }

    if ($InputFileName){
        $Original = Get-Content ($InputFileName) -raw
        $Output | Add-Member -MemberType NoteProperty -Name "Original" -Value $Original -ErrorAction SilentlyContinue | Out-Null
        $Output | Add-Member -MemberType NoteProperty -Name "Filepath" -Value $InputFileName -ErrorAction SilentlyContinue | Out-Null
    }

    return $Output
}

    # Initialize variables
    $CSV = @()
    
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

        # Get YAML files
        $Files = Get-ChildItem -Path $InputDir -Recurse -Include '*.yml' -ErrorAction Stop

        if ($Files.Count -eq 0) {
            Write-Warning "No YAML files found in '$InputDir'"
            return
        }

        # Process each YAML file
        foreach ($File in $Files) {
            if ($File.GetType().Name -eq "FileInfo") {
                try {
                    $FullName = $File.FullName
                    $YAML = ConvertFrom-Yaml (Get-Content $FullName -Raw -ErrorAction Stop)
                    $CSV += Get-FlatYAML $YAML $FullName
                }
                catch {
                    Write-Warning "Failed to process file '$FullName': $_"
                    continue
                }
            }
        }

        # Export to CSV
        if ($CSV.Count -gt 0) {
            $CSV | 
                Select-Object title, name, id, status, description, references, author, date, 
                            modified, tags, logsource.category, logsource.definition, 
                            logsource.product, logsource.service, falsepositives, level, 
                            license, FilePath, original |
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

end {
    Write-Verbose "Script execution completed"
}