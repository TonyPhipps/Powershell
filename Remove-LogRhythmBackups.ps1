function Remove-LogRhythmBackups {
    <#
    .SYNOPSIS 
        Removes older LogRhythm backups based on date.

    .DESCRIPTION 
        

    .PARAMETER Path
        Root folder of backups. Subfolders should have names like 20200607_1_637265520994768542

    .EXAMPLE 
        Remove-LogRhythmBackups -Path "C:\temp\backups" -OlderThanDays 180

    .NOTES
        Updated: 2020-06-07

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2020
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
       https://github.com/TonyPhipps/
    #>

    [CmdletBinding()]
    param(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Path = "C:\temp\backups",

            [Parameter()]
            [alias("Days","Age")]
            [int]
            $OlderThanDays = 180
        )

	begin{

        Write-Verbose ("Using parameters: Path: {0} OlderThanDays: {1}" -f $Path, $OlderThanDays)

        $DateScanned = Get-Date -Format u
        Write-Verbose ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        
    }

    process{

        $LogRhythmBackups = Get-ChildItem $Path -Directory

        $Today = Get-Date
        $Window = $Today.AddDays(0 - $OlderThanDays)
        $Window

        Foreach ($LogRhythmBackup in $LogRhythmBackups) {
            

            $folderName = $LogRhythmBackup.Name
            $backupDateString = $folderName.Split('_')[0]
            $backupDate = [datetime]::parseexact($backupDateString, 'yyyyMMdd', $null)
            #$backupDate

            if ($backupDate -lt $Window) {
                Write-Verbose("Deleting " + $folderName)
                Remove-Item -LiteralPath $LogRhythmBackup.PSPath -Force -Recurse
            }

        }
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}