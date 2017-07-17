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
    Updated: 2017-07-17
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
        $SCCMServer="domain.com",
        [Parameter()]
        [Alias("e")]
        [switch] $ErrorLog
    );

	BEGIN{
        $SCCMNameSpace="root\sms\site_$SiteName"

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
	}

    PROCESS{        
                
        if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){ # is this an IP address?
            $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname
            $ThisComputer = $fqdn.Split(".")[0]
        }
        
        else{ # Convert any FQDN into just hostname
            $ThisComputer = $Computer.Split(".")[0].Replace('"', '')
        }

        Try{
            $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames, IPAddresses, IPSubnets, AgentTime, ResourceID, CPUType, DistinguishedName from SMS_R_System where name='$ThisComputer'"
            $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
            $SMS_G_System_Computer_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Model, Domain, SystemType, UserName, CurrentTimeZone, DomainRole, NumberOfProcessors, TimeStamp from SMS_G_System_Computer_System where ResourceID='$ResourceID'"
            $SMS_G_System_SYSTEM_ENCLOSURE = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, SerialNumber, ChassisTypes from SMS_G_System_SYSTEM_ENCLOSURE where ResourceID='$ResourceID'"
            $SMS_G_System_PC_BIOS = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Name, SMBIOSBIOSVersion, ReleaseDate from SMS_G_System_PC_BIOS where ResourceID='$ResourceID'"
            $SMS_G_System_OPERATING_SYSTEM = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select InstallDate, LastBootUpTime, Caption, CSDVersion from SMS_G_System_OPERATING_SYSTEM where ResourceID='$ResourceID'"
        


            $output = [PSCustomObject]@{
                Name = $ThisComputer
                Domain = $SMS_G_System_Computer_System.Domain
                DistinguishedName = $SMS_R_System.DistinguishedName
                ResourceNames = $SMS_R_System.ResourceNames[0]
                IsVirtualMachine = $SMS_R_System.IsVirtualMachine
                LastLogonTimestamp = $SMS_R_System.LastLogonTimestamp.Split(".")[0]
                LastLogonUserDomain = $SMS_R_System.LastLogonUserDomain
                LastLogonUserName = $SMS_R_System.LastLogonUserName
                IPAddresses = $SMS_R_System.IPAddresses -join " "
                IPSubnets = $SMS_R_System.IPSubnets -join " "
                MACAddresses = $SMS_R_System.MACAddresses -join " "
                ResourceID = $SMS_R_System.ResourceID
                CPUType = $SMS_R_System.CPUType
                LastSCCMHeartBeat = $SMS_R_System.AgentTime[3].Split(".")[0]
                OperatingSystemNameandVersion = $SMS_R_System.OperatingSystemNameandVersion
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
                InstallDate = $SMS_G_System_OPERATING_SYSTEM.InstallDate
                LastBootUpTime = $SMS_G_System_OPERATING_SYSTEM.LastBootUpTime
                Caption = $SMS_G_System_OPERATING_SYSTEM.Caption
                CSDVersion = $SMS_G_System_OPERATING_SYSTEM.CSDVersion
            }

            Write-Verbose -Message "$ThisComputer found."
            
            Write-Output $output;
            $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}    
        }
        Catch{
            Write-Verbose -Message "$ThisComputer NOT found."

            if ($ErrorLog){
                Add-Content -Path .\Get-SCCMComputer_errors_$datetime.txt -Value ("$ThisComputer");
            }
        }
    };

    END{
	};
};

