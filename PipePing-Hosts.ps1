####################################################################################
#.Synopsis 
#    Pings mulitple systems and provides status. 
#
#.Description 
#    Pings mulitple systems and provides status. Outputs unreachable hosts to .\Ping-Hosts_errors.txt
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | Ping-Hosts | export-csv pingable.csv
#
#.Example 
#    Get-Content .\hosts.txt | Ping-Hosts | Select-Object IPV4Address | export-csv pingable.csv
#
#.Example 
#    Get-Content .\hosts.txt | Ping-Hosts | Select-Object PSComputerName | export-csv pingable.csv
#
#.Notes 
# Updated: 2016-10-19
# LEGAL: Copyright (C) 2016  Anthony Phipps
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
####################################################################################

Function Ping-Hosts() {
	[cmdletbinding()]


	param(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = "localhost"
	);


	PROCESS{

		TRY{
			foreach ($thisHost in $INPUTLIST){
				Test-Connection -Computername $thisHost -Count 1 -ErrorAction Stop;
			};
		}
		CATCH{
			Add-Content -Path .\Ping-Hosts_errors.txt -Value ("$thisHost");
		};
	};
};

