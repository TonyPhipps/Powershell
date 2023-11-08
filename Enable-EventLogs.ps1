$LogNames = @(
    "Microsoft-Windows-DriverFrameworks-UserMode/Operational",
    "Microsoft-Windows-Dhcp-Server/AuditLog",
    "Microsoft-Windows-Dhcp-Server/DebugLogs",
    "Microsoft-Windows-Dhcp-Server/FilterNotifications",
    "Microsoft-Windows-Dhcp-Server/Operational",
    "Microsoft-Windows-Dhcpv6-Client/Admin",
    "Microsoft-Windows-Dhcpv6-Client/Operational"
  )
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
