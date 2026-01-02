<#
.SYNOPSIS
    Replaces the first 3 characters of GUIDs in a text file with a specified prefix.

.DESCRIPTION
    This script reads a configuration file, identifies standard GUID/UUID patterns, 
    and replaces the first three characters of every GUID with the string provided 
    in the Prefix parameter (Default: "AAA").

.PARAMETER InputPath
    The path to the source file containing the GUIDs.

.PARAMETER OutputPath
    The path where the modified file will be saved. 
    If omitted, it creates a file named *_modified.conf in the same directory.

.PARAMETER Prefix
    The string to replace the start of the GUID with. Default is "AAA".

.EXAMPLE
    .\Update-SplunkGuids.ps1 -InputPath ".\windows_security_rules.conf"
    
    Processes the file and saves it as "windows_security_rules_modified.conf" with "AAA" prefixes.

.EXAMPLE
    .\Update-SplunkGuids.ps1 -InputPath ".\rules.conf" -OutputPath ".\rules_new.conf" -Prefix "ABC" -Verbose
    
    Processes rules.conf, changes GUID starts to "ABC", saves to rules_new.conf, and shows status messages.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to the source file.")]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$InputPath,

    [Parameter(Position=1, HelpMessage="Path for the output file.")]
    [string]$OutputPath,

    [Parameter(HelpMessage="The string to replace the first 3 characters with.")]
    [string]$Prefix = "AAA"
)

# Determine Output Path if not provided
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $FileInfo = Get-Item $InputPath
    $Directory = $FileInfo.DirectoryName
    $BaseName = $FileInfo.BaseName
    $Extension = $FileInfo.Extension
    $OutputPath = Join-Path -Path $Directory -ChildPath "${BaseName}_modified${Extension}"
}

Write-Verbose "Reading content from: $InputPath"
$Content = Get-Content -Path $InputPath -Raw -ErrorAction Stop

# Define Regex for Standard GUID (8-4-4-4-12 hex)
# This matches typical GUIDs like: 35ba1d85-724d-42a3-889f-2e2362bcaf23
$GuidRegex = [regex]'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'

# Perform Replacement
# We use a ScriptBlock to handle the specific string manipulation logic
$ModifiedContent = $GuidRegex.Replace($Content, {
    param($Match)
    $OriginalGuid = $Match.Value
    return $Prefix + $OriginalGuid.Substring(3)
})

Write-Verbose "Saving modified content to: $OutputPath"
Set-Content -Path $OutputPath -Value $ModifiedContent -Encoding UTF8 -Force
Write-Host "Success: Processed file. Output saved to '$OutputPath'" -ForegroundColor Green
