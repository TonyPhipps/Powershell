FUNCTION Get-SCCMEnvironment {
<#
.Synopsis 
    Queries SCCM for a given hostname, FQDN, or IP address.

.Description 
    Queries SCCM for a given hostname, FQDN, or IP address.

.Parameter Computer  
    Computer can be a single hostname, FQDN, or IP address.

.Example 
    Get-SCCMEnvironment 
    Get-SCCMEnvironment SomeHostName.domain.com
    Get-Content C:\hosts.csv | Get-SCCMEnvironment
    Get-SCCMEnvironment $env:computername
    Get-ADComputer -filter * | Select -ExpandProperty Name | Get-SCCMEnvironment

.Notes 
    Updated: 2017-07-20
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
        $Computer,
        [Parameter()]
        $SiteName="A1",
        [Parameter()]
        $SCCMServer="server.domain.com"
    );

	BEGIN{
        $SCCMNameSpace="root\sms\site_$SiteName";

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime"

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
	}

    PROCESS{        
                
        if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){ # is this an IP address?
            
            $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname;
            $ThisComputer = $fqdn.Split(".")[0];
        }
        
        else{ # Convert any FQDN into just hostname
            
            $ThisComputer = $Computer.Split(".")[0].Replace('"', '');
        };

            $output = [PSCustomObject]@{
                Name = $ThisComputer
                ResourceNames = ""
                Username = ""
                SystemVariable = ""
                VariableValue = ""
                Caption = ""
                Description = ""        
                Timestamp = ""
            }

            $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceNames, ResourceID from SMS_R_System where name='$ThisComputer'";
            $ResourceID = $SMS_R_System.ResourceID; # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
            $SMS_G_System_ENVIRONMENT = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select Name, VariableValue, SystemVariable, Username, Timestamp, Caption, Description from SMS_G_System_ENVIRONMENT where ResourceID='$ResourceID'";

            if ($SMS_G_System_ENVIRONMENT){
                
                $SMS_G_System_ENVIRONMENT | ForEach-Object {
                
                    $output.ResourceNames = $SMS_R_System.ResourceNames[0]

                    $output.VariableValue = $_.VariableValue;
                    $output.SystemVariable = $_.SystemVariable;
                    $output.Username = $_.Username;
                    $output.Timestamp = $_.Timestamp.Split(".")[0];
                    
                    if ($_.Caption.Split("\")[2]){ # These values have variable \'s present until the relevant content.
                        $output.Caption = $_.Caption.Split("\")[2];
                        $output.Description = $_.Description.Split("\")[2];
                    }
                    else{
                        $output.Caption = $_.Caption.Split("\")[1];
                        $output.Description = $_.Description.Split("\")[1];
                    };


                    return $output;
                    $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}; 
                };
            }
            else {

                return $output;
                $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}; 
            };

            $elapsed = $stopwatch.Elapsed;
            $total = $total+1;
            
            Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed";

    };

    END{
        $elapsed = $stopwatch.Elapsed;
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
	};
};

