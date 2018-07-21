function Get-DuplicateFiles {
    <#
    .SYNOPSIS
        Performs a search for duplicate files in a given directory.

    .DESCRIPTION
        Performs a search for duplicate files in a given directory.
        Items with the first CreationTime are considered originals, regardless of path.

    .PARAMETER Path
        Specify a path to search for duplicate files in, recursively.
        Default starting directory is $ENV:USERPROFILE.

    .EXAMPLE
        Get-DuplicateFiles -Verbose
        Provides start time, time taken, and total files scanned.

    .EXAMPLE
        Get-DuplicateFiles -Path "C:\Temp" -FullReport
        Returns all files checked, including originals. A Status property will contain Original or Duplicate.

    .EXAMPLE
        Get-DuplicateFiles "C:\Users\MyProfile" | Where-Object {$_.Status -eq "Duplicate"} | Remove-Item
        Removes duplicate items found.

    .NOTES
        Updated: 2018-07-20

        Contributing Authors:
            Anthony Phipps

        LEGAL: Copyright (C) 2018
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
       https://github.com/TonyPhipps/Powershell
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Path = $ENV:USERPROFILE,

        [Parameter()]
        [Switch]$FullReport
    )

    begin{
        $DateScanned = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $Stopwatch = New-Object System.Diagnostics.Stopwatch
        $Stopwatch.Start()

        $Total = 0
    }

    process{
        $FileArray = Get-ChildItem $Path -Recurse -File | Sort-Object CreationTime

        $counter = 0
        Foreach ($File in $FileArray){

            $counter++
            Write-Progress -Activity 'Calculating Hashes' -CurrentOperation $File.FullName -PercentComplete (($counter / $FileArray.count) * 100)
            $File | Add-Member -MemberType NoteProperty -Name "Hash" -Value (Get-FileHash $File.FullName).Hash
            $File | Add-Member -MemberType NoteProperty -Name "Status" -Value "Duplicate"
        }

        $GroupArray = $FileArray | Group-Object -Property Hash

        ForEach ($Group in $GroupArray){
            $Group.Group[0].Status = "Original"
        }

        $ReportArray = $GroupArray.Group

        if(!$FullReport){
            $ReportArray = $GroupArray.Group | Where-Object {$_.Status -eq "Duplicate"}
        }

        $Total = $Total + $FileArray.Count
        $ReportArray
    }

    end{
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Files Scanned: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}