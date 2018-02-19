function Invoke-THRecon {
    <#
    .SYNOPSIS 
        Performs a search for alternate data streams (ADS) on a system.

    .DESCRIPTION 
        Performs a search for alternate data streams (ADS) on a system. Default starting directory is c:\temp.
        To test, perform the following steps first:
        $file = "C:\temp\testfile.txt";
        Set-Content -Path $file -Value 'Nobody here but us chickens!';
        Add-Content -Path $file -Value 'Super secret squirrel stuff' -Stream 'secretStream';

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Path  
        Specify a path to search for alternate data streams in. Default is c:\temp

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THR_ADS -Path "C:\"
        Get-THR_ADS SomeHostName.domain.com -Path "C:\"
        Get-Content C:\hosts.csv | Get-THR_ADS -Path "C:\"
        Get-THR_ADS $env:computername -Path "C:\"
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_ADS -Path "C:\"

    .NOTES 
        Updated: 2018-02-07

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
       https://github.com/TonyPhipps/THRecon
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        $Options = ""
    );

    begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime";

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
    };

    process{

        $Computer = $Computer.Replace('"', '');

        Write-Verbose "Attemting to run Invoke-Command on remote system.";
        
        if ($Options -like "*R*"){
            $Class = [ThreconRegistry]::new()
            $Class.Hunt()
                        
            $Results = $Class.Results

            ForEach ($Result in $Results) {

                $Result | Add-Member -MemberType NoteProperty -Name "Target" -Value $Class.Target
                $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $Class.DateScanned
            }

            return $Results
        }

        

        # if result array remains empty, build a single fail result
        

    };

    end{

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};