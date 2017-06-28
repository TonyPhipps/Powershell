FUNCTION Get-SCCMComputer {

    Param(
    	[Parameter(
			ValueFromPipeline=$True)]
		$ComputerName,
        $SiteName="NA1",
    );

	BEGIN{
		#change the error action temporarily
		$RecordErrorAction = $ErrorActionPreference
		$ErrorActionPreference = "SilentlyContinue"
	}

    PROCESS{

    $SCCMNameSpace="root\sms\site_$SiteName"


    $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames from SMS_R_System where name='$ComputerName'" | select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames
    $SMS_G_System_Computer_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select Manufacturer, Model, Domain, SystemType, UserName from SMS_G_System_Computer_System where name='$ComputerName'" | select Manufacturer, Model, Domain, SystemType, UserName
    
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
    $output.PsObject.Members.Remove('*');

    };

    END{
		#restore the error action
		$ErrorActionPreference = $RecordErrorAction
	}
}
