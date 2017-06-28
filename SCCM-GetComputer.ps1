FUNCTION SCCM-GetComputer {

Param([parameter(Mandatory = $true)]$ComputerName,
    $SiteName="AA1",
    $SCCMServer="name.fqdn.com")
    $SCCMNameSpace="root\sms\site_$SiteName"
    
    Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames from sms_r_system where name='$ComputerName'" | select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, {$_.MACAddresses}, OperatingSystemNameandVersion, {$_.ResourceNames}
    Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select Manufacturer, Model, Domain, SystemType, UserName from SMS_G_System_Computer_System where name='$ComputerName'" | select Manufacturer, Model, Domain, SystemType, UserName
}
