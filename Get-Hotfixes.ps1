FUNCTION Get-Hotfixes {
<#
.Synopsis 
    Gets the hotfixes applied to a given system.

.Description 
    Gets the hotfixes applied to a given system. Get-Hotfix returns only OS-level hotfixes, this one grabs em all.

.Parameter Computer  
    Computer can be a single hostname, FQDN, or IP address.

.Example 
    Get-Hotfixes 
    Get-Hotfixes SomeHostName.domain.com
    Get-Content C:\hosts.csv | Get-Hotfixes
    Get-Hotfixes $env:computername
    Get-ADComputer -filter * | Select -ExpandProperty Name | Get-Hotfixes

.Notes 
    Updated: 2017-07-26
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
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer
    );

	BEGIN{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime"

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
	}

    PROCESS{

        $output = [PSCustomObject]@{
            Name = $Computer
            PSComputerName = ""
            Operation = ""
            ResultCode = ""
            HResult = ""
            Date = ""
            Title = ""
            Description = ""
            UnmappedResultCode = ""
            ClientApplicationID = ""
            ServerSelection = ""
            ServiceID = ""
            UninstallationNotes = ""
            SupportUrl = ""
        };

        $Hotfixes = invoke-command -Computer $Computer -scriptblock {

            $Session = New-Object -ComObject "Microsoft.Update.Session";
            $Searcher = $Session.CreateUpdateSearcher();
            $historyCount = $Searcher.GetTotalHistoryCount();
            $Searcher.QueryHistory(0, $historyCount) | Select-Object PSComputerName, Operation, ResultCode, HResult, Date, Title, Description, UnmappedResultCode, ClientApplicationID, ServerSelection, ServiceID, UninstallationNotes, SupportUrl | Where-Object Title -ne $null;
        };

        if ($Hotfixes){
            
            $Hotfixes | ForEach-Object {

                $output.PSComputerName = $_.PSComputerName;
                $output.Operation = $_.Operation;
                $output.ResultCode = $_.ResultCode;
                $output.HResult = $_.HResult;
                $output.Date = $_.Date;
                $output.Title = $_.Title;
                $output.Description = $_.Description;
                $output.UnmappedResultCode = $_.UnmappedResultCode;
                $output.ClientApplicationID = $_.ClientApplicationID;
                $output.ServerSelection = $_.ServerSelection;
                $output.ServiceID = $_.ServiceID;
                $output.UninstallationNotes = $_.UninstallationNotes;
                $output.SupportUrl = $_.SupportUrl;

                return $output;
                $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}; 
            };
        }
        else {

            return $output;
            $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}; 
        };

        $elapsed = $stopwatch.Elapsed;
        $total = $total++;
            
        Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed";

    };

    END{
        $elapsed = $stopwatch.Elapsed;
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
	};
};




