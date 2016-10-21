####################################################################################
#.Synopsis 
#    Performs "Get-ADComputer -Property *" on several systems.
#
#.Description 
#    Performs "Get-ADComputer -Property *" on several systems.
#	 Output errors to Get-ADComputer_Multi_errors.txt.
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | Get-ADComputer_Multi | export-csv Get-ADComputer_Multi.csv
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

Function Get-ADComputer_Multi() {
	[cmdletbinding()]


	PARAM(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = (hostname)
	);


	PROCESS{
		TRY{
			foreach ($thisHost in $INPUTLIST){	
				if ([bool]($thisHost -as [ipaddress])){
					Get-ADComputer -filter { ipv4address -eq $thisHost} -Property * -ErrorAction Stop;
				}
				else{
					Get-ADComputer -filter { name -eq $thisHost} -Property * -ErrorAction Stop;
				};
			};
		}
		CATCH{
			Add-Content -Path .\Get-ADComputer_Multi_errors.txt -Value ("$thisHost");
		}
	};
};

