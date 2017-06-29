FUNCTION Get-SCCMComputer {
<#
.Synopsis 
	Queries SCCM for a given hostname or IP address.

.Description 
    Queries SCCM for a given hostname or IP address.

.Parameter Computer  
    Computer can be a single hostname, IP address, or a piped in object with "Name, IP" fields.

.Example 
    Get-SCCMComputer 
    import-csv C:\hosts.csv | Get-SCCMComputer
    Get-SCCMComputer $env:computername
    Get-SCCMComputer SomeHostName.domain.com

.Notes 
    Updated: 2017-06-29
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
        $SiteName="NA1",
    );

	BEGIN{

	}

    PROCESS{

        $SCCMNameSpace="root\sms\site_$SiteName"
        
        if ($Computer.GetType().Name -eq "PSCustomObject"){ # Are we being fed an object?
            
            if ($Computer.Name -ne ""){
                $ThisComputer = $Computer.Name
            }
            
            elseif ($Computer.IP -ne ""){ # If only IP field is filled out, derive hostname
                $FQDN = [System.Net.Dns]::GetHostByAddress($Computer.IP).Hostname
                $FQDNSplit = $FQDN.Split(".")
                $ThisComputer = $FQDNSplit[0]
            }
            
            else{
                Write-Error "No Name or IP Found"
            }
        }
        
        else{ # We are being fed a string.
        
            if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){ # is this an IP address?
                $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname
                $fqdnsplit = $fqdn.Split(".")
                $ThisComputer = $fqdnsplit[0]
            }
        
            else{ # Convert any FQDN into just hostname
                $ComputerSplit = $Computer.Split(".")
                $ThisComputer = $ComputerSplit[0]
            }
        }

        
        $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames from SMS_R_System where name='$ThisComputer'" | select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames
        $SMS_G_System_Computer_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select Manufacturer, Model, Domain, SystemType, UserName from SMS_G_System_Computer_System where name='$ThisComputer'" | select Manufacturer, Model, Domain, SystemType, UserName
    
        Try{
            $output = [PSCustomObject]@{
                Name = $ThisComputer
                Domain = $SMS_G_System_Computer_System.Domain
                IsVirtualMachine = $sms_r_system.IsVirtualMachine
                LastLogonTimestamp = $sms_r_system.LastLogonTimestamp
                LastLogonUserDomain = $sms_r_system.LastLogonUserDomain
                LastLogonUserName = $sms_r_system.LastLogonUserName
                MACAddresses = [system.String]::Join(" ", $sms_r_system.MACAddresses)
                Manufacturer = $SMS_G_System_Computer_System.Manufacturer
                Model = $SMS_G_System_Computer_System.Model
                OperatingSystemNameandVersion = $sms_r_system.OperatingSystemNameandVersion
                ResourceNames = [system.String]::Join(" ", $sms_r_system.ResourceNames)
                SystemType = $SMS_G_System_Computer_System.SystemType
                UserName = $SMS_G_System_Computer_System.UserName
            }
        }
        Catch{
        }
    
        if ([bool]($output.PSobject.Properties.Name -match "SystemType")){ # If SCCM query worked
            Write-Output $output;
            $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}    
        }
        else{
            Write-Error "$ThisComputer not found"
        }
        
        
    };

    END{

	}
}

