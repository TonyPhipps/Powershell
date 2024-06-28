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
        Updated: 2024-06-18

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
        [Parameter(mandatory=$true)]
            [ValidateScript({
                try {
                    Get-Item $_ -ErrorAction Stop
                } catch [System.Management.Automation.ItemNotFoundException] {
                    Throw [System.Management.Automation.ItemNotFoundException] "${_} Maybe there are network issues?"
                }
            })]
            [String]$ReferenceObject,
        [Parameter(mandatory=$true)]
            [ValidateScript({
                try {
                    Get-Item $_ -ErrorAction Stop
                } catch [System.Management.Automation.ItemNotFoundException] {
                    Throw [System.Management.Automation.ItemNotFoundException] "${_} Maybe there are network issues?"
                }
            })]
            [String]$DifferenceObject,
        [Parameter()]
            [Array]$Compare,
        [Parameter()]
            [String]$OutputFolder = "$DifferenceObject\Difference"
    )

    begin{
        $ReferenceObjects = Import-Csv $ReferenceObject
        $DifferenceObjects = Import-Csv $DifferenceObject
        if ($ReferenceObjects -eq $DifferenceObjects){ # Objects are the same / both blank
            continue 
        } 
        if (!$ReferenceObject -OR !$ReferenceObjects){ # ReferenceObject is blank
            Write-Information -InformationAction Continue -MessageData ("Reference object blank or doesn't exist for: `n`t{0}`n`tCopying the DifferenceObject to represent differences." -f $DifferenceObject)
            $Output = "{0}\NO_REFERENCE_OBJECT_OR_CONTENT_FOR_{1}.csv" -f $OutputFolder, (Split-Path $DifferenceObject -Leaf).split('\.')[-2]
            Copy-Item $DifferenceObject $Output
            continue
        }    
        if (!$DifferenceObject -OR !$DifferenceObjects){ # DifferenceObject is blank
            Write-Information -InformationAction Continue -MessageData ("Difference object blank or doesn't exist for: `n`t{0}`n`tCopying the ReferenceObject to represent differences." -f $ReferenceObject)
            $Output = "{0}\{1}_HAS_NO_DIFFERENCE_OBJECT_OR_CONTENT.csv" -f $OutputFolder, (Split-Path $ReferenceObject -Leaf).split('\.')[-2]
            Copy-Item $ReferenceObject $Output
            continue
        }
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
