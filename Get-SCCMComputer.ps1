FUNCTION Get-SCCMComputer {
<#
.Synopsis 
    Queries SCCM for a given hostname, FQDN, or IP address.

.Description 
    Queries SCCM for a given hostname, FQDN, or IP address.

.Parameter Computer  
    Computer can be a single hostname, FQDN, or IP address.

.Example 
    Get-SCCMComputer 
    Get-SCCMComputer SomeHostName.domain.com
    Get-Content C:\hosts.csv | Get-SCCMComputer
    Get-SCCMComputer $env:computername
    Get-ADComputer -filter * | Select -ExpandProperty Name | Get-SCCMComputer

.Notes 
    Updated: 2017-07-19
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
            $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname
            $ThisComputer = $fqdn.Split(".")[0]
        }
        
        else{ # Convert any FQDN into just hostname
            $ThisComputer = $Computer.Split(".")[0].Replace('"', '')
        }

        $output = [PSCustomObject]@{
                Name = $ThisComputer
                Domain = ""
                DistinguishedName = ""
                ResourceNames = ""
                IsVirtualMachine = ""
                LastLogonTimestamp = ""
                LastLogonUserDomain = ""
                LastLogonUserName = ""
                IPAddresses = ""
                IPSubnets = ""
                MACAddresses = ""
                ResourceID = ""
                CPUType = ""
                LastSCCMHeartBeat = ""
                OperatingSystemNameandVersion = ""
                Manufacturer = ""
                Model = ""
                SystemType = ""
                UserName = ""
                CurrentTimeZone = ""
                DomainRole = ""
                NumberOfProcessors = ""
                TimeStamp = ""
                SerialNumber = ""
                ChassisTypes = ""
                BIOSManufacturer = ""
                BIOSName = ""
                BIOSVersion = ""
                BIOSReleaseDate = ""
                InstallDate = ""
                LastBootUpTime = ""
                Caption = ""
                CSDVersion = ""
            }

            $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames, IPAddresses, IPSubnets, AgentTime, ResourceID, CPUType, DistinguishedName from SMS_R_System where name='$ThisComputer'"
            $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
            $SMS_G_System_Computer_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Model, Domain, SystemType, UserName, CurrentTimeZone, DomainRole, NumberOfProcessors, TimeStamp from SMS_G_System_Computer_System where ResourceID='$ResourceID'"
            $SMS_G_System_SYSTEM_ENCLOSURE = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, SerialNumber, ChassisTypes from SMS_G_System_SYSTEM_ENCLOSURE where ResourceID='$ResourceID'"
            $SMS_G_System_PC_BIOS = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Name, SMBIOSBIOSVersion, ReleaseDate from SMS_G_System_PC_BIOS where ResourceID='$ResourceID'"
            $SMS_G_System_OPERATING_SYSTEM = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select InstallDate, LastBootUpTime, Caption, CSDVersion from SMS_G_System_OPERATING_SYSTEM where ResourceID='$ResourceID'"

            
            $output.Name = $ThisComputer;
            
            if ($SMS_R_System){
                $output.Domain = $SMS_G_System_Computer_System.Domain
                $output.DistinguishedName = $SMS_R_System.DistinguishedName
                $output.ResourceNames = $SMS_R_System.ResourceNames[0]
                $output.IsVirtualMachine = $SMS_R_System.IsVirtualMachine
                if ($SMS_R_System.LastLogonTimestamp) { # Sometimes fails
                    $output.LastLogonTimestamp = $SMS_R_System.LastLogonTimestamp.Split(".")[0]
                }
                $output.LastLogonUserDomain = $SMS_R_System.LastLogonUserDomain
                $output.LastLogonUserName = $SMS_R_System.LastLogonUserName
                $output.IPAddresses = $SMS_R_System.IPAddresses -join " "
                $output.IPSubnets = $SMS_R_System.IPSubnets -join " "
                $output.MACAddresses = $SMS_R_System.MACAddresses -join " "
                $output.ResourceID = $SMS_R_System.ResourceID
                $output.CPUType = $SMS_R_System.CPUType
                if ($SMS_R_System.AgentTime[3]) { # Sometimes fails
                    $output.LastSCCMHeartBeat = $SMS_R_System.AgentTime[3].Split(".")[0]
                }
                $output.OperatingSystemNameandVersion = $SMS_R_System.OperatingSystemNameandVersion
            };

            if ($SMS_G_System_Computer_System){
                $output.Manufacturer = $SMS_G_System_Computer_System.Manufacturer
                $output.Model = $SMS_G_System_Computer_System.Model
                $output.SystemType = $SMS_G_System_Computer_System.SystemType
                $output.UserName = $SMS_G_System_Computer_System.UserName
                $output.CurrentTimeZone = $SMS_G_System_Computer_System.CurrentTimeZone
                $output.DomainRole = $SMS_G_System_Computer_System.DomainRole
                $output.NumberOfProcessors = $SMS_G_System_Computer_System.NumberOfProcessors
                $output.TimeStamp = $SMS_G_System_Computer_System.TimeStamp.Split(".")[0]
            };

            if ($SMS_G_System_SYSTEM_ENCLOSURE){
                $output.SerialNumber = $SMS_G_System_SYSTEM_ENCLOSURE.SerialNumber
                $output.ChassisTypes = $SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes
            };

            if ($SMS_G_System_PC_BIOS){
                $output.BIOSManufacturer = $SMS_G_System_PC_BIOS.Manufacturer
                $output.BIOSName = $SMS_G_System_PC_BIOS.Name
                $output.BIOSVersion = $SMS_G_System_PC_BIOS.SMBIOSBIOSVersion
                $output.BIOSReleaseDate = $SMS_G_System_PC_BIOS.ReleaseDate.Split(".")[0]
            };

            if ($SMS_G_System_OPERATING_SYSTEM){
                $output.InstallDate = $SMS_G_System_OPERATING_SYSTEM.InstallDate
                $output.LastBootUpTime = $SMS_G_System_OPERATING_SYSTEM.LastBootUpTime
                $output.Caption = $SMS_G_System_OPERATING_SYSTEM.Caption
                $output.CSDVersion = $SMS_G_System_OPERATING_SYSTEM.CSDVersion
            };
            

            $elapsed = $stopwatch.Elapsed;
            $total = $total+1;
            

            Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed";

            return $output;

            $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}    
    };

    END{
        $elapsed = $stopwatch.Elapsed;
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
	};
};

