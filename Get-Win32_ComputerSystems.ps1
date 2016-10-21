####################################################################################
#.Synopsis 
#    Perform Get-WmiObject -class Win32_ComputerSystem on several systems.
#
#.Description 
#    Perform Get-WmiObject -class Win32_ComputerSystem on several systems.
#	 Output errors to Get-Win32_ComputerSystems_errors.txt.
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | Get-Win32_ComputerSystems | export-csv Get-Win32_ComputerSystems.csv
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

Function Get-Win32_ComputerSystems() {
	[cmdletbinding()]


	PARAM(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = "localhost"
	);


	PROCESS{
		TRY{
			foreach ($thisHost in $INPUTLIST){
				Get-WmiObject -class Win32_ComputerSystem -ComputerName $thisHost -ErrorAction Stop | Select-Object *;
			};
		}
		CATCH{
			Add-Content -Path .\Get-Win32_ComputerSystems_errors.txt -Value ("$thisHost");
		}
	};
};
