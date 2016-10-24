####################################################################################
#.Synopsis 
# Perform Get-WmiObject -Class Win32_BIOS | Select-Object *; on several systems.
#
#.Description 
#   Perform Get-WmiObject -Class Win32_BIOS | Select-Object *; on several systems.
#	Outputs errors to Get-Win32_BIOS_Multi_errors.txt.
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | MultiGet-Win32_BIOS | export-csv .\Get-Win32_BIOS_Multi.csv
#
#.Notes 
# Updated: 2016-10-24
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

Function MultiGet-Win32_BIOS() {
	[cmdletbinding()]


	PARAM(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = "localhost"
	);


	PROCESS{
		TRY{
			foreach ($thisHost in $INPUTLIST){
				Get-WmiObject -Class Win32_BIOS -ComputerName $thisHost -ErrorAction Stop | Select-Object *;
			};
		}
		CATCH{
			Add-Content -Path .\MultiGet-Win32_BIOS_errors.txt -Value ("$thisHost");
		}
	};
};

