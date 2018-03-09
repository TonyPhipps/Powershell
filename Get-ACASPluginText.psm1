function Get-ACASPluginText {
    <#
    .SYNOPSIS 
        Takes ACAS results exported to CSV and parses out information in Plugin Text field.

    .DESCRIPTION 
        Takes ACAS results exported to CSV and parses out information in Plugin Text field.
        Currently only tested with ACAS Plugin ID 10863

    .PARAMETER ACASResult
        One single ACAS Result line from the CSV export.

    .PARAMETER Retain
        Use this switch to retain the original Plugin Text field.

    .EXAMPLE 
        Import-CSV C:\Results.csv | Get-ACASPluginText

    .NOTES 
        Updated: 2018-03-05

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
       
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $ACASResult,

        [Parameter()]
        [Switch]$Retain
    )

	begin{

        $DateScanned = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

	}

    process{
                        
        $ACASResult.'Plugin Text' = $ACASResult.'Plugin Text' -replace "Plugin Output: ", "" # Remove header
        $ACASResult.'Plugin Text' = $ACASResult.'Plugin Text' -replace "\n+", "`n" # Remove double newlines
        $ACASResult.'Plugin Text' = $ACASResult.'Plugin Text' -replace "(?m)\n^\s+", "" # Remove newlines that have multiple spaces
        $ACASResult.'Plugin Text' = $ACASResult.'Plugin Text' -replace " :", ":" # Fix some delimeters
        
        $Lines = $null
        $Lines += $ACASResult.'Plugin Text'.Split("`n").Trim()

        $iLines = 0
        foreach ($Line in $Lines){
            
            if ($Line -ne "") {

                $iLines++
                $Name, $Value = $Line.Split(':',2) # Split by first delimeter only. Fixes parsing dates as objects
            
                if ($ACASResult.($Name)){ # Checks if a column already exists, and creates a solution
                
                    $Name = $Name+$iLines

                }

                if (!$Retain){
                    $ACASResult = $ACASResult | Select-Object * -ExcludeProperty "Plugin Text"
                }

                $ACASResult | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
            }
        }

        $total++
        $ACASResult
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Results: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}