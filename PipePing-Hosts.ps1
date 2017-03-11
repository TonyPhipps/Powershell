####################################################################################
#.Synopsis 
#    Pings multiple systems, outputting active hosts to stdout and offline hosts to stderr.
#
#.Description 
#    Pings multiple systems and provides status. Outputs unreachable hosts to .\PipePing-Hosts_errors.txt
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | PipePing-Hosts | export-csv pingable.csv
#
#.Example 
#    Get-Content .\hosts.txt | PipePing-Hosts | Select-Object IPV4Address | export-csv pingable.csv
#
#.Example 
#    Get-Content .\hosts.txt | PipePing-Hosts | Select-Object PSComputerName | export-csv pingable.csv
#
#.Notes 
# Updated: 2017-03-01
# LEGAL: Copyright (C) 2017  Anthony Phipps
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

Function PipePing-Hosts() {
	[cmdletbinding()]


	PARAM(
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True)]
		$INPUT
	);

	
	BEGIN{
		#change the error action temporarily
		$RecordErrorAction = $ErrorActionPreference
		$ErrorActionPreference = "SilentlyContinue"
	}

	PROCESS{

		TRY{
			Test-Connection -Computername $INPUT -Count 1 -ErrorAction Stop;
		}
		CATCH{
			Add-Content -Path .\PipePing-Hosts_errors.txt -Value ("$INPUT");
		};
	};
	
	
	END{
		#restore the error action
		$ErrorActionPreference = $RecordErrorAction
	}
};

