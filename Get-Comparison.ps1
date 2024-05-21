function Get-Comparison {
    <#
    .SYNOPSIS
        Compares two CSV files for differences and exports the result in a new CSV file.

    .DESCRIPTION
        Compares two CSV files for differences and exports the result in a new CSV file. 
        The output file will be saved in the folder specified in the -OutputFolder parameter, and will contain the two compared filenames.

    .PARAMETER ReferenceObject
        The first CSV file to compare.

    .PARAMETER DifferenceObject
        The second CSV file to compare.

    .PARAMETER Compare
        The properties to compare. Use the format "One", "Two", "Three", etc.

    .PARAMETER OutputFolder
        The folder where the output file will be saved. Do NOT include the trailing backslash (\)

    .EXAMPLE
        Get-Comparison -ReferenceObject "C:\baseline.csv" -DifferenceObject "C:\new_check.csv" -Compare "One", "Two", "Three" -OutputFolder "C:\output"

    .NOTES
        Updated: 2024-05-21

        Contributing Authors:
            Anthony Phipps

        LEGAL: Copyright (C) 2024
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
        [Parameter()]
        $ReferenceObject = "C:\baseline.csv",
        [Parameter()]
        $DifferenceObject = "C:\new.csv",
        [Parameter()]
        [Array]$Compare = @("ProcessName"),
        [Parameter()]
        $OutputFolder = "c:\output"
    )

    begin{
    }

    process{

        New-Item -Path (Split-Path $OutputFolder -Parent) -Name (Split-Path $OutputFolder -Leaf) -ItemType "Directory" -ErrorAction SilentlyContinue
        $Output = "{0}\{1}_vs_{2}_difference.csv" -f $OutputFolder, (Split-Path $ReferenceObject -Leaf), (Split-Path $DifferenceObject -Leaf)
        $ReferenceObjects = Import-Csv $ReferenceObject
        $DifferenceObjects = Import-Csv $DifferenceObject

        $UniqueObjects = Compare-Object -ReferenceObject $ReferenceObjects -DifferenceObject $DifferenceObjects -Property $Compare -PassThru | 
            Where-Object { $_.SideIndicator -eq '<=' -or $_.SideIndicator -eq '=>' }

        foreach ($UniqueObject in $UniqueObjects) {
                
            if ($UniqueObject.SideIndicator -eq "<="){
                $UniqueObject | Add-Member -MemberType NoteProperty -Name "File" -Value $ReferenceObject
            }
            
            if ($UniqueObject.SideIndicator -eq "=>"){
                $UniqueObject | Add-Member -MemberType NoteProperty -Name "File" -Value $DifferenceObject
            }

            $UniqueObject | Add-Member -MemberType NoteProperty -Name "ComparedProperties" -Value ($Compare -join ", ")
        }  

        Write-Information -InformationAction Continue -MessageData ("Found {0} unique objects." -f $UniqueObjects.count)
        
        if ($UniqueObjects.count -gt 0) {
            Write-Information -InformationAction Continue -MessageData ("Saving output to {0}" -f $Output)    
            $UniqueObjects | Export-Csv $Output -NoTypeInformation
        }
    }

    end{
    }
}