####################################################################################
#.Synopsis 
#   Retreives PATH environment variables from multiple systems.
#
#.Description
#	Retreives PATH environment variables from multiple systems.
#	Performs Get-WMIObject -Class Win32_Environment | Where-Object {$_.Name -eq "Path"} | Select-Object *; | Select-Object *; on several systems.
#	The end result will be a list of all PATH environment variables, each with the associated computer name.
#	Output errors to MultiGet-Win32_Environment_errors.txt.
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | MultiGet-Win32_Environment | export-csv MultiGet-Win32_Environment.csv
#
#.Notes 
# Updated: 2016-10-26
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

Function MultiGet-Win32_Environment() {
	[cmdletbinding()]


	PARAM(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = "localhost"
	);


	PROCESS{
		TRY{
			foreach ($thisHost in $INPUTLIST){
				$paths = (Get-WMIObject -Class Win32_Environment -ComputerName $thisHost -ErrorAction Stop | Where {$_.Name -eq "Path"} | select -ExpandProperty VariableValue).Split(';') | Where-Object {$_ -ne ""};

				ForEach ($path in $paths){
					$path = $path.Replace('"',"");

					if (-not $path.EndsWith("\")){
						$path = $path + "\";
					};

					$output = New-Object PSObject;
					$output | Add-Member NoteProperty Host ($thisHost);
					$output | Add-Member NoteProperty VariableValue ($path);

					Write-Output $output;
					$output.PsObject.Members.Remove('*');
				};
			};
		}
		CATCH{
			Add-Content -Path .\MultiGet-Win32_Environment_errors.txt -Value ("$thisHost");
		};
	};
};

