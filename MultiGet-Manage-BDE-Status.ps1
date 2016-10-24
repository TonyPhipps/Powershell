####################################################################################
#.Synopsis 
#    Performs manage-bde -status on several systems.
#
#.Description 
#    Performs manage-bde -status on several systems.
#	 Output errors to MultiGet-Win32_Share_errors.txt.
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | MultiGet-Manage-BDE-Status | export-csv MultiGet-Manage-BDE-Status.csv
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

Function MultiGet-Manage-BDE-Status() {
	[cmdletbinding()]


	PARAM(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = "localhost"
	);


	PROCESS{
		TRY{
			foreach ($thisHost in $INPUTLIST){
			
				$BitLocker = @() 
				 
				Invoke-Expression "manage-bde -ComputerName $thisHost -Status" | 
				Select-String -Pattern "Name:" -Context 0,17 | 
					WHERE { 
						$Record = New-Object PSObject -Property @{
						Computer=($_.Line -Split "Name:\s")[1];
						Volume=($_.Context.PostContext[3] -Split "Volume\s")[1];
						Size=($_.Context.PostContext[6] -Split ":\s+")[1];
						Version=($_.Context.PostContext[7] -Split ":\s+")[1];
						Percentage=($_.Context.PostContext[9] -Split ":\s+")[1];
						Method=($_.Context.PostContext[10] -Split ":\s+")[1];
						Status=($_.Context.PostContext[11] -Split ":\s+")[1];
						IDField=($_.Context.PostContext[13] -Split ":\s+")[1];
						};
						$BitLocker +=$Record;
					};
				return $BitLocker;
			};
		}
		CATCH{
			Add-Content -Path .\MultiGet-Manage-BDE-Status_errors.txt -Value ("$thisHost");
		}
	};
};

