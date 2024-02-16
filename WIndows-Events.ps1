Get Windows Event Logs sumamry
```
Get-WinEvent -ListLog * | Select-Object * | Where-Object {($_.RecordCount -ne $null) -and ($_.RecordCount -ne 0)}
```

Get Logs
```
Get-Winevent -LogName "Windows PowerShell"
Get-WinEvent -LogName "Microsoft-Windows-Powershell/Operational"
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational"
Get-WinEvent -LogName "Microsoft-Windows-PrintService/Operational"
Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL"
```

Filter Logs
```
Get-WinEvent -FilterHashtable @{LogName = "Security"; ID = "4663"}
Get-WinEvent -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8003","8004"} | select *
```

Get Logs (with XML data)
```
Get-WinEvent -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002"} | Foreach-Object { $_.ToXml() }
```

Get AppLocker Logs (different info)
```
Get-AppLockerFileInformation –EventLog -LogPath "Microsoft-Windows-AppLocker/EXE and DLL" –EventType Audited –Statistics
```

