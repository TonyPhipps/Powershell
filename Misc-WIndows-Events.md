Get Windows Event Logs summary
```ps1
Get-WinEvent -ListLog * | Select-Object * | Where-Object {($_.RecordCount -ne $null) -and ($_.RecordCount -ne 0)}
```


Count Event IDs in a Given Log
```ps1
$LogName = "System"
$Events = Get-WinEvent -FilterHashtable @{LogName=$LogName} -ErrorAction SilentlyContinue
$Events | Group-Object Id | Select-Object Name, Count, 
    @{Name="Percent"; Expression={"{0:N2}%" -f (($_.Count / $Events.Count) * 100)}} | 
    Sort-Object Count -Descending | 
    Format-Table -AutoSize
```


Get Logs
```ps1
Get-Winevent -LogName "Windows PowerShell"
Get-WinEvent -LogName "Microsoft-Windows-Powershell/Operational"
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational"
Get-WinEvent -LogName "Microsoft-Windows-PrintService/Operational"
Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL"
```

Clear all event logs
```ps1
wevtutil el | Foreach-Object {wevtutil cl "$_"}
```

Filter Logs
```ps1
Get-WinEvent -FilterHashtable @{LogName = "Security"; ID = "4663"}
Get-WinEvent -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8003","8004"} | select *
```

Get Logs (with XML data)
```ps1
Get-WinEvent -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002"} | Foreach-Object { $_.ToXml() }
```

Get AppLocker Logs (different info)
```ps1
Get-AppLockerFileInformation –EventLog -LogPath "Microsoft-Windows-AppLocker/EXE and DLL" –EventType Audited –Statistics
```

Enable Windows Event Logs
```ps1
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
```
