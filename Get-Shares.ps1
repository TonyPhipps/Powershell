####################################################################################
#.Synopsis 
#    Performs Get-WmiObject -class Win32_Share | Select-Object; on several systems.
#
#.Description 
#    Performs Get-WmiObject -class Win32_Share on several systems.
#	 Output errors to Get-Win32_Share_Multi_errors.txt.
#
#.Parameter InputList  
#    Piped-in list of hosts or IP addresses
#
#.Example 
#    get-content .\hosts.txt | PipeGet-Win32_Share | export-csv Get-Win32_Share_Multi.csv
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

Function Get-Shares() {
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
			Get-WmiObject -class Win32_Share -ComputerName $INPUT -ErrorAction Stop | Select-Object PSComputerName, Name, Path, Description;
		}
		CATCH{
			Add-Content -Path .\Get-Shares_errors.txt -Value ("$INPUT");
		}
	};
	
	
	END{
		#restore the error action
		$ErrorActionPreference = $RecordErrorAction
	}
};

