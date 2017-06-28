FUNCTION Get-SCCMComputer {

    Param(
    	[Parameter(
	ValueFromPipeline=$True)]
	$Computer,
        $IP,
        $SiteName="AA1",
        $SCCMServer="domain.com"
    );

	BEGIN{
		#change the error action temporarily
		$RecordErrorAction = $ErrorActionPreference
		$ErrorActionPreference = "SilentlyContinue"
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
        
            if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){
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
    
        $output = [PSCustomObject]@{
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
    
        Write-Output $output;
        $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}
    };

    END{
		#restore the error action
		$ErrorActionPreference = $RecordErrorAction
	}
}
