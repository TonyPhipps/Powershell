FUNCTION Parse-NetworkCKP {
<#
.Synopsis 
	Scans .CKP network object files and outputs properties.

.Description 
    Scans .CKP network object files and outputs properties.

.Parameter Path
    The path to a file. Can use DIR to feed filenames.

.Example 
    "C:\temp\network.ckp" | Parse-NetworkCKP
    dir *.ckp | Parse-NetworkCKP
    dir *.ckp | Parse-NetworkCKP | export-csv networks.csv    

.Notes 
    Updated: 2017-07-05
    LEGAL: Copyright (C) 2017  Anthony Phipps
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

    PARAM(
    	[Parameter(ValueFromPipeline=$True, Position = 0)]
		$Path
    );

	BEGIN{

	};

    PROCESS{
        Write-Host "Parsing $Path"

        $File = Get-Content $Path
        
        $pattern = ":name \((.*?)\).*:comments \((.*?)\).*:ipaddr \((.*?)\).*:netmask \((.*?)\)"

        $m = Select-String -InputObject $File -Pattern $pattern -AllMatches;

        try{
            $output = [PSCustomObject]@{
                Name = $m.Matches[0].Groups[1].Value;
                Comments = $m.Matches[0].Groups[2].Value;
                IP = $m.Matches[0].Groups[3].Value;
                Netmask = $m.Matches[0].Groups[4].Value;
            }
        }
        catch{}

        $output;
    };

    END{
        
    };
};
