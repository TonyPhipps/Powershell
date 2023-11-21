function Get-Files {
    <#
    .SYNOPSIS 
        Retreives files and provides a csv of the files with original metadata.

    .DESCRIPTION 
        Retreives files and provides a csv of the files with original metadata.

    .PARAMETER SourceList
        Files and folder paths to retrieve, including support for wildcards.

    .PARAMETER Destination
        Place to store all files.

    .EXAMPLE
        Get-Files

    .EXAMPLE
        Get-Files | 
        Export-Csv -NoTypeInformation ("c:\temp\Files.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Files} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Files.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Files} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Files.csv")
        }

    .NOTES 
        Updated: 2023-11-21

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2023
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.

    .LINK
       https://github.com/TonyPhipps
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [String[]]$SourceList = @(
            "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\places.sqlite",
            "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\formhistory.sqlite"
        ),
        $Destination = "C:\Get-Files"
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-Files at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        # Prepare destination Folder
        New-Item -ItemType Directory $Destination -ErrorAction SilentlyContinue

        $ResolvedPaths = ForEach ($Path in [String[]]$SourceList) {
            if ($Path -match '\*') {
                $Paths = (Resolve-Path -Path $Path).Path
                if ($Paths.Count -gt 0){
                    (Resolve-Path -Path $Path).Path
                }
            }
            else{
                $Path
            }
        }

        $ResolvedFiles = ForEach ($Path in $ResolvedPaths) {

            if ((Test-Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -File -Recurse).Count -gt 0){
                (Get-ChildItem -Path $Path -File -Recurse).FullName
            }
            else {
                $Path
            }
        }

        $ResultsArray = ForEach ($File in $ResolvedFiles) {

            $PathSplit = Split-Path (Split-Path $File -NoQualifier) -Parent

            New-Item -ItemType Directory ($Destination + $PathSplit) -ErrorAction SilentlyContinue | Out-Null
            Copy-Item -Path $File -Destination ($Destination + $PathSplit) -Force

            # Remove Empty Directories Recursively
            Get-ChildItem $Destination -Directory -Recurse |
                Foreach-Object { $_.FullName} |
                Sort-Object -Descending |
                Where-Object { !@(Get-ChildItem -force $_) } |
                Remove-Item

            try{
                $FileHash = (Get-FileHash -Path $File -ErrorAction Stop).Hash
            }
            catch{
                $FileHash = " "
            }          

            $fileObject = Get-Item -Path $File 
            $fileObject | Add-Member -MemberType NoteProperty -Name "Hash" -Value $FileHash -Force
            $fileObject
        }

        foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned 
        }

        $ResultsArray | Select-Object Host, DateScanned, FullName, Mode, Length, Hash, LastWriteTimeUTC, LastAccessTimeUTC, creationTimeUtc | Export-Csv -NoTypeInformation ("$Destination\Files.csv") -Append
        
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
