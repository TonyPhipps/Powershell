$LogNames = @("Microsoft-Windows-Dhcp-Client/Admin",
              "Microsoft-Windows-Dhcp-Client/Operational",
              "Microsoft-Windows-Dhcpv6-Client/Admin",
              "Microsoft-Windows-Dhcpv6-Client/Operational")
ForEach ($LogName in $LogNames) {
    $EventLog = Get-WinEvent -ListLog $LogName
    if ($EventLog.IsEnabled) {
        Write-Host "Already enabled: $LogName"
    }
    else {
        Write-Host "Enabling: $LogName"
        $EventLog.IsEnabled = $true
        $EventLog.SaveChanges()
    }
}
