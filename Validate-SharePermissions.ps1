####################################################################################
#.Synopsis 
#	Performs read, write, and delete tests on multiple file shares.
#
#.Description 
#	Performs read, write, remove test on several systems and reports the results.
#
#.Parameter InputList  
#	Piped-in list of shares in the format
#	PSComputerName, Name, [Path], [Description]
#
#.Example 
#	import-csv .\shares.csv | Validate-SharePermissions
#	get-content .\shares.csv | convertfrom-csv | Validate-SharePermissions
#	get-content .\hosts.txt | Ping-Hosts | Foreach-Object {$_.Address} | '
#		MultiGet-Win32_Share | Validate-SharePermissions
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


Function Validate-SharePermissions() {
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
		$output = New-Object PSObject;
		
		$thisHost = $INPUT.PSComputerName;
		$INPUTName = $INPUT.Name;
		$INPUTPath = "\\$thisHost\$INPUTName";
		$testFolder = "testFolder8675309";
		$testFolderFull = "$INPUTPath\$testFolder";
						
		# Add original properties
		$output | Add-Member NoteProperty Hostname ($INPUT.PSComputerName);
		$output | Add-Member NoteProperty ShareName ($INPUT.Name);
		if ($INPUT.Path){
			$output | Add-Member NoteProperty SharePath ($INPUT.Path);
		}
		else{$output | Add-Member NoteProperty SharePath ("");}
		
		if ($INPUT.Path){
			$output | Add-Member NoteProperty ShareDescription ($INPUT.Description);
		}
		else{$output | Add-Member NoteProperty ShareDescription ("");}

		
		# Test Read				
		if (Test-Path $INPUTPath) {
			$output | Add-Member NoteProperty ReadFolder ("Granted")
			
			# Test Write
			New-Item -Path $INPUTPath -Name $testFolder -ItemType "directory" -Force | Out-Null
			
			if (Test-Path $testFolderFull) {
				$output | Add-Member NoteProperty WriteFolder ("Granted");
				
				# Test Delete
				Remove-Item -path $INPUTPath\$testFolder  | Out-Null
				
				if (Test-Path $testFolderFull) {
					$output | Add-Member NoteProperty RemoveFolder ("Denied");
				}
				
				else {
					$output | Add-Member NoteProperty RemoveFolder ("Granted");
				}
			}
			else{
				$output | Add-Member NoteProperty WriteFolder ("Denied");
				$output | Add-Member NoteProperty RemoveFolder ("Denied");
			}
			
		}
		else{
			$output | Add-Member NoteProperty ReadFolder ("Denied")
			$output | Add-Member NoteProperty WriteFolder ("Denied");
			$output | Add-Member NoteProperty RemoveFolder ("Denied");
		}
		
		
		Write-Output $output;
		$output.PsObject.Members.Remove('*');
	};
	
	END{
		#restore the error action
		$ErrorActionPreference = $RecordErrorAction
	}
};


