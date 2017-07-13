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
    import-csv C:\hosts.csv | Get-SCCMComputer
    Get-SCCMComputer $env:computername
    Get-SCCMComputer SomeHostName.domain.com

.Notes 
    Updated: 2017-07-13
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
    	[Parameter(
			ValueFromPipeline=$True)]
		$Computer,
        $IP,
        $SiteName="A1",
        $SCCMServer="Domain.com"
    );

    BEGIN{

	}

    PROCESS{

        $SCCMNameSpace="root\sms\site_$SiteName"
        
                
        if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){ # is this an IP address?
            $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname
            $fqdnsplit = $fqdn.Split(".")
            $ThisComputer = $fqdnsplit[0]
        }
        
        else{ # Convert any FQDN into just hostname
            $ThisComputer = $Computer.Split(".")[0]
        }

        $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames, IPAddresses, IPSubnets, AgentTime, ResourceID, CPUType, DistinguishedName from SMS_R_System where name='$ThisComputer'"
        $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
        $SMS_G_System_Computer_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Model, Domain, SystemType, UserName, CurrentTimeZone, DomainRole, NumberOfProcessors, TimeStamp from SMS_G_System_Computer_System where ResourceID='$ResourceID'"
        $SMS_G_System_SYSTEM_ENCLOSURE = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, SerialNumber, ChassisTypes from SMS_G_System_SYSTEM_ENCLOSURE where ResourceID='$ResourceID'"
        $SMS_G_System_PC_BIOS = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Name, SMBIOSBIOSVersion, ReleaseDate from SMS_G_System_PC_BIOS where ResourceID='$ResourceID'"

        Try{
            $output = [PSCustomObject]@{
                Name = $ThisComputer
                Domain = $SMS_G_System_Computer_System.Domain
                DistinguishedName = $SMS_R_System.DistinguishedName
                ResourceNames = $sms_r_system.ResourceNames[0]
                IsVirtualMachine = $sms_r_system.IsVirtualMachine
                LastLogonTimestamp = $sms_r_system.LastLogonTimestamp.Split(".")[0]
                LastLogonUserDomain = $sms_r_system.LastLogonUserDomain
                LastLogonUserName = $sms_r_system.LastLogonUserName
                IPAddresses = $sms_r_system.IPAddresses -join " "
                IPSubnets = $sms_r_system.IPSubnets -join " "
                MACAddresses = $sms_r_system.MACAddresses -join " "
                ResourceID = $SMS_R_System.ResourceID
                CPUType = $SMS_R_System.CPUType
                LastSCCMHeartBeat = $SMS_R_System.AgentTime[3].Split(".")[0]
                OperatingSystemNameandVersion = $sms_r_system.OperatingSystemNameandVersion
                Manufacturer = $SMS_G_System_Computer_System.Manufacturer
                Model = $SMS_G_System_Computer_System.Model
                SystemType = $SMS_G_System_Computer_System.SystemType
                UserName = $SMS_G_System_Computer_System.UserName
                CurrentTimeZone = $SMS_G_System_Computer_System.CurrentTimeZone
                DomainRole = $SMS_G_System_Computer_System.DomainRole
                NumberOfProcessors = $SMS_G_System_Computer_System.NumberOfProcessors
                TimeStamp = $SMS_G_System_Computer_System.TimeStamp.Split(".")[0]
                SerialNumber = $SMS_G_System_SYSTEM_ENCLOSURE.SerialNumber
                ChassisTypes = $SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes
                BIOSManufacturer = $SMS_G_System_PC_BIOS.Manufacturer
                BIOSName = $SMS_G_System_PC_BIOS.Name
                BIOSVersion = $SMS_G_System_PC_BIOS.SMBIOSBIOSVersion
                BIOSReleaseDate = $SMS_G_System_PC_BIOS.ReleaseDate.Split(".")[0]
            }
        }
        Catch{
        }
    };

    END{
        if ([bool]($output.PSobject.Properties.Name -match "SystemType")){ # If SCCM query worked
            Write-Output $output;
            $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}    
        }
        else{
            Write-Error "$ThisComputer not found"
        }
	}
}
