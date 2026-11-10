<#
.SYNOPSIS
    Packages an extracted Splunk app directory into a .tgz archive.

.DESCRIPTION
    Takes the path to an extracted Splunk app folder, creates a GZipped Tarball (.tgz)
    containing the root app folder structure, and places the archive in the parent directory.
    Uses native .NET assemblies without requiring external tools like tar.exe or 7-Zip.

.PARAMETER AppFolderPath
    The full or relative path to the extracted Splunk app directory.

.EXAMPLE
    New-SplunkAppPackage -AppFolderPath "C:\Builds\MyApp"
    Creates "C:\Builds\MyApp.tgz".
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$AppFolderPath
)

process {
    $resolvedAppItem = Get-Item -Path $AppFolderPath
    $appName = $resolvedAppItem.Name
    $parentDir = $resolvedAppItem.Parent.FullName
    $outputTgzPath = Join-Path -Path $parentDir -ChildPath "$appName.tgz"
    Write-Verbose "Packaging Splunk app '$appName' from: $AppFolderPath"
    Write-Verbose "Output archive target: $outputTgzPath"
    function Write-TarHeader {
        param (
            [System.IO.Stream]$Stream,
            [string]$FileName,
            [long]$Length,
            [bool]$IsDirectory
        )
        $header = New-Object byte[] 512
        $nameBytes = [System.Text.Encoding]::ASCII.GetBytes($FileName)
        [Array]::Copy($nameBytes, 0, $header, 0, [Math]::Min($nameBytes.Length, 100))
        $modeStr = if ($IsDirectory) { "0000755`0" } else { "0000644`0" }
        $modeBytes = [System.Text.Encoding]::ASCII.GetBytes($modeStr)
        [Array]::Copy($modeBytes, 0, $header, 100, 8)
        $idBytes = [System.Text.Encoding]::ASCII.GetBytes("0000000`0")
        [Array]::Copy($idBytes, 0, $header, 108, 8)
        [Array]::Copy($idBytes, 0, $header, 116, 8)
        $sizeStr = if ($IsDirectory) { "00000000000`0" } else { ([Convert]::ToString($Length, 8)).PadLeft(11, '0') + "`0" }
        $sizeBytes = [System.Text.Encoding]::ASCII.GetBytes($sizeStr)
        [Array]::Copy($sizeBytes, 0, $header, 124, 12)
        $mtimeStr = ([Convert]::ToString([long](Get-Date -Date "1970-01-01 00:00:00Z").TimeOfDay.TotalSeconds, 8)).PadLeft(11, '0') + "`0"
        $mtimeBytes = [System.Text.Encoding]::ASCII.GetBytes($mtimeStr)
        [Array]::Copy($mtimeBytes, 0, $header, 136, 12)
        $spaceBytes = [System.Text.Encoding]::ASCII.GetBytes("        ")
        [Array]::Copy($spaceBytes, 0, $header, 148, 8)
        $header[156] = if ($IsDirectory) { 53 } else { 48 }
        [long]$chksum = 0
        foreach ($b in $header) { $chksum += $b }
        $chkStr = ([Convert]::ToString($chksum, 8)).PadLeft(6, '0') + "`0 "
        $chkBytes = [System.Text.Encoding]::ASCII.GetBytes($chkStr)
        [Array]::Copy($chkBytes, 0, $header, 148, 8)
        $Stream.Write($header, 0, 512)
    }
    try {
        $outFileStream = [System.IO.File]::Create($outputTgzPath)
        $gzipStream = New-Object System.IO.Compression.GZipStream($outFileStream, [System.IO.Compression.CompressionMode]::Compress)
        $allItems = Get-ChildItem -Path $resolvedAppItem.FullName -Recurse -Force
        Write-TarHeader -Stream $gzipStream -FileName "$appName/" -Length 0 -IsDirectory $true
        foreach ($item in $allItems) {
            $relativePath = $item.FullName.Substring($resolvedAppItem.Parent.FullName.Length + 1).Replace('\', '/')
            if ($item.PSIsContainer) {
                $relativePath = "$relativePath/"
                Write-TarHeader -Stream $gzipStream -FileName $relativePath -Length 0 -IsDirectory $true
            }
            else {
                $fileLength = $item.Length
                Write-TarHeader -Stream $gzipStream -FileName $relativePath -Length $fileLength -IsDirectory $false
                $fileStream = [System.IO.File]::OpenRead($item.FullName)
                $fileStream.CopyTo($gzipStream)
                $fileStream.Dispose()
                $padding = 512 - ($fileLength % 512)
                if ($padding -ne 512) {
                    $padBuffer = New-Object byte[] $padding
                    $gzipStream.Write($padBuffer, 0, $padding)
                }
            }
        }
        $nullBlock = New-Object byte[] 1024
        $gzipStream.Write($nullBlock, 0, 1024)
        $gzipStream.Dispose()
        $outFileStream.Dispose()
        Write-Host "Successfully packaged Splunk app to: $outputTgzPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to package Splunk app '$appName'. Error: $_"
    }
}