FUNCTION SCCM-GetComputer {

Param([parameter(Mandatory = $true)]$ComputerName,
    $SiteName="AA1",
    $SCCMServer="name.fqdn.com")
    $SCCMNameSpace="root\sms\site_$SiteName"
    Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select * from sms_r_system where name='$ComputerName'" | select *
}
