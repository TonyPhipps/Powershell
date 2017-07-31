Function Get-OnlineComputers() {

    <#
    .Synopsis 
        Pings mulitple systems, outputting active hosts to stdout and offline hosts to stderr.

    .Description 
        Pings mulitple systems and provides status. Outputs unreachable hosts to .\Ping-Hosts_errors.txt

    .Parameter InputList  
        Piped-in list of hosts/IP addresses

    .Example 
        get-content .\hosts.txt | Ping-Hosts | export-csv pingable.csv

    .Example 
        Get-Content .\hosts.txt | Ping-Hosts | Select-Object IPV4Address | export-csv pingable.csv

    .Example 
        Get-Content .\hosts.txt | Ping-Hosts | Select-Object Address | export-csv pingable.csv

    .Notes 
     Updated: 2017-07-31
     LEGAL: Copyright (C) 2017  Anthony Phipps
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

    #>

	[cmdletbinding()]


	PARAM(
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True)]
		$Computer,
        [Parameter()]
        $Fails
	);

	
	BEGIN{
        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime"

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
	};

	PROCESS{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $PingResults = $null;

        $PingResults = Test-Connection -Computername $Computer -Count 1 -BufferSize 16 -TimeToLive 10 -Quiet;


		if ($PingResults){
            return $Computer;
        }
		else{
            if ($Fails) { # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer");
            };
		};

        $elapsed = $stopwatch.Elapsed;
        $total = $total+1;
            
        Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed";
	};
	
	
	END{
		
        $elapsed = $stopwatch.Elapsed;
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
	};
};

