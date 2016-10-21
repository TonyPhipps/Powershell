####################################################################################
#.Synopsis 
#    Performs Get-WmiObject -class Win32_OperatingSystem | Select-Object *; on several systems.
#
#.Description 
#    Performs Get-WmiObject -class Win32_OperatingSystem on several systems.
#	 Output errors to Get-Win32_OperatingSystem_Multi_errors.txt.
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | Get-Win32_OperatingSystem_Multi | export-csv Get-Win32_OperatingSystem_Multi.csv
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

Function Get-Win32_OperatingSystem_Multi() {
	[cmdletbinding()]


	PARAM(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = "localhost"
	);


	PROCESS{
		TRY{
			foreach ($thisHost in $INPUTLIST){
				Get-WmiObject -class Win32_OperatingSystem -ComputerName $thisHost -ErrorAction Stop | Select-Object *;
			};
		}
		CATCH{
			Add-Content -Path .\Get-Win32_OperatingSystem_Multi_errors.txt -Value ("$thisHost");
		}
	};
};

